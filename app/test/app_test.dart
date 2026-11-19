import 'package:asistencia_docente/app/app_movil.dart';
import 'package:asistencia_docente/app/app_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prueba de humo de I0: ambas aplicaciones arrancan.
void main() {
  testWidgets('la app del encargado arranca', (tester) async {
    await tester.pumpWidget(const AppMovil());
    expect(find.text('App del encargado · entorno listo'), findsOneWidget);
  });

  testWidgets('la web de Coordinación arranca', (tester) async {
    await tester.pumpWidget(const AppWeb());
    expect(find.text('Web de Coordinación · entorno listo'), findsOneWidget);
  });
}
