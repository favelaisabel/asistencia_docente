import 'dart:io';
import 'dart:typed_data';

import 'package:asistencia_docente/dominio/horario.dart';
import 'package:asistencia_docente/modulos/horario/aplicacion/lector_archivo.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lectura de archivos de horario (RF-010, C-13)', () {
    test(
      'el horario de demostración es válido: 480 clases, 10 aulas, 20 docentes',
      () {
        final bytes = File('../docs/demo/horario_demo.csv').readAsBytesSync();
        final r = validarHorario(leerFilas(bytes, 'horario_demo.csv'));
        expect(r.errores, isEmpty, reason: r.errores.join('\n'));
        expect(r.clases, hasLength(480));
        expect(r.aulas, hasLength(10));
        expect(r.docentes, hasLength(20));
      },
    );

    test('el archivo con errores reporta cada problema y no importa nada', () {
      final bytes = File(
        '../docs/demo/horario_con_errores.csv',
      ).readAsBytesSync();
      final r = validarHorario(leerFilas(bytes, 'horario_con_errores.csv'));
      expect(r.esValido, isFalse);
      expect(r.clases, isEmpty);
      expect(r.errores.map((e) => e.fila), containsAll([4, 5, 6, 7]));
    });

    test('lee Excel (.xlsx) con números y horas', () {
      final libro = Excel.createExcel();
      final hoja = libro[libro.getDefaultSheet() ?? 'Sheet1'];
      hoja.appendRow([for (final c in columnasPlantilla) TextCellValue(c)]);
      hoja.appendRow([
        TextCellValue('A101'),
        const IntCellValue(1001),
        TextCellValue('Laura Pérez Soto'),
        TextCellValue('lunes'),
        const IntCellValue(7),
        const TimeCellValue(hour: 9, minute: 0),
        TextCellValue('Cálculo'),
        TextCellValue('1A'),
      ]);
      final bytes = Uint8List.fromList(libro.encode()!);
      final r = validarHorario(leerFilas(bytes, 'horario.xlsx'));
      expect(r.errores, isEmpty, reason: r.errores.join('\n'));
      expect(r.clases.single.horaFin, 9);
      expect(r.clases.single.docenteId, '1001');
    });

    test(
      'PU-06 rechaza archivos de más de 2 MB y extensiones no permitidas',
      () {
        expect(
          () => leerFilas(Uint8List(maxBytesHorario + 1), 'h.csv'),
          throwsA(isA<ArchivoNoValido>()),
        );
        expect(
          () => leerFilas(Uint8List(10), 'h.pdf'),
          throwsA(isA<ArchivoNoValido>()),
        );
      },
    );

    test('la plantilla descargable es válida', () {
      final r = validarHorario(leerFilas(plantillaCsv(), 'plantilla.csv'));
      expect(r.errores, isEmpty, reason: r.errores.join('\n'));
      expect(r.clases, hasLength(2));
    });
  });
}
