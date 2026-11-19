import '../horario.dart';

/// Periodo e importación vigentes (`config/sistema`, 06 §4.1).
class HorarioVigente {
  const HorarioVigente({
    required this.periodoId,
    required this.periodoNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.importacionId,
    required this.totalClases,
    required this.archivoNombre,
    required this.importadoEn,
  });

  final String periodoId;
  final String periodoNombre;
  final String fechaInicio;
  final String fechaFin;
  final String importacionId;
  final int totalClases;
  final String archivoNombre;
  final DateTime? importadoEn;
}

/// Horario oficial (RF-006, RF-010, RF-013).
abstract interface class HorarioRepositorio {
  /// `null` si aún no hay horario activo.
  Stream<HorarioVigente?> vigente();

  /// Clases de la importación activa para un día de la semana (1–6).
  Stream<List<Clase>> clasesDelDia(String importacionId, int diaSemana);

  /// Importación versionada (06 §7.2): si algo falla, el horario anterior
  /// sigue vigente. [progreso] recibe valores de 0 a 1.
  Future<void> importar({
    required List<Clase> clases,
    required String periodoNombre,
    required String fechaInicio,
    required String fechaFin,
    required String archivoNombre,
    void Function(double)? progreso,
  });
}
