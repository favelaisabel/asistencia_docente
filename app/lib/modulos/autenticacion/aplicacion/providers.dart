import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../datos/firebase_autenticacion_repositorio.dart';
import '../../../dominio/repositorios/autenticacion_repositorio.dart';
import '../../../dominio/sesion.dart';

/// Repositorio de acceso. En las pruebas se sustituye por uno falso.
final autenticacionRepositorioProvider = Provider<AutenticacionRepositorio>(
  (ref) => FirebaseAutenticacionRepositorio(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  ),
);

/// Estado de la sesión en vivo.
final sesionProvider = StreamProvider<EstadoSesion>(
  (ref) => ref.watch(autenticacionRepositorioProvider).cambiosSesion(),
);
