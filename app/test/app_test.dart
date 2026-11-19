import 'package:asistencia_docente/app/app_movil.dart';
import 'package:asistencia_docente/app/app_web.dart';
import 'package:asistencia_docente/dominio/rol.dart';
import 'package:asistencia_docente/dominio/sesion.dart';
import 'package:asistencia_docente/dominio/usuario.dart';
import 'package:asistencia_docente/modulos/autenticacion/aplicacion/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/autenticacion_falsa.dart';

Widget conSesion(Widget app, AutenticacionFalsa repositorio) => ProviderScope(
  overrides: [autenticacionRepositorioProvider.overrideWithValue(repositorio)],
  child: app,
);

ConPerfil perfil(Rol rol) => ConPerfil(
  Usuario(
    uid: 'u1',
    correo: 'x@demo.edu.mx',
    nombre: 'Carlos Medina',
    rol: rol,
    activo: true,
  ),
);

void main() {
  testWidgets('sin sesión, ambas apps muestran Entrar', (tester) async {
    await tester.pumpWidget(conSesion(const AppMovil(), AutenticacionFalsa()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);

    await tester.pumpWidget(conSesion(const AppWeb(), AutenticacionFalsa()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('el encargado entra directo al recorrido en la app', (
    tester,
  ) async {
    final repo = AutenticacionFalsa(inicial: perfil(Rol.encargado));
    await tester.pumpWidget(conSesion(const AppMovil(), repo));
    await tester.pumpAndSettle();
    expect(find.text('Recorrido'), findsOneWidget);
    expect(find.textContaining('Hola, Carlos Medina'), findsOneWidget);
  });

  testWidgets('Coordinación no puede usar la app del encargado', (
    tester,
  ) async {
    final repo = AutenticacionFalsa(inicial: perfil(Rol.coordinacion));
    await tester.pumpWidget(conSesion(const AppMovil(), repo));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Coordinación usa la versión web'),
      findsOneWidget,
    );
  });

  testWidgets(
    'si Coordinación desactiva la cuenta, la app lo muestra al instante',
    (tester) async {
      final repo = AutenticacionFalsa(inicial: perfil(Rol.encargado));
      await tester.pumpWidget(conSesion(const AppMovil(), repo));
      await tester.pumpAndSettle();

      repo.emitir(const SesionDesactivada());
      await tester.pumpAndSettle();
      expect(
        find.text('Tu cuenta está desactivada. Consulta a Coordinación.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('cerrar sesión regresa a Entrar', (tester) async {
    final repo = AutenticacionFalsa(inicial: perfil(Rol.encargado));
    await tester.pumpWidget(conSesion(const AppMovil(), repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });
}
