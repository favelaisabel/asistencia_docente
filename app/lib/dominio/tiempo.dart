/// Fecha y hora de negocio en `America/Mexico_City` (06_MODELO_DATOS §2).
///
/// Desde 2022 la Ciudad de México no tiene horario de verano: el desfase es
/// fijo de UTC−6 (supuesto documentado en 12_INCREMENTOS, I3).
library;

const Duration desfaseMexico = Duration(hours: -6);

/// Un instante expresado en hora local de negocio.
class MomentoNegocio {
  MomentoNegocio.desdeUtc(DateTime instante)
    : _local = instante.toUtc().add(desfaseMexico);

  final DateTime _local;

  /// `AAAA-MM-DD`.
  String get fecha => formatoFecha(_local.year, _local.month, _local.day);

  int get hora => _local.hour;
  int get minuto => _local.minute;

  /// 1 = lunes … 7 = domingo.
  int get diaSemana => _local.weekday;

  int get anio => _local.year;
  int get mes => _local.month;
  int get dia => _local.day;
}

String formatoFecha(int anio, int mes, int dia) =>
    '${anio.toString().padLeft(4, '0')}-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';

/// Instante UTC en que inicia el día de negocio `AAAA-MM-DD` (00:00 en México).
DateTime inicioDelDiaUtc(String fecha) {
  final partes = fecha.split('-').map(int.parse).toList();
  return DateTime.utc(partes[0], partes[1], partes[2]).subtract(desfaseMexico);
}

/// Instante UTC en que inicia el bloque [hora] del día [fecha].
DateTime inicioDelBloqueUtc(String fecha, int hora) =>
    inicioDelDiaUtc(fecha).add(Duration(hours: hora));

/// Minutos transcurridos desde el inicio del bloque hasta [instante] (puede
/// ser negativo si es antes del bloque).
int minutosDesdeInicioDelBloque(String fecha, int hora, DateTime instante) =>
    instante.toUtc().difference(inicioDelBloqueUtc(fecha, hora)).inMinutes;

/// Fechas `AAAA-MM-DD` de lunes a domingo de la semana que contiene [fecha].
List<String> semanaDe(String fecha) {
  final inicio = DateTime.utc(
    int.parse(fecha.substring(0, 4)),
    int.parse(fecha.substring(5, 7)),
    int.parse(fecha.substring(8, 10)),
  );
  final lunes = inicio.subtract(Duration(days: inicio.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      () {
        final d = lunes.add(Duration(days: i));
        return formatoFecha(d.year, d.month, d.day);
      }(),
  ];
}
