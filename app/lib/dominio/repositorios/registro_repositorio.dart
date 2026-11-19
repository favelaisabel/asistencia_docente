import '../horario.dart';
import '../registro.dart';
import '../usuario.dart';

/// Datos de una captura en el aula.
class Captura {
  const Captura({
    required this.estado,
    this.suplenteNombre = '',
    this.observacion = '',
  });

  final EstadoCaptura estado;
  final String suplenteNombre;
  final String observacion;
}

/// Registros de asistencia y su bitácora (RF-014 a RF-022, RF-030 a RF-033).
abstract interface class RegistroRepositorio {
  /// Registros de un día; marca los que aún no llegan al servidor.
  Stream<List<Registro>> registrosDelDia(String fecha);

  /// `true` mientras la app trabaja sin conexión con el servidor (RF-021).
  Stream<bool> sinConexion(String fecha);

  /// Registros entre dos fechas `AAAA-MM-DD` inclusive (reportes, COO).
  Future<List<Registro>> registrosEntre(String desde, String hasta);

  /// Primera captura de un aula (lote registro + bitácora v1). No espera al
  /// servidor: funciona sin conexión.
  Future<void> registrar({
    required Clase clase,
    required String periodoId,
    required String fecha,
    required int hora,
    required Captura captura,
    required DateTime horaDispositivo,
    required int desfaseRelojMs,
    required bool sinConexion,
    required Usuario usuario,
  });

  /// "Ya llegó" sobre un registro "Aún no llega" (RN-003).
  Future<void> marcarLlegada({
    required Registro registro,
    required DateTime llegada,
    required Usuario usuario,
  });

  /// Corrección. El encargado durante el bloque; Coordinación con [motivo].
  Future<void> corregir({
    required Registro registro,
    required Captura captura,
    required Usuario usuario,
    String motivo = '',
  });

  Stream<List<EntradaBitacora>> bitacora(String registroId);

  /// Diferencia reloj del dispositivo − servidor, en ms (RNF-008).
  Future<int> medirDesfaseReloj(String uid, DateTime ahoraDispositivo);
}
