import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/streams.dart';
import '../dominio/correo.dart';
import '../dominio/fallas.dart';
import '../dominio/repositorios/autenticacion_repositorio.dart';
import '../dominio/sesion.dart';
import 'mapeadores.dart';

/// Implementación con Firebase Auth + Firestore (ADR-002, ADR-005).
class FirebaseAutenticacionRepositorio implements AutenticacionRepositorio {
  FirebaseAutenticacionRepositorio(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _perfil(String uid) =>
      _db.collection('usuarios').doc(uid);

  DocumentReference<Map<String, dynamic>> _preregistro(String correo) =>
      _db.collection('preregistros').doc(normalizarCorreo(correo));

  @override
  Stream<EstadoSesion> cambiosSesion() {
    return _auth.userChanges().cambiarA<EstadoSesion>((usuario) {
      if (usuario == null) return Stream.value(const SinSesion());
      final correo = usuario.email ?? '';
      // Escucha el perfil en vivo: si Coordinación lo desactiva, la app reacciona.
      return _perfil(usuario.uid).snapshots().map((doc) {
        if (!doc.exists) {
          return usuario.emailVerified
              ? SinPerfil(correo)
              : PendienteVerificacion(correo);
        }
        final perfil = usuarioDesdeDatos(doc.id, doc.data());
        if (perfil == null || !perfil.activo) return const SesionDesactivada();
        return ConPerfil(perfil);
      });
    });
  }

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: normalizarCorreo(correo),
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      throw _traducirAuth(e);
    }
  }

  @override
  Future<void> crearCuenta({
    required String correo,
    required String contrasena,
  }) async {
    final User usuario;
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: normalizarCorreo(correo),
        password: contrasena,
      );
      final creado = credencial.user;
      if (creado == null) throw const FallaDesconocida('sin-usuario');
      usuario = creado;
    } on FirebaseAuthException catch (e) {
      throw _traducirAuth(e);
    }

    // Solo se conserva la cuenta si el correo está pre-registrado (ADR-005).
    final bool preregistrado;
    try {
      final pre = await _preregistro(correo).get();
      preregistrado = pre.exists && pre.data()?['usado'] == false;
    } on FirebaseException catch (e) {
      await usuario.delete();
      throw _traducirFirestore(e);
    }
    if (!preregistrado) {
      await usuario.delete();
      throw const SinPreregistro();
    }

    try {
      await usuario.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _traducirAuth(e);
    }
  }

  @override
  Future<void> reenviarVerificacion() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _traducirAuth(e);
    }
  }

  @override
  Future<void> completarPerfil() async {
    final usuario = _auth.currentUser;
    if (usuario == null) throw const CredencialesInvalidas();
    try {
      await usuario.reload();
      final actualizado = _auth.currentUser;
      if (actualizado == null || !actualizado.emailVerified) {
        throw const CorreoNoVerificado();
      }
      // Renueva el token para que las reglas vean `email_verified == true`.
      await actualizado.getIdToken(true);

      final correo = normalizarCorreo(actualizado.email ?? '');
      final pre = await _preregistro(correo).get();
      final datos = pre.data();
      if (!pre.exists || datos == null || datos['usado'] != false) {
        throw const SinPreregistro();
      }

      final lote = _db.batch()
        ..set(_perfil(actualizado.uid), {
          'correo': correo,
          'nombre': datos['nombre'],
          'rol': datos['rol'],
          'activo': true,
          'creadoEn': FieldValue.serverTimestamp(),
          'esquemaVersion': 1,
        })
        ..update(_preregistro(correo), {'usado': true});
      await lote.commit();
      // Fuerza a `userChanges` a emitir de nuevo y leer el perfil recién creado.
      await actualizado.reload();
    } on FirebaseAuthException catch (e) {
      throw _traducirAuth(e);
    } on FirebaseException catch (e) {
      throw _traducirFirestore(e);
    }
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  Falla _traducirAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return const CredencialesInvalidas();
      case 'user-disabled':
        return const CuentaDesactivada();
      case 'too-many-requests':
        return const DemasiadosIntentos();
      case 'network-request-failed':
        return const SinConexion();
      case 'email-already-in-use':
        return const CuentaYaExiste();
      case 'weak-password':
        return const ContrasenaDebil();
      default:
        log('Error de autenticación: ${e.code}', name: 'autenticacion');
        return FallaDesconocida(e.code);
    }
  }

  Falla _traducirFirestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const SinPermiso();
      case 'unavailable':
        return const SinConexion();
      default:
        log('Error de Firestore: ${e.code}', name: 'autenticacion');
        return FallaDesconocida(e.code);
    }
  }
}
