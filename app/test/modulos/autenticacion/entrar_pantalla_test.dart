import 'package:asistencia_docente/app/app_movil.dart';
import 'package:asistencia_docente/dominio/fallas.dart';
import 'package:asistencia_docente/modulos/autenticacion/aplicacion/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/autenticacion_falsa.dart';

Future<AutenticacionFalsa> abrir(WidgetTester tester) async {
  final repo = AutenticacionFalsa();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [autenticacionRepositorioProvider.overrideWithValue(repo)],
      child: const AppMovil(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);
final botonEntrar = find.widgetWithText(FilledButton, 'Entrar');

void main() {
  group('PW-01 pantalla Entrar (RF-001)', () {
    testWidgets('sin datos muestra qué falta y no intenta entrar', (
      tester,
    ) async {
      final repo = await abrir(tester);
      await tester.tap(botonEntrar);
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu correo.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);
      expect(repo.intentosDeEntrada, 0);
    });

    testWidgets('correo con formato inválido', (tester) async {
      await abrir(tester);
      await tester.enterText(campo('Correo institucional'), 'carlos');
      await tester.tap(botonEntrar);
      await tester.pumpAndSettle();
      expect(find.text('Escribe un correo válido.'), findsOneWidget);
    });

    testWidgets('credenciales inválidas muestran un mensaje genérico', (
      tester,
    ) async {
      final repo = await abrir(tester)
        ..fallaAlEntrar = const CredencialesInvalidas();
      await tester.enterText(
        campo('Correo institucional'),
        'carlos@demo.edu.mx',
      );
      await tester.enterText(campo('Contraseña'), 'incorrecta123');
      await tester.tap(botonEntrar);
      await tester.pumpAndSettle();

      expect(repo.intentosDeEntrada, 1);
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    });

    testWidgets('sin conexión muestra el mensaje correspondiente', (
      tester,
    ) async {
      final repo = await abrir(tester)
        ..fallaAlEntrar = const SinConexion();
      await tester.enterText(
        campo('Correo institucional'),
        'carlos@demo.edu.mx',
      );
      await tester.enterText(campo('Contraseña'), 'asistencia2026');
      await tester.tap(botonEntrar);
      await tester.pumpAndSettle();

      expect(repo.intentosDeEntrada, 1);
      expect(
        find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('el enlace lleva a Primer acceso', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('¿Primera vez? Crear mi contraseña'));
      await tester.pumpAndSettle();
      expect(find.text('Primer acceso'), findsOneWidget);
    });
  });
}
