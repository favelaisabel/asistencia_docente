import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/streams.dart';
import '../dominio/fallas.dart';
import '../dominio/horario.dart';
import '../dominio/repositorios/horario_repositorio.dart';

/// Horario oficial en Firestore (06_MODELO_DATOS §4.1–4.8, §7.2).
class FirestoreHorarioRepositorio implements HorarioRepositorio {
  FirestoreHorarioRepositorio(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _tamanoLote = 400;

  @override
  Stream<HorarioVigente?> vigente() {
    return _db.collection('config').doc('sistema').snapshots().cambiarA((
      config,
    ) {
      final datos = config.data();
      final periodoId = datos?['periodoActivoId'];
      final importacionId = datos?['importacionActivaId'];
      if (periodoId is! String || importacionId is! String) {
        return Stream<HorarioVigente?>.value(null);
      }
      return _db.collection('periodos').doc(periodoId).snapshots().cambiarA((
        periodo,
      ) {
        return _db
            .collection('importaciones')
            .doc(importacionId)
            .snapshots()
            .map((imp) {
              final p = periodo.data() ?? const {};
              final i = imp.data() ?? const {};
              final creado = i['creadoEn'];
              return HorarioVigente(
                periodoId: periodoId,
                periodoNombre: p['nombre'] is String
                    ? p['nombre'] as String
                    : periodoId,
                fechaInicio: p['fechaInicio'] is String
                    ? p['fechaInicio'] as String
                    : '',
                fechaFin: p['fechaFin'] is String
                    ? p['fechaFin'] as String
                    : '',
                importacionId: importacionId,
                totalClases: i['totalClases'] is int
                    ? i['totalClases'] as int
                    : 0,
                archivoNombre: i['archivoNombre'] is String
                    ? i['archivoNombre'] as String
                    : '',
                importadoEn: creado is Timestamp ? creado.toDate() : null,
              );
            });
      });
    });
  }

  @override
  Stream<List<Clase>> clasesDelDia(String importacionId, int diaSemana) {
    return _db
        .collection('clases')
        .where('importacionId', isEqualTo: importacionId)
        .where('diaSemana', isEqualTo: diaSemana)
        .snapshots()
        .map((s) => s.docs.map(_clase).whereType<Clase>().toList());
  }

  Clase? _clase(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final valores = [
      m['aulaId'],
      m['docenteId'],
      m['docenteNombre'],
      m['materia'],
      m['grupo'],
    ];
    if (valores.any((v) => v is! String) ||
        m['diaSemana'] is! int ||
        m['horaInicio'] is! int ||
        m['horaFin'] is! int) {
      log('Clase con formato inválido: ${d.id}', name: 'horario');
      return null;
    }
    return Clase(
      id: d.id,
      aulaId: m['aulaId'] as String,
      docenteId: m['docenteId'] as String,
      docenteNombre: m['docenteNombre'] as String,
      materia: m['materia'] as String,
      grupo: m['grupo'] as String,
      diaSemana: m['diaSemana'] as int,
      horaInicio: m['horaInicio'] as int,
      horaFin: m['horaFin'] as int,
    );
  }

  @override
  Future<void> importar({
    required List<Clase> clases,
    required String periodoNombre,
    required String fechaInicio,
    required String fechaFin,
    required String archivoNombre,
    void Function(double)? progreso,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const SinPermiso();
    final periodoId = periodoNombre.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    final importacion = _db.collection('importaciones').doc();
    try {
      await _db.collection('periodos').doc(periodoId).set({
        'nombre': periodoNombre.trim(),
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        'esquemaVersion': 1,
      });
      await importacion.set({
        'periodoId': periodoId,
        'archivoNombre': archivoNombre,
        'totalClases': clases.length,
        'estado': 'CARGANDO',
        'creadoPor': uid,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      // Catálogos derivados del archivo (RF-008, RF-009).
      final aulas = {for (final c in clases) c.aulaId};
      final docentes = {for (final c in clases) c.docenteId: c.docenteNombre};
      final escrituras = <void Function(WriteBatch)>[
        for (final aula in aulas)
          (b) => b.set(_db.collection('aulas').doc(aula), {
            'numero': aula,
            'edificio': 'Principal',
            'activa': true,
          }),
        for (final entrada in docentes.entries)
          (b) => b.set(_db.collection('docentes').doc(entrada.key), {
            'numEmpleado': entrada.key,
            'nombreCompleto': entrada.value,
            'activo': true,
          }),
        for (final c in clases)
          (b) => b.set(_db.collection('clases').doc(), {
            'importacionId': importacion.id,
            'periodoId': periodoId,
            'aulaId': c.aulaId,
            'docenteId': c.docenteId,
            'docenteNombre': c.docenteNombre,
            'materia': c.materia,
            'grupo': c.grupo,
            'diaSemana': c.diaSemana,
            'horaInicio': c.horaInicio,
            'horaFin': c.horaFin,
          }),
      ];

      for (var i = 0; i < escrituras.length; i += _tamanoLote) {
        final lote = _db.batch();
        for (final escribir in escrituras.skip(i).take(_tamanoLote)) {
          escribir(lote);
        }
        await lote.commit();
        progreso?.call(
          (i + _tamanoLote).clamp(0, escrituras.length) / escrituras.length,
        );
      }

      // Activación atómica: solo aquí cambia el horario vigente.
      final activar = _db.batch()
        ..update(importacion, {'estado': 'COMPLETA'})
        ..set(_db.collection('config').doc('sistema'), {
          'periodoActivoId': periodoId,
          'importacionActivaId': importacion.id,
          'actualizadoEn': FieldValue.serverTimestamp(),
          'actualizadoPor': uid,
        });
      await activar.commit();
    } on FirebaseException catch (e) {
      try {
        await importacion.update({'estado': 'DESCARTADA'});
      } on FirebaseException {
        // La importación queda en CARGANDO y nunca se activa (06 §7.2).
      }
      log('Importación fallida: ${e.code}', name: 'horario');
      throw e.code == 'permission-denied'
          ? const SinPermiso()
          : FallaDesconocida(e.code);
    }
  }
}
