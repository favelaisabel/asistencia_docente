import 'package:flutter/material.dart';

import 'tema.dart';

/// Aplicación web de Coordinación (y docentes en v1.1). En I1 se agrega el
/// inicio de sesión y la navegación por rol.
class AppWeb extends StatelessWidget {
  const AppWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia docente · Coordinación',
      theme: temaApp(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Asistencia docente · Coordinación')),
        body: const Center(child: Text('Web de Coordinación · entorno listo')),
      ),
    );
  }
}
