/// Roles del sistema (03_REQUISITOS §2).
enum Rol {
  encargado('ENC', 'Encargado'),
  docente('DOC', 'Docente'),
  coordinacion('COO', 'Coordinación');

  const Rol(this.codigo, this.nombre);

  /// Código guardado en Firestore.
  final String codigo;

  /// Nombre para mostrar.
  final String nombre;

  static Rol? desdeCodigo(String? codigo) {
    for (final rol in Rol.values) {
      if (rol.codigo == codigo) return rol;
    }
    return null;
  }
}
