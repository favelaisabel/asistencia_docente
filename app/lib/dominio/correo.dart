/// Reglas de correo usadas en el acceso y el pre-registro (RF-001, RF-004).
library;

final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Forma canónica: sin espacios alrededor y en minúsculas.
/// Es también el ID del documento `preregistros/{correo}` (06_MODELO_DATOS §4.3).
String normalizarCorreo(String correo) => correo.trim().toLowerCase();

bool esCorreoValido(String correo) => _formatoCorreo.hasMatch(correo.trim());
