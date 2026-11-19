import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración de Firebase según el entorno (08_SEGURIDAD_CONTINUIDAD §8).
///
/// Variables (se pasan con `--dart-define`, ver `.env.example`):
/// - `USAR_EMULADOR` (por defecto `true`): usa el Firebase Emulator Suite con
///   el proyecto de demostración `demo-asistencia-docente`, que no requiere
///   un proyecto real en la nube ni datos reales.
/// - `HOST_EMULADOR`: host del emulador. Por defecto `10.0.2.2` en Android
///   (el emulador de Android ve así a la PC) y `localhost` en web. Con un
///   celular físico, usa la IP local de la PC.
const bool usarEmulador = bool.fromEnvironment(
  'USAR_EMULADOR',
  defaultValue: true,
);
const String _hostEmulador = String.fromEnvironment('HOST_EMULADOR');

const String proyectoDemo = 'demo-asistencia-docente';

/// Opciones ficticias válidas solo contra el emulador.
/// Las del proyecto real se generan en la Etapa 18 con `flutterfire configure`.
const FirebaseOptions _opcionesDemo = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: kIsWeb
      ? '1:000000000000:web:0000000000000000'
      : '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: proyectoDemo,
);

String get hostEmulador {
  if (_hostEmulador.isNotEmpty) return _hostEmulador;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}

Future<void> inicializarFirebase() async {
  if (!usarEmulador) {
    throw UnsupportedError(
      'Aún no hay proyecto de producción configurado (Etapa 18). '
      'Ejecuta con --dart-define=USAR_EMULADOR=true.',
    );
  }
  await Firebase.initializeApp(options: _opcionesDemo);
  // Memoria local persistente también en web (ADR-003, RNF-001). Debe
  // configurarse antes de conectar con el emulador.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FirebaseAuth.instance.useAuthEmulator(hostEmulador, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(hostEmulador, 8080);
}
