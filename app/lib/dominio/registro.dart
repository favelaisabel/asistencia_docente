import 'tiempo.dart';

/// Lo que observa el encargado (06_MODELO_DATOS §5, RN-001).
enum EstadoCaptura {
  presente('PRESENTE', 'Presente'),
  aunNoLlega('AUN_NO_LLEGA', 'Aún no llega'),
  retardo('RETARDO', 'Retardo'),
  suplente('SUPLENTE', 'Suplente'),
  sinAlumnos('SIN_ALUMNOS', 'Sin alumnos'),
  sinDocente('SIN_DOCENTE', 'Sin docente'),
  noProgramada('NO_PROGRAMADA', 'Clase no programada');

  const EstadoCaptura(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoCaptura? desdeCodigo(String? codigo) {
    for (final e in values) {
      if (e.codigo == codigo) return e;
    }
    return null;
  }
}

enum JustificacionEstado {
  ninguna('NINGUNA'),
  pendiente('PENDIENTE'),
  aprobada('APROBADA'),
  rechazada('RECHAZADA');

  const JustificacionEstado(this.codigo);
  final String codigo;

  static JustificacionEstado desdeCodigo(String? codigo) =>
      values.firstWhere((e) => e.codigo == codigo, orElse: () => ninguna);
}

/// ID determinista `{aula}_{AAAAMMDD}_{HH}`: un registro por aula, fecha y
/// bloque, aun sin conexión (RN-006, ADR-004).
String idRegistro(String aulaId, String fecha, int hora) =>
    '${aulaId}_${fecha.replaceAll('-', '')}_${hora.toString().padLeft(2, '0')}';

/// Registro de asistencia (`registros/{id}`, 06_MODELO_DATOS §4.9).
class Registro {
  const Registro({
    required this.id,
    required this.periodoId,
    required this.claseId,
    required this.aulaId,
    required this.fecha,
    required this.hora,
    required this.turno,
    required this.docenteId,
    required this.docenteNombre,
    required this.materia,
    required this.grupo,
    required this.estado,
    required this.suplenteNombre,
    required this.observacion,
    required this.horaDispositivo,
    required this.horaServidor,
    required this.llegadaDispositivo,
    required this.desfaseRelojMs,
    required this.capturadoSinConexion,
    required this.origen,
    required this.registradoPor,
    required this.version,
    required this.actualizadoPor,
    required this.justificacion,
    this.pendienteDeEnvio = false,
  });

  final String id;
  final String periodoId;
  final String claseId;
  final String aulaId;
  final String fecha;
  final int hora;
  final String turno;
  final String docenteId;
  final String docenteNombre;
  final String materia;
  final String grupo;
  final EstadoCaptura estado;
  final String suplenteNombre;
  final String observacion;
  final DateTime horaDispositivo;
  final DateTime? horaServidor;
  final DateTime? llegadaDispositivo;
  final int desfaseRelojMs;
  final bool capturadoSinConexion;
  final String origen;
  final String registradoPor;
  final int version;
  final String actualizadoPor;
  final JustificacionEstado justificacion;

  /// Escrito en el dispositivo y aún no confirmado por el servidor (RF-021).
  final bool pendienteDeEnvio;

  /// Minuto del bloque en que se registró la llegada (RN-003).
  int? get minutoLlegada => llegadaDispositivo == null
      ? null
      : minutosDesdeInicioDelBloque(fecha, hora, llegadaDispositivo!);

  int get minutoCaptura =>
      minutosDesdeInicioDelBloque(fecha, hora, horaDispositivo);
}

/// Entrada de la bitácora (`bitacora/{registroId}_v{n}`, 06 §4.10).
class EntradaBitacora {
  const EntradaBitacora({
    required this.registroId,
    required this.version,
    required this.accion,
    required this.antes,
    required this.despues,
    required this.motivo,
    required this.usuarioUid,
    required this.usuarioNombre,
    required this.usuarioRol,
    required this.horaServidor,
  });

  final String registroId;
  final int version;
  final String accion;
  final Map<String, Object?> antes;
  final Map<String, Object?> despues;
  final String motivo;
  final String usuarioUid;
  final String usuarioNombre;
  final String usuarioRol;
  final DateTime? horaServidor;
}
