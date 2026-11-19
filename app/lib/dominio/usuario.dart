import 'rol.dart';

/// Perfil de un usuario (`usuarios/{uid}`, 06_MODELO_DATOS §4.2).
class Usuario {
  const Usuario({
    required this.uid,
    required this.correo,
    required this.nombre,
    required this.rol,
    required this.activo,
  });

  final String uid;
  final String correo;
  final String nombre;
  final Rol rol;
  final bool activo;
}

/// Alta pendiente hecha por Coordinación (`preregistros/{correo}`, 06 §4.3).
class Preregistro {
  const Preregistro({
    required this.correo,
    required this.nombre,
    required this.rol,
    required this.usado,
  });

  final String correo;
  final String nombre;
  final Rol rol;
  final bool usado;
}
