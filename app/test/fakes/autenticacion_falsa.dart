import 'dart:async';

import 'package:asistencia_docente/dominio/fallas.dart';
import 'package:asistencia_docente/dominio/repositorios/autenticacion_repositorio.dart';
import 'package:asistencia_docente/dominio/sesion.dart';

/// Repositorio de acceso en memoria para pruebas de pantallas.
class AutenticacionFalsa implements AutenticacionRepositorio {
  AutenticacionFalsa({EstadoSesion inicial = const SinSesion()})
    : _estado = inicial;

  final _cambios = StreamController<EstadoSesion>.broadcast();
  EstadoSesion _estado;

  /// Falla que lanzará el próximo `iniciarSesion`; `null` = éxito.
  Falla? fallaAlEntrar;
  int intentosDeEntrada = 0;

  void emitir(EstadoSesion estado) {
    _estado = estado;
    _cambios.add(estado);
  }

  @override
  Stream<EstadoSesion> cambiosSesion() async* {
    yield _estado;
    yield* _cambios.stream;
  }

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    intentosDeEntrada++;
    final falla = fallaAlEntrar;
    if (falla != null) throw falla;
  }

  @override
  Future<void> cerrarSesion() async => emitir(const SinSesion());

  @override
  Future<void> crearCuenta({
    required String correo,
    required String contrasena,
  }) async {}

  @override
  Future<void> completarPerfil() async {}

  @override
  Future<void> reenviarVerificacion() async {}
}
