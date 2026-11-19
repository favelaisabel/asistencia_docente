import 'package:asistencia_docente/app/app_movil.dart';
import 'package:asistencia_docente/core/reloj.dart';
import 'package:asistencia_docente/dominio/registro.dart';
import 'package:asistencia_docente/dominio/rol.dart';
import 'package:asistencia_docente/dominio/sesion.dart';
import 'package:asistencia_docente/dominio/usuario.dart';
import 'package:asistencia_docente/modulos/autenticacion/aplicacion/providers.dart';
import 'package:asistencia_docente/modulos/horario/aplicacion/providers.dart';
import 'package:asistencia_docente/modulos/recorrido/aplicacion/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/autenticacion_falsa.dart';
import '../../fakes/datos_falsos.dart';

/// Jueves 19 nov 2026, 09:05 en México (15:05 UTC).
final juevesNueveYCinco = DateTime.utc(2026, 11, 19, 15, 5);

Future<(RegistrosFalsos, RelojFijo)> abrir(
  WidgetTester tester, {
  DateTime? hora,
  bool conHorario = true,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final registros = RegistrosFalsos();
  final reloj = RelojFijo(hora ?? juevesNueveYCinco);
  final sesion = AutenticacionFalsa(
    inicial: const ConPerfil(
      Usuario(
        uid: 'enc',
        correo: 'e@demo.edu.mx',
        nombre: 'Carlos Medina',
        rol: Rol.encargado,
        activo: true,
      ),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(sesion),
        horarioRepositorioProvider.overrideWithValue(
          HorarioFalso(clasesDeEjemplo(), activo: conHorario),
        ),
        registroRepositorioProvider.overrideWithValue(registros),
        relojProvider.overrideWithValue(reloj),
      ],
      child: const AppMovil(),
    ),
  );
  await tester.pumpAndSettle();
  return (registros, reloj);
}

void main() {
  group('PW-02 recorrido del encargado', () {
    testWidgets(
      'muestra el bloque actual con las aulas pendientes y el docente precargado (RF-013)',
      (tester) async {
        await abrir(tester);
        expect(find.text('Bloque 09:00–09:59'), findsOneWidget);
        expect(find.text('0 de 3 aulas'), findsOneWidget);
        expect(find.text('Laura Pérez Soto'), findsOneWidget);
        expect(find.text('En línea · todo enviado'), findsOneWidget);
      },
    );

    testWidgets(
      'registrar Presente con un toque deja el aula a tiempo y con bitácora (RF-014)',
      (tester) async {
        final (registros, _) = await abrir(tester);
        await tester.tap(find.text('A101'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Presente'));
        await tester.pumpAndSettle();

        final r = registros.todos.single;
        expect(r.id, 'A101_20261119_09');
        expect(r.estado, EstadoCaptura.presente);
        expect(registros.bitacoraEscrita.single.accion, 'CREAR');
        expect(find.text('1 de 3 aulas'), findsOneWidget);

        await tester.tap(find.text('Todas'));
        await tester.pumpAndSettle();
        expect(find.text('A tiempo'), findsOneWidget);
      },
    );

    testWidgets('suplente exige nombre (RF-016, RN-007)', (tester) async {
      final (registros, _) = await abrir(tester);
      await tester.tap(find.text('A102'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suplente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar suplente'));
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe el nombre del suplente para guardar.'),
        findsOneWidget,
      );
      expect(registros.todos, isEmpty);
      // Regresión: el mensaje aparece una sola vez, sin texto técnico suelto.
      expect(find.text('suplente'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre del suplente'),
        'Pedro Gómez',
      );
      await tester.tap(find.text('Guardar suplente'));
      await tester.pumpAndSettle();
      expect(registros.todos.single.suplenteNombre, 'Pedro Gómez');
    });

    testWidgets('aún no llega y luego llega al minuto 20 = retardo (RN-003)', (
      tester,
    ) async {
      final (registros, reloj) = await abrir(tester);
      await tester.tap(find.text('A103'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aún no llega'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aún no llega · min 5'), findsOneWidget);

      reloj.instante = juevesNueveYCinco.add(const Duration(minutes: 15));
      await tester.tap(find.text('A103'));
      await tester.pumpAndSettle();
      expect(find.textContaining('quedará como Retardo'), findsOneWidget);
      await tester.tap(find.text('Ya llegó'));
      await tester.pumpAndSettle();

      expect(registros.todos.single.minutoLlegada, 20);
      expect(registros.bitacoraEscrita.map((e) => e.accion), [
        'CREAR',
        'LLEGADA',
      ]);
    });

    testWidgets('fuera de horario muestra el estado vacío', (tester) async {
      await abrir(tester, hora: DateTime.utc(2026, 11, 20, 4));
      expect(
        find.textContaining('No hay clases en este momento'),
        findsOneWidget,
      );
    });

    testWidgets('sin horario activo avisa a Coordinación', (tester) async {
      await abrir(tester, conHorario: false);
      expect(
        find.text('Aún no hay horario activo. Avisa a Coordinación.'),
        findsOneWidget,
      );
    });
  });
}
