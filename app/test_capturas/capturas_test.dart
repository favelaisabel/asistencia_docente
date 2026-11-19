// Genera las capturas de pantalla del manual de usuario a partir de las
// pantallas REALES de la app, con datos de ejemplo en memoria.
//
// Uso:  flutter test test_capturas/capturas_test.dart
// Salida: ../docs/manual/capturas/*.png
//
// No forma parte de la suite de CI (está fuera de test/).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:asistencia_docente/app/app_movil.dart';
import 'package:asistencia_docente/app/app_web.dart';
import 'package:asistencia_docente/app/localizacion.dart';
import 'package:asistencia_docente/app/tema.dart';
import 'package:asistencia_docente/core/reloj.dart';
import 'package:asistencia_docente/dominio/horario.dart';
import 'package:asistencia_docente/dominio/registro.dart';
import 'package:asistencia_docente/dominio/repositorios/usuario_repositorio.dart';
import 'package:asistencia_docente/dominio/rol.dart';
import 'package:asistencia_docente/dominio/sesion.dart';
import 'package:asistencia_docente/dominio/tiempo.dart';
import 'package:asistencia_docente/dominio/turno.dart';
import 'package:asistencia_docente/dominio/usuario.dart';
import 'package:asistencia_docente/modulos/autenticacion/aplicacion/providers.dart';
import 'package:asistencia_docente/modulos/horario/aplicacion/lector_archivo.dart';
import 'package:asistencia_docente/modulos/horario/aplicacion/providers.dart';
import 'package:asistencia_docente/modulos/horario/presentacion/horario_pantalla.dart';
import 'package:asistencia_docente/modulos/recorrido/aplicacion/providers.dart';
import 'package:asistencia_docente/modulos/usuarios/aplicacion/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/fakes/autenticacion_falsa.dart';
import '../test/fakes/datos_falsos.dart';

const salida = '../docs/manual/capturas';
const fecha = '2026-11-19';

/// Jueves 19 nov 2026, 9:22 en México.
final ahora = inicioDelBloqueUtc(fecha, 9).add(const Duration(minutes: 22));

const encargado = Usuario(
  uid: 'enc',
  correo: 'encargado@demo.edu.mx',
  nombre: 'Carlos Medina Ríos',
  rol: Rol.encargado,
  activo: true,
);
const coordinacion = Usuario(
  uid: 'coo',
  correo: 'coordinacion@demo.edu.mx',
  nombre: 'Ana Ruiz Campos',
  rol: Rol.coordinacion,
  activo: true,
);

late List<Clase> clasesDemo;

Future<void> cargarFuentes() async {
  final raiz = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final dir = '$raiz/bin/cache/artifacts/material_fonts';
  Future<ByteData> leer(String archivo) async =>
      ByteData.sublistView(await File('$dir/$archivo').readAsBytes());
  final roboto = FontLoader('Roboto')
    ..addFont(leer('roboto-regular.ttf'))
    ..addFont(leer('roboto-medium.ttf'))
    ..addFont(leer('roboto-bold.ttf'));
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(leer('materialicons-regular.otf'))).load();
}

class UsuariosFalsos implements UsuarioRepositorio {
  @override
  Stream<List<Usuario>> usuarios() => Stream.value(const [
    coordinacion,
    encargado,
    Usuario(
      uid: 'coo2',
      correo: 'subdireccion@demo.edu.mx',
      nombre: 'Jorge Lara Méndez',
      rol: Rol.coordinacion,
      activo: true,
    ),
    Usuario(
      uid: 'enc2',
      correo: 'apoyo.recorridos@demo.edu.mx',
      nombre: 'Martha Ochoa Ruiz',
      rol: Rol.encargado,
      activo: false,
    ),
  ]);

  @override
  Stream<List<Preregistro>> preregistrosPendientes() => Stream.value(const [
    Preregistro(
      correo: 'nuevo.encargado@demo.edu.mx',
      nombre: 'Rosa Jiménez Paz',
      rol: Rol.encargado,
      usado: false,
    ),
  ]);

  @override
  Future<void> preregistrar({
    required String correo,
    required String nombre,
    required Rol rol,
  }) async {}

  @override
  Future<void> cancelarPreregistro(String correo) async {}

  @override
  Future<void> cambiarActivo({
    required String uid,
    required bool activo,
  }) async {}
}

Registro registro(
  String aula,
  int hora,
  EstadoCaptura estado,
  int minuto, {
  String suplente = '',
  String observacion = '',
  int? llegada,
  int desfaseMin = 0,
  bool sinConexion = false,
  bool pendiente = false,
  int version = 1,
}) {
  final clase = clasesDelBloque(
    clasesDemo,
    4,
    hora,
  ).firstWhere((c) => c.aulaId == aula);
  final captura = inicioDelBloqueUtc(
    fecha,
    hora,
  ).add(Duration(minutes: minuto));
  return Registro(
    id: idRegistro(aula, fecha, hora),
    periodoId: '2026-2',
    claseId: clase.id,
    aulaId: aula,
    fecha: fecha,
    hora: hora,
    turno: (Turno.deBloque(hora) ?? Turno.matutino).codigo,
    docenteId: clase.docenteId,
    docenteNombre: clase.docenteNombre,
    materia: clase.materia,
    grupo: clase.grupo,
    estado: estado,
    suplenteNombre: suplente,
    observacion: observacion,
    horaDispositivo: captura,
    horaServidor: sinConexion
        ? captura.add(const Duration(minutes: 40))
        : captura,
    llegadaDispositivo: llegada == null
        ? null
        : inicioDelBloqueUtc(fecha, hora).add(Duration(minutes: llegada)),
    desfaseRelojMs: desfaseMin * 60000,
    capturadoSinConexion: sinConexion,
    origen: 'APP',
    registradoPor: 'enc',
    version: version,
    actualizadoPor: 'enc',
    justificacion: JustificacionEstado.ninguna,
    pendienteDeEnvio: pendiente,
  );
}

EntradaBitacora entrada(
  String id,
  int v,
  String accion,
  Map<String, Object?> antes,
  Map<String, Object?> despues,
  Usuario u,
  int minutoHora8, {
  String motivo = '',
}) => EntradaBitacora(
  registroId: id,
  version: v,
  accion: accion,
  antes: antes,
  despues: despues,
  motivo: motivo,
  usuarioUid: u.uid,
  usuarioNombre: u.nombre,
  usuarioRol: u.rol.codigo,
  horaServidor: inicioDelBloqueUtc(
    fecha,
    8,
  ).add(Duration(minutes: minutoHora8)),
);

RegistrosFalsos datosDelDia({bool sinConexion = false}) {
  final r = RegistrosFalsos()..simularSinConexion = sinConexion;
  // Bloques de las 7:00 y 8:00 (ya terminados).
  const estados7 = [
    EstadoCaptura.presente,
    EstadoCaptura.presente,
    EstadoCaptura.retardo,
    EstadoCaptura.presente,
    EstadoCaptura.sinDocente,
    EstadoCaptura.presente,
    EstadoCaptura.sinAlumnos,
    EstadoCaptura.presente,
    EstadoCaptura.presente,
    EstadoCaptura.presente,
  ];
  for (var i = 0; i < 10; i++) {
    final aula = 'A${101 + i}';
    r.sembrar(registro(aula, 7, estados7[i], 3 + i * 2, sinConexion: i == 3));
    r.sembrar(
      registro(
        aula,
        8,
        i == 4 ? EstadoCaptura.sinDocente : EstadoCaptura.presente,
        2 + i * 2,
        desfaseMin: i == 6 ? 8 : 0,
        version: i == 4 ? 2 : 1,
      ),
    );
  }
  // El A105 de las 8:00 fue corregido por Coordinación.
  r.sembrar(
    registro(
      'A105',
      8,
      EstadoCaptura.suplente,
      10,
      suplente: 'Pedro Gómez Ríos',
      version: 2,
    ),
  );
  final id = idRegistro('A105', fecha, 8);
  r.bitacoraEscrita
    ..add(
      entrada(
        id,
        1,
        'CREAR',
        const {},
        const {'estadoCaptura': 'SIN_DOCENTE'},
        encargado,
        10,
      ),
    )
    ..add(
      entrada(
        id,
        2,
        'CORREGIR',
        const {'estadoCaptura': 'SIN_DOCENTE'},
        const {
          'estadoCaptura': 'SUPLENTE',
          'suplenteNombre': 'Pedro Gómez Ríos',
        },
        coordinacion,
        48,
        motivo: 'La suplencia estaba autorizada por la jefatura de carrera',
      ),
    );
  // Bloque actual (9:00), recorrido en curso.
  r
    ..sembrar(
      registro(
        'A101',
        9,
        EstadoCaptura.presente,
        3,
        pendiente: sinConexion,
        sinConexion: sinConexion,
      ),
    )
    ..sembrar(
      registro(
        'A102',
        9,
        EstadoCaptura.suplente,
        5,
        suplente: 'Pedro Gómez Ríos',
        pendiente: sinConexion,
        sinConexion: sinConexion,
      ),
    )
    ..sembrar(
      registro('A103', 9, EstadoCaptura.aunNoLlega, 6, llegada: 19, version: 2),
    )
    ..sembrar(
      registro(
        'A104',
        9,
        EstadoCaptura.sinDocente,
        8,
        observacion: 'Aula cerrada',
      ),
    )
    ..sembrar(registro('A105', 9, EstadoCaptura.sinAlumnos, 10))
    ..sembrar(registro('A106', 9, EstadoCaptura.aunNoLlega, 12));
  return r;
}

Widget conDatos(
  Widget app, {
  required EstadoSesion sesion,
  RegistrosFalsos? registros,
}) {
  return ProviderScope(
    overrides: [
      autenticacionRepositorioProvider.overrideWithValue(
        AutenticacionFalsa(inicial: sesion),
      ),
      horarioRepositorioProvider.overrideWithValue(HorarioFalso(clasesDemo)),
      registroRepositorioProvider.overrideWithValue(registros ?? datosDelDia()),
      usuarioRepositorioProvider.overrideWithValue(UsuariosFalsos()),
      relojProvider.overrideWithValue(RelojFijo(ahora)),
    ],
    child: app,
  );
}

final _marco = GlobalKey();

Future<void> mostrar(
  WidgetTester tester,
  Widget app, {
  required bool movil,
}) async {
  tester.view.physicalSize = movil
      ? const Size(412, 892)
      : const Size(1280, 860);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(RepaintBoundary(key: _marco, child: app));
  await tester.pumpAndSettle();
}

Future<void> capturar(WidgetTester tester, String nombre) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final limite =
        _marco.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await limite.toImage(pixelRatio: 2);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    await File('$salida/$nombre.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void caso(String descripcion, Future<void> Function(WidgetTester) cuerpo) {
  testWidgets(descripcion, (tester) async {
    debugDisableShadows = false;
    addTearDown(tester.view.reset);
    try {
      await cuerpo(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  setUpAll(() async {
    await cargarFuentes();
    Directory(salida).createSync(recursive: true);
    final bytes = File('../docs/demo/horario_demo.csv').readAsBytesSync();
    clasesDemo = [
      for (final (i, c) in validarHorario(
        leerFilas(bytes, 'horario_demo.csv'),
      ).clases.indexed)
        Clase(
          id: 'c$i',
          aulaId: c.aulaId,
          docenteId: c.docenteId,
          docenteNombre: c.docenteNombre,
          materia: c.materia,
          grupo: c.grupo,
          diaSemana: c.diaSemana,
          horaInicio: c.horaInicio,
          horaFin: c.horaFin,
        ),
    ];
  });

  // ---------- App del encargado ----------

  caso('01 entrar', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const SinSesion()),
      movil: true,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'encargado@demo.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'Encargado2026',
    );
    await capturar(tester, '01_entrar');
  });

  caso('02 primer acceso', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const SinSesion()),
      movil: true,
    );
    await tester.tap(find.text('¿Primera vez? Crear mi contraseña'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'nuevo.encargado@demo.edu.mx',
    );
    await capturar(tester, '02_primer_acceso');
  });

  caso('03 confirmar correo', (tester) async {
    await mostrar(
      tester,
      conDatos(
        const AppMovil(),
        sesion: const PendienteVerificacion('nuevo.encargado@demo.edu.mx'),
      ),
      movil: true,
    );
    await capturar(tester, '03_confirmar_correo');
  });

  caso('04 recorrido pendientes', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const ConPerfil(encargado)),
      movil: true,
    );
    await capturar(tester, '04_recorrido_pendientes');
  });

  caso('05 recorrido todas', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const ConPerfil(encargado)),
      movil: true,
    );
    await tester.tap(find.text('Todas'));
    await capturar(tester, '05_recorrido_todas');
  });

  caso('06 panel de registro', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const ConPerfil(encargado)),
      movil: true,
    );
    await tester.tap(find.text('A107'));
    await capturar(tester, '06_panel_registro');
  });

  caso('07 suplente', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const ConPerfil(encargado)),
      movil: true,
    );
    await tester.tap(find.text('A108'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suplente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar suplente'));
    await capturar(tester, '07_suplente_sin_nombre');
  });

  caso('08 llegada', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const ConPerfil(encargado)),
      movil: true,
    );
    await tester.tap(find.text('A106'));
    await capturar(tester, '08_aun_no_llega');
  });

  caso('09 sin conexion', (tester) async {
    await mostrar(
      tester,
      conDatos(
        const AppMovil(),
        sesion: const ConPerfil(encargado),
        registros: datosDelDia(sinConexion: true),
      ),
      movil: true,
    );
    await tester.tap(find.text('Todas'));
    await capturar(tester, '09_sin_conexion');
  });

  caso('10 acceso no disponible', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppMovil(), sesion: const ConPerfil(coordinacion)),
      movil: true,
    );
    await capturar(tester, '10_acceso_no_disponible');
  });

  // ---------- Web de Coordinación ----------

  caso('11 hoy', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppWeb(), sesion: const ConPerfil(coordinacion)),
      movil: false,
    );
    await capturar(tester, '11_coordinacion_hoy');
  });

  caso('12 registros', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppWeb(), sesion: const ConPerfil(coordinacion)),
      movil: false,
    );
    await tester.tap(find.widgetWithText(Tab, 'Registros'));
    await capturar(tester, '12_coordinacion_registros');
  });

  caso('13 detalle y bitacora', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppWeb(), sesion: const ConPerfil(coordinacion)),
      movil: false,
    );
    await tester.tap(find.widgetWithText(Tab, 'Registros'));
    await tester.pumpAndSettle();
    final chip = find.textContaining('Suplente: Pedro').first;
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    final motivo = find.widgetWithText(TextField, 'Motivo (obligatorio)');
    expect(motivo, findsOneWidget);
    await capturar(tester, '13_detalle_bitacora');
  });

  caso('14 reportes', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppWeb(), sesion: const ConPerfil(coordinacion)),
      movil: false,
    );
    await tester.tap(find.widgetWithText(Tab, 'Reportes'));
    await capturar(tester, '14_coordinacion_reportes');
  });

  Widget horario(ResultadoImportacion resultado, String archivo) => conDatos(
    MaterialApp(
      theme: temaApp(),
      debugShowCheckedModeBanner: false,
      locale: idiomaApp,
      supportedLocales: idiomasSoportados,
      localizationsDelegates: delegadosLocalizacion,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Asistencia docente · Coordinación · Horario'),
        ),
        body: HorarioPantalla(
          resultadoInicial: resultado,
          archivoInicial: archivo,
        ),
      ),
    ),
    sesion: const ConPerfil(coordinacion),
  );

  caso('15 horario con errores', (tester) async {
    final bytes = File(
      '../docs/demo/horario_con_errores.csv',
    ).readAsBytesSync();
    final r = validarHorario(leerFilas(bytes, 'horario_con_errores.csv'));
    await mostrar(tester, horario(r, 'horario_con_errores.csv'), movil: false);
    await capturar(tester, '15_horario_errores');
  });

  caso('16 horario listo', (tester) async {
    final bytes = File('../docs/demo/horario_demo.csv').readAsBytesSync();
    final r = validarHorario(leerFilas(bytes, 'horario_demo.csv'));
    await mostrar(tester, horario(r, 'horario_demo.csv'), movil: false);
    await capturar(tester, '16_horario_listo');
  });

  caso('17 usuarios', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppWeb(), sesion: const ConPerfil(coordinacion)),
      movil: false,
    );
    await tester.tap(find.widgetWithText(Tab, 'Usuarios'));
    await capturar(tester, '17_coordinacion_usuarios');
  });

  caso('18 entrar web', (tester) async {
    await mostrar(
      tester,
      conDatos(const AppWeb(), sesion: const SinSesion()),
      movil: false,
    );
    await capturar(tester, '18_entrar_web');
  });
}
