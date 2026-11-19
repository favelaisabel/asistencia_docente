import 'package:flutter/material.dart';

/// Colores base de 07_UX_UI §5.
abstract final class ColoresApp {
  static const fondo = Color(0xFFF5F6F8);
  static const texto = Color(0xFF1B1F24);
  static const acento = Color(0xFF1F4FBF);
}

ThemeData temaApp() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: ColoresApp.acento),
    scaffoldBackgroundColor: ColoresApp.fondo,
    useMaterial3: true,
  );
}
