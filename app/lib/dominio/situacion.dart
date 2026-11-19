import 'registro.dart';
import 'tiempo.dart';

/// Situación efectiva: se CALCULA al leer, no se guarda (ADR-004, 06 §5).
enum Situacion {
  aTiempo('A tiempo', incidencia: false),
  retardo('Retardo', incidencia: true),
  falta('Falta', incidencia: true),
  pendiente('Aún no llega', incidencia: false),
  suplencia('Suplente', incidencia: false),
  sinAlumnos('Sin alumnos', incidencia: false),
  noProgramada('Clase no programada', incidencia: false),
  justificado('Justificado', incidencia: false);

  const Situacion(this.etiqueta, {required this.incidencia});

  final String etiqueta;

  /// Cuenta como retardo o falta en los reportes.
  final bool incidencia;
}

/// Tolerancias de RN-002.
const int minutosATiempo = 15;
const int minutosRetardo = 30;

Situacion _porMinuto(int minuto) {
  if (minuto <= minutosATiempo) return Situacion.aTiempo;
  if (minuto <= minutosRetardo) return Situacion.retardo;
  return Situacion.falta;
}

/// RN-002, RN-003, RN-005, RN-013.
///
/// [minutoActual]: minutos transcurridos desde el inicio del bloque en el
/// momento de calcular (un valor ≥ 60 significa que el bloque ya terminó).
Situacion calcularSituacion({
  required EstadoCaptura estado,
  required int? minutoLlegada,
  required int minutoActual,
  JustificacionEstado justificacion = JustificacionEstado.ninguna,
}) {
  if (justificacion == JustificacionEstado.aprobada) {
    return Situacion.justificado;
  }
  switch (estado) {
    case EstadoCaptura.presente:
      return Situacion.aTiempo;
    case EstadoCaptura.retardo:
      return Situacion.retardo;
    case EstadoCaptura.suplente:
      return Situacion.suplencia;
    case EstadoCaptura.sinAlumnos:
      return Situacion.sinAlumnos;
    case EstadoCaptura.sinDocente:
      return Situacion.falta;
    case EstadoCaptura.noProgramada:
      return Situacion.noProgramada;
    case EstadoCaptura.aunNoLlega:
      if (minutoLlegada != null) return _porMinuto(minutoLlegada);
      return minutoActual > minutosRetardo
          ? Situacion.falta
          : Situacion.pendiente;
  }
}

/// Situación de un registro en el instante [ahoraUtc].
Situacion situacionDe(Registro registro, DateTime ahoraUtc) =>
    calcularSituacion(
      estado: registro.estado,
      minutoLlegada: registro.minutoLlegada,
      minutoActual: minutosDesdeInicioDelBloque(
        registro.fecha,
        registro.hora,
        ahoraUtc,
      ),
      justificacion: registro.justificacion,
    );

/// RNF-008 (refinado en 06 §6): el desfase del reloj del celular supera 5 min,
/// o la hora del celular es posterior a la del servidor (con 1 min de tolerancia).
bool esHoraDudosa({
  required DateTime horaDispositivo,
  required DateTime? horaServidor,
  required int desfaseRelojMs,
}) {
  if (desfaseRelojMs.abs() > const Duration(minutes: 5).inMilliseconds) {
    return true;
  }
  if (horaServidor == null) return false;
  return horaDispositivo.isAfter(horaServidor.add(const Duration(minutes: 1)));
}
