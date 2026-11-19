import '../rol.dart';
import '../usuario.dart';

/// Gestión de usuarios por Coordinación (RF-004).
abstract interface class UsuarioRepositorio {
  Stream<List<Usuario>> usuarios();

  Stream<List<Preregistro>> preregistrosPendientes();

  /// Lanza `PreregistroDuplicado` si el correo ya tiene pre-registro.
  Future<void> preregistrar({
    required String correo,
    required String nombre,
    required Rol rol,
  });

  Future<void> cancelarPreregistro(String correo);

  Future<void> cambiarActivo({required String uid, required bool activo});
}
