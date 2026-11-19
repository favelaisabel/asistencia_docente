import 'package:cloud_firestore/cloud_firestore.dart';

/// Exporta todas las colecciones de negocio para el respaldo (RF-033).
/// Cada colección se convierte en una tabla: encabezado + filas de texto.
class FirestoreRespaldo {
  FirestoreRespaldo(this._db);

  final FirebaseFirestore _db;

  static const colecciones = [
    'usuarios',
    'preregistros',
    'periodos',
    'aulas',
    'docentes',
    'importaciones',
    'clases',
    'registros',
    'bitacora',
    'config',
  ];

  Future<Map<String, List<List<String>>>> exportar() async {
    final tablas = <String, List<List<String>>>{};
    for (final nombre in colecciones) {
      final s = await _db.collection(nombre).get();
      final campos = <String>{for (final d in s.docs) ...d.data().keys}.toList()
        ..sort();
      tablas[nombre] = [
        ['id', ...campos],
        for (final d in s.docs)
          [d.id, for (final c in campos) _texto(d.data()[c])],
      ];
    }
    return tablas;
  }

  String _texto(Object? valor) => switch (valor) {
    null => '',
    Timestamp() => valor.toDate().toUtc().toIso8601String(),
    Map() || List() => valor.toString(),
    _ => '$valor',
  };
}
