import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../dominio/registro.dart';
import '../../../dominio/reportes.dart';
import '../../../dominio/situacion.dart';
import '../../../dominio/tiempo.dart';

/// Un registro con su situación calculada para reportar.
class FilaReporte {
  const FilaReporte(this.registro, this.situacion, {required this.horaDudosa});

  final Registro registro;
  final Situacion situacion;
  final bool horaDudosa;
}

const _encabezadoRegistros = [
  'Fecha',
  'Hora',
  'Turno',
  'Aula',
  'Núm. empleado',
  'Docente',
  'Materia',
  'Grupo',
  'Situación',
  'Suplente',
  'Observación',
  'Hora de captura',
  'Avisos',
  'Versión',
];

String _horaCaptura(Registro r) {
  final m = MomentoNegocio.desdeUtc(r.horaDispositivo);
  return '${m.hora.toString().padLeft(2, '0')}:${m.minuto.toString().padLeft(2, '0')}';
}

String _avisos(FilaReporte f) => [
  if (f.horaDudosa) 'Hora dudosa',
  if (f.registro.capturadoSinConexion) 'Capturado sin conexión',
  if (f.registro.origen == 'MANUAL') 'Captura manual',
  if (f.registro.version > 1) 'Corregido',
].join(', ');

List<String> _filaRegistro(FilaReporte f) {
  final r = f.registro;
  return [
    r.fecha,
    '${r.hora.toString().padLeft(2, '0')}:00',
    r.turno == 'VES' ? 'Vespertino' : 'Matutino',
    r.aulaId,
    r.docenteId,
    r.docenteNombre,
    r.materia,
    r.grupo,
    f.situacion.etiqueta,
    r.suplenteNombre,
    r.observacion,
    _horaCaptura(r),
    _avisos(f),
    '${r.version}',
  ].map(celdaSegura).toList();
}

List<FilaReporte> ordenar(List<FilaReporte> filas) => [...filas]
  ..sort((a, b) {
    final c = a.registro.fecha.compareTo(b.registro.fecha);
    if (c != 0) return c;
    final h = a.registro.hora.compareTo(b.registro.hora);
    return h != 0 ? h : a.registro.aulaId.compareTo(b.registro.aulaId);
  });

List<List<String>> _tablaTotales(List<TotalesDocente> totales) => [
  [
    'Núm. empleado',
    'Docente',
    'A tiempo',
    'Retardos',
    'Faltas',
    'Suplencias',
    'Sin alumnos',
    'Justificados',
    'Total',
  ],
  for (final t in totales)
    [
      celdaSegura(t.docenteId),
      celdaSegura(t.docenteNombre),
      '${t.aTiempo}',
      '${t.retardos}',
      '${t.faltas}',
      '${t.suplencias}',
      '${t.sinAlumnos}',
      '${t.justificados}',
      '${t.total}',
    ],
];

/// Reporte en Excel: hoja de registros y, si es semanal, hoja de totales.
Uint8List reporteExcel({
  required List<FilaReporte> filas,
  required bool conTotales,
}) {
  final libro = Excel.createExcel();
  final inicial = libro.getDefaultSheet() ?? 'Sheet1';
  libro.rename(inicial, 'Registros');
  final hoja = libro['Registros'];
  hoja.appendRow([for (final t in _encabezadoRegistros) TextCellValue(t)]);
  for (final f in ordenar(filas)) {
    hoja.appendRow([for (final v in _filaRegistro(f)) TextCellValue(v)]);
  }
  if (conTotales) {
    final totales = libro['Totales por docente'];
    final tabla = _tablaTotales(
      totalesPorDocente(filas.map((f) => (f.registro, f.situacion))),
    );
    for (final (i, fila) in tabla.indexed) {
      totales.appendRow([
        for (final (j, v) in fila.indexed)
          i > 0 && j >= 2 ? IntCellValue(int.parse(v)) : TextCellValue(v),
      ]);
    }
  }
  return Uint8List.fromList(libro.encode() ?? const []);
}

/// Reporte en PDF (RF-028, RF-029).
Future<Uint8List> reportePdf({
  required String titulo,
  required String subtitulo,
  required List<FilaReporte> filas,
  required bool conTotales,
}) async {
  final doc = pw.Document(title: titulo, author: 'Asistencia docente');
  final conteo = <Situacion, int>{};
  for (final f in filas) {
    conteo[f.situacion] = (conteo[f.situacion] ?? 0) + 1;
  }
  final resumen = Situacion.values
      .where((s) => (conteo[s] ?? 0) > 0)
      .map((s) => '${s.etiqueta}: ${conteo[s]}')
      .join('   ');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Text(
          'Total de registros: ${filas.length}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          resumen.isEmpty ? 'Sin registros.' : resumen,
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        if (conTotales) ...[
          pw.Text(
            'Totales por docente',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            data: _tablaTotales(
              totalesPorDocente(filas.map((f) => (f.registro, f.situacion))),
            ),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Detalle de registros',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
        ],
        if (filas.isNotEmpty)
          pw.TableHelper.fromTextArray(
            data: [
              [
                'Fecha',
                'Hora',
                'Aula',
                'Docente',
                'Materia',
                'Situación',
                'Suplente',
                'Captura',
                'Avisos',
              ],
              for (final f in ordenar(filas))
                () {
                  final c = _filaRegistro(f);
                  return [
                    c[0],
                    c[1],
                    c[3],
                    c[5],
                    c[6],
                    c[8],
                    c[9],
                    c[11],
                    c[12],
                  ];
                }(),
            ],
            headerStyle: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
          ),
      ],
    ),
  );
  return doc.save();
}

/// Respaldo completo (RF-033, RNF-014): un .zip con un CSV por colección.
Uint8List respaldoZip(Map<String, List<List<String>>> tablas) {
  final archivo = Archive();
  for (final entrada in tablas.entries) {
    final contenido = utf8.encode(
      Csv().encode([
        for (final fila in entrada.value)
          [for (final c in fila) celdaSegura(c)],
      ]),
    );
    archivo.addFile(
      ArchiveFile('${entrada.key}.csv', contenido.length, contenido),
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(archivo) ?? const []);
}
