import 'registro.dart';
import 'situacion.dart';

/// Totales por docente para el reporte semanal (RF-029).
class TotalesDocente {
  TotalesDocente(this.docenteId, this.docenteNombre);

  final String docenteId;
  final String docenteNombre;
  int aTiempo = 0;
  int retardos = 0;
  int faltas = 0;
  int suplencias = 0;
  int sinAlumnos = 0;
  int justificados = 0;
  int pendientes = 0;

  int get total =>
      aTiempo +
      retardos +
      faltas +
      suplencias +
      sinAlumnos +
      justificados +
      pendientes;
}

/// PU-15, PU-17: un registro justificado no cuenta como falta ni retardo.
List<TotalesDocente> totalesPorDocente(Iterable<(Registro, Situacion)> filas) {
  final porDocente = <String, TotalesDocente>{};
  for (final (registro, situacion) in filas) {
    if (registro.docenteId.isEmpty) continue;
    final t = porDocente.putIfAbsent(
      registro.docenteId,
      () => TotalesDocente(registro.docenteId, registro.docenteNombre),
    );
    switch (situacion) {
      case Situacion.aTiempo:
        t.aTiempo++;
      case Situacion.retardo:
        t.retardos++;
      case Situacion.falta:
        t.faltas++;
      case Situacion.suplencia:
        t.suplencias++;
      case Situacion.sinAlumnos:
        t.sinAlumnos++;
      case Situacion.justificado:
        t.justificados++;
      case Situacion.pendiente:
        t.pendientes++;
      case Situacion.noProgramada:
        break;
    }
  }
  return porDocente.values.toList()
    ..sort((a, b) => a.docenteNombre.compareTo(b.docenteNombre));
}

/// C-14: neutraliza texto que Excel interpretaría como fórmula (PU-16).
String celdaSegura(String texto) {
  if (texto.isEmpty) return texto;
  const peligrosos = ['=', '+', '-', '@', '\t', '\r'];
  return peligrosos.contains(texto[0]) ? "'$texto" : texto;
}
