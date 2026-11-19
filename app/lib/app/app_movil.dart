import 'package:flutter/material.dart';

import 'tema.dart';

/// App Android del encargado. En I1 se reemplaza la pantalla inicial por el
/// inicio de sesión y la navegación por rol.
class AppMovil extends StatelessWidget {
  const AppMovil({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia docente',
      theme: temaApp(),
      debugShowCheckedModeBanner: false,
      home: const _PantallaEntornoListo(plataforma: 'App del encargado'),
    );
  }
}

class _PantallaEntornoListo extends StatelessWidget {
  const _PantallaEntornoListo({required this.plataforma});

  final String plataforma;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia docente')),
      body: Center(child: Text('$plataforma · entorno listo')),
    );
  }
}
