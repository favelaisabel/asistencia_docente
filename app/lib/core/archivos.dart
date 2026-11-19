import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

enum TipoArchivo {
  pdf('pdf', MimeType.pdf),
  excel('xlsx', MimeType.microsoftExcel),
  csv('csv', MimeType.csv),
  zip('zip', MimeType.zip);

  const TipoArchivo(this.extension, this.mime);
  final String extension;
  final MimeType mime;
}

/// Descarga (web) o guarda (Android) un archivo generado por la app.
Future<void> descargarArchivo(
  String nombreSinExtension,
  Uint8List bytes,
  TipoArchivo tipo,
) {
  return FileSaver.instance.saveFile(
    name: nombreSinExtension,
    bytes: bytes,
    fileExtension: tipo.extension,
    mimeType: tipo.mime,
  );
}
