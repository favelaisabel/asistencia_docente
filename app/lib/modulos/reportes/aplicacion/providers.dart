import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../datos/firestore_respaldo.dart';
import '../../../dominio/registro.dart';
import '../../../dominio/situacion.dart';
import '../../recorrido/aplicacion/providers.dart';
import 'generador_reportes.dart';

final respaldoProvider = Provider<FirestoreRespaldo>(
  (ref) => FirestoreRespaldo(FirebaseFirestore.instance),
);

/// Convierte registros en filas de reporte con su situación y aviso de hora.
List<FilaReporte> filasDeReporte(
  Iterable<Registro> registros,
  DateTime ahora,
) => [
  for (final r in registros)
    FilaReporte(
      r,
      situacionDe(r, ahora),
      horaDudosa: esHoraDudosa(
        horaDispositivo: r.horaDispositivo,
        horaServidor: r.horaServidor,
        desfaseRelojMs: r.desfaseRelojMs,
      ),
    ),
];

/// Filas de reporte de un día (se actualiza en vivo).
final filasDelDiaProvider =
    Provider.family<AsyncValue<List<FilaReporte>>, String>((ref, fecha) {
      final ahora =
          ref.watch(ahoraProvider).value ?? ref.read(relojProvider).ahora();
      return ref
          .watch(registrosDelDiaProvider(fecha))
          .whenData((rs) => filasDeReporte(rs, ahora));
    });
