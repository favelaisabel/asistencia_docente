import 'usuario.dart';

/// Estado de la sesión, del que depende la navegación por rol.
sealed class EstadoSesion {
  const EstadoSesion();
}

/// Nadie ha iniciado sesión.
final class SinSesion extends EstadoSesion {
  const SinSesion();
}

/// Cuenta creada en el primer acceso, pero el correo aún no se confirma.
final class PendienteVerificacion extends EstadoSesion {
  const PendienteVerificacion(this.correo);
  final String correo;
}

/// Correo confirmado, pero falta crear el perfil a partir del pre-registro.
final class SinPerfil extends EstadoSesion {
  const SinPerfil(this.correo);
  final String correo;
}

/// Perfil desactivado por Coordinación (RF-004, C-04).
final class SesionDesactivada extends EstadoSesion {
  const SesionDesactivada();
}

/// Sesión completa con perfil activo.
final class ConPerfil extends EstadoSesion {
  const ConPerfil(this.usuario);
  final Usuario usuario;
}
