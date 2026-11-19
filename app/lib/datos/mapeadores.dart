import 'dart:developer';

import '../dominio/rol.dart';
import '../dominio/usuario.dart';

/// Conversión documento ↔ entidad con validación (10_ESTANDARES §7: sin `!`
/// sobre datos externos). Un documento inválido devuelve `null` y se registra
/// solo su ID técnico.

Usuario? usuarioDesdeDatos(String uid, Map<String, dynamic>? datos) {
  if (datos == null) return null;
  final correo = datos['correo'];
  final nombre = datos['nombre'];
  final rol = Rol.desdeCodigo(
    datos['rol'] is String ? datos['rol'] as String : null,
  );
  final activo = datos['activo'];
  if (correo is! String ||
      nombre is! String ||
      rol == null ||
      activo is! bool) {
    log('Perfil con formato inválido: $uid', name: 'datos');
    return null;
  }
  return Usuario(
    uid: uid,
    correo: correo,
    nombre: nombre,
    rol: rol,
    activo: activo,
  );
}

Preregistro? preregistroDesdeDatos(String id, Map<String, dynamic>? datos) {
  if (datos == null) return null;
  final nombre = datos['nombre'];
  final rol = Rol.desdeCodigo(
    datos['rol'] is String ? datos['rol'] as String : null,
  );
  final usado = datos['usado'];
  if (nombre is! String || rol == null || usado is! bool) {
    log('Pre-registro con formato inválido', name: 'datos');
    return null;
  }
  return Preregistro(correo: id, nombre: nombre, rol: rol, usado: usado);
}
