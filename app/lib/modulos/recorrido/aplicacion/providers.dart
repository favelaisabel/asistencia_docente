import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reloj.dart';
import '../../../datos/firestore_registro_repositorio.dart';
import '../../../dominio/fallas.dart';
import '../../../dominio/horario.dart';
import '../../../dominio/registro.dart';
import '../../../dominio/repositorios/registro_repositorio.dart';
import '../../../dominio/sesion.dart';
import '../../../dominio/tiempo.dart';
import '../../autenticacion/aplicacion/providers.dart';
import '../../horario/aplicacion/providers.dart';

/// `--dart-define=HORA_DEMO=09:05` hace que la app viva hoy a esa hora local,
/// para demostraciones fuera del horario de clases. Los registros quedarán
/// marcados como "hora dudosa", porque el reloj está desplazado (RNF-008).
const String _horaDemo = String.fromEnvironment('HORA_DEMO');

Reloj _crearReloj() {
  final partes = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(_horaDemo);
  if (partes == null) return const RelojSistema();
  final hoy = MomentoNegocio.desdeUtc(DateTime.now().toUtc());
  final inicio = inicioDelDiaUtc(hoy.fecha).add(
    Duration(
      hours: int.parse(partes.group(1)!),
      minutes: int.parse(partes.group(2)!),
    ),
  );
  return RelojDesplazado(inicio);
}

final relojProvider = Provider<Reloj>((ref) => _crearReloj());

/// Hora actual que se refresca cada 20 s (avance de minutos y bloques).
final ahoraProvider = StreamProvider<DateTime>((ref) async* {
  final reloj = ref.watch(relojProvider);
  yield reloj.ahora();
  yield* Stream.periodic(const Duration(seconds: 20), (_) => reloj.ahora());
});

final registroRepositorioProvider = Provider<RegistroRepositorio>(
  (ref) => FirestoreRegistroRepositorio(FirebaseFirestore.instance),
);

final registrosDelDiaProvider = StreamProvider.family<List<Registro>, String>(
  (ref, fecha) => ref.watch(registroRepositorioProvider).registrosDelDia(fecha),
);

final sinConexionProvider = StreamProvider.family<bool, String>(
  (ref, fecha) => ref.watch(registroRepositorioProvider).sinConexion(fecha),
);

final bitacoraProvider = StreamProvider.family<List<EntradaBitacora>, String>(
  (ref, id) => ref.watch(registroRepositorioProvider).bitacora(id),
);

/// Desfase del reloj medido al abrir la app (0 si no hay conexión).
final desfaseRelojProvider = FutureProvider<int>((ref) async {
  final sesion = ref.watch(sesionProvider).value;
  if (sesion is! ConPerfil) return 0;
  try {
    return await ref
        .read(registroRepositorioProvider)
        .medirDesfaseReloj(sesion.usuario.uid, ref.read(relojProvider).ahora());
  } catch (_) {
    return 0;
  }
});

/// Acciones del encargado en el recorrido (RF-014 a RF-022).
class AccionesRecorrido {
  AccionesRecorrido(this._ref);

  final Ref _ref;

  ConPerfil _sesion() {
    final sesion = _ref.read(sesionProvider).value;
    if (sesion is! ConPerfil) throw const SinPermiso();
    return sesion;
  }

  Future<void> registrar({
    required Clase clase,
    required String fecha,
    required int hora,
    required Captura captura,
  }) async {
    final vigente = _ref.read(horarioVigenteProvider).value;
    await _ref
        .read(registroRepositorioProvider)
        .registrar(
          clase: clase,
          periodoId: vigente?.periodoId ?? '',
          fecha: fecha,
          hora: hora,
          captura: captura,
          horaDispositivo: _ref.read(relojProvider).ahora(),
          desfaseRelojMs: _ref.read(desfaseRelojProvider).value ?? 0,
          sinConexion: _ref.read(sinConexionProvider(fecha)).value ?? false,
          usuario: _sesion().usuario,
        );
  }

  Future<void> marcarLlegada(Registro registro) => _ref
      .read(registroRepositorioProvider)
      .marcarLlegada(
        registro: registro,
        llegada: _ref.read(relojProvider).ahora(),
        usuario: _sesion().usuario,
      );

  Future<void> corregir(
    Registro registro,
    Captura captura, {
    String motivo = '',
  }) => _ref
      .read(registroRepositorioProvider)
      .corregir(
        registro: registro,
        captura: captura,
        usuario: _sesion().usuario,
        motivo: motivo,
      );
}

final accionesRecorridoProvider = Provider<AccionesRecorrido>(
  AccionesRecorrido.new,
);
