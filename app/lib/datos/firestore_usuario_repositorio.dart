import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../dominio/correo.dart';
import '../dominio/fallas.dart';
import '../dominio/repositorios/usuario_repositorio.dart';
import '../dominio/rol.dart';
import '../dominio/usuario.dart';
import 'mapeadores.dart';

/// Gestión de usuarios con Firestore (RF-004).
class FirestoreUsuarioRepositorio implements UsuarioRepositorio {
  FirestoreUsuarioRepositorio(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Stream<List<Usuario>> usuarios() {
    return _db
        .collection('usuarios')
        .orderBy('nombre')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => usuarioDesdeDatos(d.id, d.data()))
              .whereType<Usuario>()
              .toList(),
        );
  }

  @override
  Stream<List<Preregistro>> preregistrosPendientes() {
    return _db
        .collection('preregistros')
        .where('usado', isEqualTo: false)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => preregistroDesdeDatos(d.id, d.data()))
              .whereType<Preregistro>()
              .toList(),
        );
  }

  @override
  Future<void> preregistrar({
    required String correo,
    required String nombre,
    required Rol rol,
  }) async {
    final id = normalizarCorreo(correo);
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const SinPermiso();
    final ref = _db.collection('preregistros').doc(id);
    try {
      final existente = await ref.get();
      if (existente.exists) throw const PreregistroDuplicado();
      final yaTieneCuenta = await _db
          .collection('usuarios')
          .where('correo', isEqualTo: id)
          .limit(1)
          .get();
      if (yaTieneCuenta.docs.isNotEmpty) throw const PreregistroDuplicado();
      await ref.set({
        'correo': id,
        'nombre': nombre.trim(),
        'rol': rol.codigo,
        'usado': false,
        'creadoPor': uid,
        'creadoEn': FieldValue.serverTimestamp(),
        'esquemaVersion': 1,
      });
    } on FirebaseException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> cancelarPreregistro(String correo) async {
    try {
      await _db
          .collection('preregistros')
          .doc(normalizarCorreo(correo))
          .delete();
    } on FirebaseException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> cambiarActivo({
    required String uid,
    required bool activo,
  }) async {
    try {
      await _db.collection('usuarios').doc(uid).update({'activo': activo});
    } on FirebaseException catch (e) {
      throw _traducir(e);
    }
  }

  Falla _traducir(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const SinPermiso();
      case 'unavailable':
        return const SinConexion();
      default:
        log('Error de Firestore: ${e.code}', name: 'usuarios');
        return FallaDesconocida(e.code);
    }
  }
}
