import '../../../dominio/rol.dart';
import '../../../dominio/sesion.dart';

/// Rutas de la aplicación.
abstract final class Rutas {
  static const cargando = '/cargando';
  static const entrar = '/entrar';
  static const primerAcceso = '/primer-acceso';
  static const noDisponible = '/no-disponible';
  static const recorrido = '/recorrido';
  static const coordinacion = '/coordinacion';
  static const docente = '/docente';
}

enum Plataforma { movil, web }

/// Pantalla de inicio de cada rol en cada plataforma (ADR-001: el encargado
/// usa la app Android; Coordinación y docentes, la web).
String? inicioDeRol(Rol rol, Plataforma plataforma) {
  return switch ((plataforma, rol)) {
    (Plataforma.movil, Rol.encargado) => Rutas.recorrido,
    (Plataforma.web, Rol.coordinacion) => Rutas.coordinacion,
    (Plataforma.web, Rol.docente) => Rutas.docente,
    _ => null,
  };
}

/// Decide a dónde debe ir el usuario según su sesión. Devuelve `null` si
/// puede quedarse en [ubicacion].
String? redirigir({
  required EstadoSesion? sesion,
  required String ubicacion,
  required Plataforma plataforma,
}) {
  String? ir(String destino) => ubicacion.startsWith(destino) ? null : destino;

  switch (sesion) {
    case null:
      return ir(Rutas.cargando);
    case SinSesion():
      if (ubicacion == Rutas.entrar || ubicacion == Rutas.primerAcceso) {
        return null;
      }
      return Rutas.entrar;
    case PendienteVerificacion() || SinPerfil():
      return ir(Rutas.primerAcceso);
    case SesionDesactivada():
      return ir(Rutas.noDisponible);
    case ConPerfil(:final usuario):
      final inicio = inicioDeRol(usuario.rol, plataforma);
      return ir(inicio ?? Rutas.noDisponible);
  }
}
