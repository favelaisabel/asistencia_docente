import 'dart:async';

import 'package:asistencia_docente/dominio/horario.dart';
import 'package:asistencia_docente/dominio/registro.dart';
import 'package:asistencia_docente/dominio/repositorios/horario_repositorio.dart';
import 'package:asistencia_docente/dominio/repositorios/registro_repositorio.dart';
import 'package:asistencia_docente/dominio/turno.dart';
import 'package:asistencia_docente/dominio/usuario.dart';

/// Horario en memoria: todas las clases dadas, todos los días.
class HorarioFalso implements HorarioRepositorio {
  HorarioFalso(this.clases, {this.activo = true});

  final List<Clase> clases;
  final bool activo;

  @override
  Stream<HorarioVigente?> vigente() => Stream.value(
    activo
        ? const HorarioVigente(
            periodoId: '2026-2',
            periodoNombre: '2026-2',
            fechaInicio: '2026-08-10',
            fechaFin: '2026-12-11',
            importacionId: 'imp1',
            totalClases: 10,
            archivoNombre: 'horario.csv',
            importadoEn: null,
          )
        : null,
  );

  @override
  Stream<List<Clase>> clasesDelDia(String importacionId, int diaSemana) =>
      Stream.value(clases.where((c) => c.diaSemana == diaSemana).toList());

  @override
  Future<void> importar({
    required List<Clase> clases,
    required String periodoNombre,
    required String fechaInicio,
    required String fechaFin,
    required String archivoNombre,
    void Function(double)? progreso,
  }) async {}
}

/// Registros en memoria con el mismo comportamiento de versiones que Firestore.
class RegistrosFalsos implements RegistroRepositorio {
  final _registros = <String, Registro>{};
  final _cambios = StreamController<void>.broadcast();
  final bitacoraEscrita = <EntradaBitacora>[];

  Iterable<Registro> get todos => _registros.values;

  void _guardar(Registro r, String accion, Usuario u, {String motivo = ''}) {
    _registros[r.id] = r;
    bitacoraEscrita.add(
      EntradaBitacora(
        registroId: r.id,
        version: r.version,
        accion: accion,
        antes: const {},
        despues: {'estadoCaptura': r.estado.codigo},
        motivo: motivo,
        usuarioUid: u.uid,
        usuarioNombre: u.nombre,
        usuarioRol: u.rol.codigo,
        horaServidor: null,
      ),
    );
    _cambios.add(null);
  }

  @override
  Stream<List<Registro>> registrosDelDia(String fecha) async* {
    List<Registro> delDia() =>
        _registros.values.where((r) => r.fecha == fecha).toList();
    yield delDia();
    yield* _cambios.stream.map((_) => delDia());
  }

  @override
  Stream<bool> sinConexion(String fecha) => Stream.value(false);

  @override
  Future<List<Registro>> registrosEntre(String desde, String hasta) async =>
      _registros.values
          .where(
            (r) =>
                r.fecha.compareTo(desde) >= 0 && r.fecha.compareTo(hasta) <= 0,
          )
          .toList();

  @override
  Future<void> registrar({
    required Clase clase,
    required String periodoId,
    required String fecha,
    required int hora,
    required Captura captura,
    required DateTime horaDispositivo,
    required int desfaseRelojMs,
    required bool sinConexion,
    required Usuario usuario,
  }) async {
    _guardar(
      Registro(
        id: idRegistro(clase.aulaId, fecha, hora),
        periodoId: periodoId,
        claseId: clase.id,
        aulaId: clase.aulaId,
        fecha: fecha,
        hora: hora,
        turno: (Turno.deBloque(hora) ?? Turno.matutino).codigo,
        docenteId: clase.docenteId,
        docenteNombre: clase.docenteNombre,
        materia: clase.materia,
        grupo: clase.grupo,
        estado: captura.estado,
        suplenteNombre: captura.suplenteNombre,
        observacion: captura.observacion,
        horaDispositivo: horaDispositivo,
        horaServidor: horaDispositivo,
        llegadaDispositivo: null,
        desfaseRelojMs: desfaseRelojMs,
        capturadoSinConexion: sinConexion,
        origen: 'APP',
        registradoPor: usuario.uid,
        version: 1,
        actualizadoPor: usuario.uid,
        justificacion: JustificacionEstado.ninguna,
      ),
      'CREAR',
      usuario,
    );
  }

  Registro _copia(
    Registro r, {
    EstadoCaptura? estado,
    String? suplente,
    DateTime? llegada,
  }) => Registro(
    id: r.id,
    periodoId: r.periodoId,
    claseId: r.claseId,
    aulaId: r.aulaId,
    fecha: r.fecha,
    hora: r.hora,
    turno: r.turno,
    docenteId: r.docenteId,
    docenteNombre: r.docenteNombre,
    materia: r.materia,
    grupo: r.grupo,
    estado: estado ?? r.estado,
    suplenteNombre: suplente ?? r.suplenteNombre,
    observacion: r.observacion,
    horaDispositivo: r.horaDispositivo,
    horaServidor: r.horaServidor,
    llegadaDispositivo: llegada ?? r.llegadaDispositivo,
    desfaseRelojMs: r.desfaseRelojMs,
    capturadoSinConexion: r.capturadoSinConexion,
    origen: r.origen,
    registradoPor: r.registradoPor,
    version: r.version + 1,
    actualizadoPor: r.actualizadoPor,
    justificacion: r.justificacion,
  );

  @override
  Future<void> marcarLlegada({
    required Registro registro,
    required DateTime llegada,
    required Usuario usuario,
  }) async => _guardar(_copia(registro, llegada: llegada), 'LLEGADA', usuario);

  @override
  Future<void> corregir({
    required Registro registro,
    required Captura captura,
    required Usuario usuario,
    String motivo = '',
  }) async => _guardar(
    _copia(registro, estado: captura.estado, suplente: captura.suplenteNombre),
    'CORREGIR',
    usuario,
    motivo: motivo,
  );

  @override
  Stream<List<EntradaBitacora>> bitacora(String registroId) => Stream.value(
    bitacoraEscrita.where((e) => e.registroId == registroId).toList(),
  );

  @override
  Future<int> medirDesfaseReloj(String uid, DateTime ahoraDispositivo) async =>
      0;
}

/// Clases de ejemplo: 3 aulas con clase de 9:00 a 11:00 de lunes a sábado.
List<Clase> clasesDeEjemplo() => [
  for (var dia = 1; dia <= 6; dia++)
    for (final (aula, empleado, nombre) in [
      ('A101', '1001', 'Laura Pérez Soto'),
      ('A102', '1002', 'Jorge Ramírez Luna'),
      ('A103', '1003', 'Elena Torres Vega'),
    ])
      Clase(
        id: '$aula-$dia',
        aulaId: aula,
        docenteId: empleado,
        docenteNombre: nombre,
        materia: 'Materia $aula',
        grupo: '1A',
        diaSemana: dia,
        horaInicio: 9,
        horaFin: 11,
      ),
];
