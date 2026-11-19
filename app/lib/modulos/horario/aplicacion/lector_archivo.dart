import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../dominio/horario.dart';

/// Tamaño máximo del archivo de horario (C-13).
const int maxBytesHorario = 2 * 1024 * 1024;

class ArchivoNoValido implements Exception {
  const ArchivoNoValido(this.mensaje);
  final String mensaje;
}

/// Convierte un .xlsx o .csv en filas de texto (la primera es el encabezado).
List<List<String>> leerFilas(Uint8List bytes, String nombre) {
  if (bytes.length > maxBytesHorario) {
    throw const ArchivoNoValido('El archivo pesa más de 2 MB.');
  }
  final extension = nombre.toLowerCase().split('.').last;
  switch (extension) {
    case 'csv':
      var texto = utf8.decode(bytes, allowMalformed: true);
      if (texto.startsWith('﻿')) texto = texto.substring(1);
      return [
        for (final fila in Csv().decode(texto))
          [for (final c in fila) '${c ?? ''}'],
      ];
    case 'xlsx':
      final Excel libro;
      try {
        libro = Excel.decodeBytes(bytes);
      } catch (_) {
        throw const ArchivoNoValido('No se pudo leer el archivo de Excel.');
      }
      if (libro.tables.isEmpty) return const [];
      final hoja = libro.tables.values.first;
      return [
        for (final fila in hoja.rows)
          [for (final celda in fila) _texto(celda?.value)],
      ];
    default:
      throw const ArchivoNoValido('Usa un archivo .xlsx o .csv.');
  }
}

String _texto(CellValue? valor) => switch (valor) {
  null => '',
  IntCellValue(:final value) => '$value',
  DoubleCellValue(:final value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value',
  TimeCellValue(:final hour, :final minute) =>
    '$hour:${minute.toString().padLeft(2, '0')}',
  _ => valor.toString(),
};

/// Plantilla descargable (RF-010).
Uint8List plantillaCsv() {
  final filas = [
    columnasPlantilla,
    [
      'A101',
      '1001',
      'Laura Pérez Soto',
      'lunes',
      '7',
      '9',
      'Cálculo Diferencial',
      '1A',
    ],
    [
      'A102',
      '1002',
      'Jorge Ramírez Luna',
      'martes',
      '14:00',
      '16:00',
      'Programación I',
      '1B',
    ],
  ];
  return Uint8List.fromList(utf8.encode('﻿${Csv().encode(filas)}'));
}
