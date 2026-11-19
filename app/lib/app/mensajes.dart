import '../dominio/contrasena.dart';
import '../dominio/fallas.dart';

/// Mensajes al usuario (07_UX_UI §6). Nunca se muestra el texto técnico.
String mensajeDeError(Object error) {
  if (error is! Falla) {
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  return switch (error) {
    CredencialesInvalidas() => 'Correo o contraseña incorrectos.',
    CuentaDesactivada() =>
      'Tu cuenta está desactivada. Consulta a Coordinación.',
    DemasiadosIntentos() =>
      'Demasiados intentos. Espera unos minutos y vuelve a intentarlo.',
    SinConexion() => 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    SinPermiso() => 'No tienes permiso para esta acción.',
    SinPreregistro() =>
      'Este correo no está pre-registrado. Pide a Coordinación que te dé de alta.',
    CuentaYaExiste() => 'Ya existe una cuenta con este correo. Usa «Entrar».',
    PreregistroDuplicado() => 'Ese correo ya está registrado.',
    ContrasenaDebil() => mensajeContrasena(ProblemaContrasena.muyCorta),
    CorreoNoVerificado() =>
      'Aún no confirmas tu correo. Abre el enlace que te enviamos y vuelve a intentarlo.',
    FallaDesconocida() => 'Ocurrió un error inesperado. Inténtalo de nuevo.',
  };
}

String mensajeContrasena(ProblemaContrasena problema) => switch (problema) {
  ProblemaContrasena.muyCorta =>
    'La contraseña debe tener al menos $longitudMinimaContrasena caracteres, con letras y números.',
  ProblemaContrasena.sinLetras => 'La contraseña debe incluir letras.',
  ProblemaContrasena.sinNumeros => 'La contraseña debe incluir números.',
};
