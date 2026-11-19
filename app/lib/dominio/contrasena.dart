/// Política de contraseñas (08_SEGURIDAD_CONTINUIDAD, C-01).
library;

const int longitudMinimaContrasena = 10;

enum ProblemaContrasena { muyCorta, sinLetras, sinNumeros }

/// Devuelve el problema encontrado, o `null` si la contraseña es aceptable.
ProblemaContrasena? validarContrasena(String contrasena) {
  if (contrasena.length < longitudMinimaContrasena) {
    return ProblemaContrasena.muyCorta;
  }
  if (!RegExp('[A-Za-zÁÉÍÓÚÑáéíóúñ]').hasMatch(contrasena)) {
    return ProblemaContrasena.sinLetras;
  }
  if (!RegExp('[0-9]').hasMatch(contrasena)) {
    return ProblemaContrasena.sinNumeros;
  }
  return null;
}
