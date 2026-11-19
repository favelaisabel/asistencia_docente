import '../sesion.dart';

/// Acceso al sistema (RF-001, RF-002, RF-005; ADR-005).
///
/// Los métodos lanzan una `Falla` (dominio/fallas.dart) cuando algo esperado
/// sale mal; la navegación reacciona a [cambiosSesion].
abstract interface class AutenticacionRepositorio {
  Stream<EstadoSesion> cambiosSesion();

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Primer acceso, paso 1: crea la cuenta solo si el correo está
  /// pre-registrado y envía el enlace de confirmación.
  Future<void> crearCuenta({
    required String correo,
    required String contrasena,
  });

  Future<void> reenviarVerificacion();

  /// Primer acceso, paso 2: con el correo ya confirmado, crea el perfil con
  /// el rol del pre-registro.
  Future<void> completarPerfil();

  Future<void> cerrarSesion();
}
