import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../datos/firestore_horario_repositorio.dart';
import '../../../dominio/horario.dart';
import '../../../dominio/repositorios/horario_repositorio.dart';

final horarioRepositorioProvider = Provider<HorarioRepositorio>(
  (ref) => FirestoreHorarioRepositorio(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);

final horarioVigenteProvider = StreamProvider<HorarioVigente?>(
  (ref) => ref.watch(horarioRepositorioProvider).vigente(),
);

/// Clases del horario vigente para un día de la semana (1–7).
final clasesDelDiaProvider = StreamProvider.family<List<Clase>, int>((
  ref,
  dia,
) {
  final vigente = ref.watch(horarioVigenteProvider).value;
  if (vigente == null || dia < 1 || dia > 6) return Stream.value(const []);
  return ref
      .watch(horarioRepositorioProvider)
      .clasesDelDia(vigente.importacionId, dia);
});
