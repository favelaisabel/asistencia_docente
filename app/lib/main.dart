import 'package:flutter/foundation.dart' show kIsWeb;

import 'main_movil.dart' as movil;
import 'main_web.dart' as web;

/// Punto de entrada por defecto (`flutter run`).
///
/// Elige la aplicación según la plataforma. Para compilar explícitamente usa
/// `-t lib/main_movil.dart` (Android, encargado) o `-t lib/main_web.dart`
/// (web, Coordinación y docentes). Ver ADR-001.
Future<void> main() => kIsWeb ? web.main() : movil.main();
