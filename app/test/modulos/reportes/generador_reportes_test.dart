import 'package:archive/archive.dart';
import 'package:asistencia_docente/dominio/registro.dart';
import 'package:asistencia_docente/dominio/situacion.dart';
import 'package:asistencia_docente/modulos/reportes/aplicacion/generador_reportes.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dominio/situacion_test.dart' show registro;

void main() {
  final filas = [
    FilaReporte(registro(), Situacion.aTiempo, horaDudosa: false),
    FilaReporte(
      registro(nombre: '=HYPERLINK("http://x")'),
      Situacion.falta,
      horaDudosa: true,
    ),
    FilaReporte(
      registro(docenteId: '1002', nombre: 'Óscar Núñez'),
      Situacion.retardo,
      horaDudosa: false,
    ),
  ];

  group('Reportes (RF-028, RF-029, RF-033)', () {
    test('Excel semanal con hoja de totales y celdas neutralizadas (C-14)', () {
      final libro = Excel.decodeBytes(
        reporteExcel(filas: filas, conTotales: true),
      );
      expect(
        libro.tables.keys,
        containsAll(['Registros', 'Totales por docente']),
      );
      final registros = libro.tables['Registros']!;
      expect(registros.maxRows, 4);
      final textos = [
        for (final fila in registros.rows)
          for (final c in fila) '${c?.value}',
      ];
      expect(textos, contains("'=HYPERLINK(\"http://x\")"));
      expect(textos, isNot(contains('=HYPERLINK("http://x")')));
    });

    test('PDF con acentos y tabla de totales', () async {
      final bytes = await reportePdf(
        titulo: 'Reporte semanal de asistencia docente',
        subtitulo: 'Semana del 2026-11-16 al 2026-11-22',
        filas: filas,
        conTotales: true,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('respaldo .zip con un CSV por colección', () {
      final zip = ZipDecoder().decodeBytes(
        respaldoZip({
          'registros': [
            ['id', 'estadoCaptura'],
            ['A101_20261119_09', EstadoCaptura.presente.codigo],
          ],
          'bitacora': [
            ['id'],
          ],
        }),
      );
      expect(zip.files.map((f) => f.name), ['registros.csv', 'bitacora.csv']);
    });
  });
}
