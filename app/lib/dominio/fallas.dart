/// Fallas esperadas que la capa de datos entrega al resto de la app
/// (10_ESTANDARES §7). La presentación las traduce a mensajes de 07_UX_UI §6.
sealed class Falla implements Exception {
  const Falla();
}

final class CredencialesInvalidas extends Falla {
  const CredencialesInvalidas();
}

final class CuentaDesactivada extends Falla {
  const CuentaDesactivada();
}

final class DemasiadosIntentos extends Falla {
  const DemasiadosIntentos();
}

final class SinConexion extends Falla {
  const SinConexion();
}

final class SinPermiso extends Falla {
  const SinPermiso();
}

/// El correo no tiene pre-registro (ADR-005).
final class SinPreregistro extends Falla {
  const SinPreregistro();
}

/// Ya existe una cuenta de acceso con ese correo.
final class CuentaYaExiste extends Falla {
  const CuentaYaExiste();
}

/// Coordinación intenta pre-registrar un correo que ya está registrado.
final class PreregistroDuplicado extends Falla {
  const PreregistroDuplicado();
}

final class ContrasenaDebil extends Falla {
  const ContrasenaDebil();
}

final class CorreoNoVerificado extends Falla {
  const CorreoNoVerificado();
}

final class FallaDesconocida extends Falla {
  const FallaDesconocida(this.codigo);

  /// Código técnico para el registro (sin datos personales).
  final String codigo;
}
