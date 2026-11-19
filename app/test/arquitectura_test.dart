import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifica automáticamente las reglas de capas de 10_ESTANDARES §4.
void main() {
  List<File> archivosDart(String carpeta) {
    final dir = Directory(carpeta);
    if (!dir.existsSync()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  List<String> violaciones(List<File> archivos, List<String> prohibidos) {
    final encontradas = <String>[];
    for (final archivo in archivos) {
      final lineas = archivo.readAsLinesSync();
      for (final linea in lineas) {
        final esImport =
            linea.startsWith('import ') || linea.startsWith('export ');
        if (esImport && prohibidos.any(linea.contains)) {
          encontradas.add('${archivo.path}: $linea');
        }
      }
    }
    return encontradas;
  }

  test('el dominio es Dart puro (sin Flutter, Firebase ni Riverpod)', () {
    final resultado = violaciones(archivosDart('lib/dominio'), [
      'package:flutter/',
      'package:firebase',
      'package:cloud_firestore',
      'package:flutter_riverpod',
      'package:riverpod',
    ]);
    expect(resultado, isEmpty, reason: resultado.join('\n'));
  });

  test('la presentación no usa Firebase directamente', () {
    final presentacion = archivosDart('lib/modulos')
        .where((f) => f.path.replaceAll(r'\', '/').contains('/presentacion/'))
        .toList();
    final resultado = violaciones(presentacion, [
      'package:firebase',
      'package:cloud_firestore',
    ]);
    expect(resultado, isEmpty, reason: resultado.join('\n'));
  });
}
