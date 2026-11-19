import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../datos/firestore_usuario_repositorio.dart';
import '../../../dominio/repositorios/usuario_repositorio.dart';
import '../../../dominio/usuario.dart';

final usuarioRepositorioProvider = Provider<UsuarioRepositorio>(
  (ref) => FirestoreUsuarioRepositorio(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);

final usuariosProvider = StreamProvider<List<Usuario>>(
  (ref) => ref.watch(usuarioRepositorioProvider).usuarios(),
);

final preregistrosPendientesProvider = StreamProvider<List<Preregistro>>(
  (ref) => ref.watch(usuarioRepositorioProvider).preregistrosPendientes(),
);
