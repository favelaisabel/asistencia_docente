import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_web.dart';
import 'app/firebase_config.dart';

/// Entrada de la aplicación web de Coordinación y docentes (ADR-001).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await inicializarFirebase();
  runApp(const ProviderScope(child: AppWeb()));
}
