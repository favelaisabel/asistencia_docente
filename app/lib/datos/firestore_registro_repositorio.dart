import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../dominio/fallas.dart';
import '../dominio/horario.dart';
import '../dominio/registro.dart';
import '../dominio/repositorios/registro_repositorio.dart';
import '../dominio/tiempo.dart';
import '../dominio/turno.dart';
import '../dominio/usuario.dart';

/// Registros y bitácora en Firestore (06_MODELO_DATOS §4.9–4.10, §7.1).
class FirestoreRegistroRepositorio implements RegistroRepositorio {
  FirestoreRegistroRepositorio(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _registros =>
      _db.collection('registros');
  CollectionReference<Map<String, dynamic>> get _bitacora =>
      _db.collection('bitacora');

  Query<Map<String, dynamic>> _delDia(String fecha) => _registros.where(
    'fechaTs',
    isEqualTo: Timestamp.fromDate(inicioDelDiaUtc(fecha)),
  );

  @override
  Stream<List<Registro>> registrosDelDia(String fecha) {
    return _delDia(fecha)
        .snapshots(includeMetadataChanges: true)
        .map((s) => s.docs.map(_registro).whereType<Registro>().toList());
  }

  @override
  Stream<bool> sinConexion(String fecha) {
    return _delDia(fecha)
        .snapshots(includeMetadataChanges: true)
        .map((s) => s.metadata.isFromCache)
        .distinct();
  }

  @override
  Future<List<Registro>> registrosEntre(String desde, String hasta) async {
    try {
      final s = await _registros
          .where('fecha', isGreaterThanOrEqualTo: desde)
          .where('fecha', isLessThanOrEqualTo: hasta)
          .get();
      return s.docs.map(_registro).whereType<Registro>().toList();
    } on FirebaseException catch (e) {
      throw _traducir(e);
    }
  }

  Registro? _registro(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (m == null) return null;
    final estado = EstadoCaptura.desdeCodigo(m['estadoCaptura'] as String?);
    final fecha = m['fecha'];
    final hora = m['hora'];
    final dispositivo = m['horaDispositivo'];
    if (estado == null ||
        fecha is! String ||
        hora is! int ||
        dispositivo is! Timestamp) {
      log('Registro con formato inválido: ${d.id}', name: 'registros');
      return null;
    }
    String texto(String campo) => m[campo] is String ? m[campo] as String : '';
    DateTime? fechaHora(String campo) =>
        m[campo] is Timestamp ? (m[campo] as Timestamp).toDate().toUtc() : null;
    return Registro(
      id: d.id,
      periodoId: texto('periodoId'),
      claseId: texto('claseId'),
      aulaId: texto('aulaId'),
      fecha: fecha,
      hora: hora,
      turno: texto('turno'),
      docenteId: texto('docenteId'),
      docenteNombre: texto('docenteNombre'),
      materia: texto('materia'),
      grupo: texto('grupo'),
      estado: estado,
      suplenteNombre: texto('suplenteNombre'),
      observacion: texto('observacion'),
      horaDispositivo: dispositivo.toDate().toUtc(),
      horaServidor: fechaHora('horaServidor'),
      llegadaDispositivo: fechaHora('llegadaDispositivo'),
      desfaseRelojMs: m['desfaseRelojMs'] is int
          ? m['desfaseRelojMs'] as int
          : 0,
      capturadoSinConexion: m['capturadoSinConexion'] == true,
      origen: texto('origen'),
      registradoPor: texto('registradoPor'),
      version: m['version'] is int ? m['version'] as int : 1,
      actualizadoPor: texto('actualizadoPor'),
      justificacion: JustificacionEstado.desdeCodigo(
        m['justificacionEstado'] as String?,
      ),
      pendienteDeEnvio: d.metadata.hasPendingWrites,
    );
  }

  Map<String, Object?> _bitacoraDatos({
    required String registroId,
    required int version,
    required String accion,
    required Map<String, Object?> antes,
    required Map<String, Object?> despues,
    required Usuario usuario,
    String motivo = '',
  }) => {
    'registroId': registroId,
    'version': version,
    'accion': accion,
    'antes': antes,
    'despues': despues,
    'motivo': motivo,
    'usuarioUid': usuario.uid,
    'usuarioNombre': usuario.nombre,
    'usuarioRol': usuario.rol.codigo,
    'horaServidor': FieldValue.serverTimestamp(),
  };

  /// Sin conexión, `commit()` no termina hasta sincronizar; la captura ya
  /// quedó en el dispositivo, así que no se espera (RF-021).
  void _enviarSinEsperar(WriteBatch lote) {
    unawaited(
      lote.commit().catchError((Object e) {
        log(
          'Envío rechazado: ${e is FirebaseException ? e.code : e.runtimeType}',
          name: 'registros',
        );
      }),
    );
  }

  @override
  Future<void> registrar({
    required Clase clase,
    required String periodoId,
    required String fecha,
    required int hora,
    required Captura captura,
    required DateTime horaDispositivo,
    required int desfaseRelojMs,
    required bool sinConexion,
    required Usuario usuario,
  }) async {
    final id = idRegistro(clase.aulaId, fecha, hora);
    final datos = <String, Object?>{
      'periodoId': periodoId,
      'claseId': clase.id,
      'aulaId': clase.aulaId,
      'fecha': fecha,
      'fechaTs': Timestamp.fromDate(inicioDelDiaUtc(fecha)),
      'hora': hora,
      'turno': (Turno.deBloque(hora) ?? Turno.matutino).codigo,
      'docenteId': clase.docenteId,
      'docenteNombre': clase.docenteNombre,
      'materia': clase.materia,
      'grupo': clase.grupo,
      'estadoCaptura': captura.estado.codigo,
      'suplenteNombre': captura.suplenteNombre.trim(),
      'observacion': captura.observacion.trim(),
      'horaDispositivo': Timestamp.fromDate(horaDispositivo),
      'horaServidor': FieldValue.serverTimestamp(),
      'llegadaDispositivo': null,
      'desfaseRelojMs': desfaseRelojMs,
      'capturadoSinConexion': sinConexion,
      'origen': 'APP',
      'registradoPor': usuario.uid,
      'version': 1,
      'actualizadoPor': usuario.uid,
      'actualizadoEn': FieldValue.serverTimestamp(),
      'justificacionEstado': JustificacionEstado.ninguna.codigo,
      'esquemaVersion': 1,
    };
    final lote = _db.batch()
      ..set(_registros.doc(id), datos)
      ..set(
        _bitacora.doc('${id}_v1'),
        _bitacoraDatos(
          registroId: id,
          version: 1,
          accion: 'CREAR',
          antes: const {},
          despues: _resumen(captura),
          usuario: usuario,
        ),
      );
    _enviarSinEsperar(lote);
  }

  Map<String, Object?> _resumen(Captura c) => {
    'estadoCaptura': c.estado.codigo,
    if (c.suplenteNombre.isNotEmpty) 'suplenteNombre': c.suplenteNombre.trim(),
    if (c.observacion.isNotEmpty) 'observacion': c.observacion.trim(),
  };

  Map<String, Object?> _resumenRegistro(Registro r) => {
    'estadoCaptura': r.estado.codigo,
    if (r.suplenteNombre.isNotEmpty) 'suplenteNombre': r.suplenteNombre,
    if (r.observacion.isNotEmpty) 'observacion': r.observacion,
  };

  @override
  Future<void> marcarLlegada({
    required Registro registro,
    required DateTime llegada,
    required Usuario usuario,
  }) async {
    final version = registro.version + 1;
    final lote = _db.batch()
      ..update(_registros.doc(registro.id), {
        'llegadaDispositivo': Timestamp.fromDate(llegada),
        'version': version,
        'actualizadoPor': usuario.uid,
        'actualizadoEn': FieldValue.serverTimestamp(),
      })
      ..set(
        _bitacora.doc('${registro.id}_v$version'),
        _bitacoraDatos(
          registroId: registro.id,
          version: version,
          accion: 'LLEGADA',
          antes: {'llegadaDispositivo': null},
          despues: {'llegadaDispositivo': llegada.toIso8601String()},
          usuario: usuario,
        ),
      );
    _enviarSinEsperar(lote);
  }

  @override
  Future<void> corregir({
    required Registro registro,
    required Captura captura,
    required Usuario usuario,
    String motivo = '',
  }) async {
    final version = registro.version + 1;
    final lote = _db.batch()
      ..update(_registros.doc(registro.id), {
        'estadoCaptura': captura.estado.codigo,
        'suplenteNombre': captura.suplenteNombre.trim(),
        'observacion': captura.observacion.trim(),
        'llegadaDispositivo': null,
        'version': version,
        'actualizadoPor': usuario.uid,
        'actualizadoEn': FieldValue.serverTimestamp(),
      })
      ..set(
        _bitacora.doc('${registro.id}_v$version'),
        _bitacoraDatos(
          registroId: registro.id,
          version: version,
          accion: 'CORREGIR',
          antes: _resumenRegistro(registro),
          despues: _resumen(captura),
          usuario: usuario,
          motivo: motivo.trim(),
        ),
      );
    if (motivo.isEmpty) {
      _enviarSinEsperar(lote); // Encargado: puede estar sin conexión.
      return;
    }
    try {
      await lote.commit(); // Coordinación: confirma con el servidor.
    } on FirebaseException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Stream<List<EntradaBitacora>> bitacora(String registroId) {
    return _bitacora
        .where('registroId', isEqualTo: registroId)
        .orderBy('version')
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              EntradaBitacora(
                registroId: registroId,
                version: d.data()['version'] is int
                    ? d.data()['version'] as int
                    : 0,
                accion: '${d.data()['accion'] ?? ''}',
                antes: Map<String, Object?>.from(
                  d.data()['antes'] as Map? ?? const {},
                ),
                despues: Map<String, Object?>.from(
                  d.data()['despues'] as Map? ?? const {},
                ),
                motivo: '${d.data()['motivo'] ?? ''}',
                usuarioUid: '${d.data()['usuarioUid'] ?? ''}',
                usuarioNombre: '${d.data()['usuarioNombre'] ?? ''}',
                usuarioRol: '${d.data()['usuarioRol'] ?? ''}',
                horaServidor: d.data()['horaServidor'] is Timestamp
                    ? (d.data()['horaServidor'] as Timestamp).toDate()
                    : null,
              ),
          ],
        );
  }

  @override
  Future<int> medirDesfaseReloj(String uid, DateTime ahoraDispositivo) async {
    final ref = _db.collection('sincronizacion').doc(uid);
    await ref
        .set({'ping': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 5));
    final doc = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 5));
    final ping = doc.data()?['ping'];
    if (ping is! Timestamp) return 0;
    return ahoraDispositivo.difference(ping.toDate().toUtc()).inMilliseconds;
  }

  Falla _traducir(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const SinPermiso();
      case 'unavailable':
        return const SinConexion();
      default:
        log('Error de Firestore: ${e.code}', name: 'registros');
        return FallaDesconocida(e.code);
    }
  }
}
