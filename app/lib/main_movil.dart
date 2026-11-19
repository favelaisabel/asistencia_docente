import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_movil.dart';
import 'app/firebase_config.dart';

/// Entrada de la app Android del encargado de recorridos (ADR-001).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await inicializarFirebase();
  runApp(const ProviderScope(child: AppMovil()));
}
