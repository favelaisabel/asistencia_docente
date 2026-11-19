import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/sesion.dart';
import '../../autenticacion/aplicacion/providers.dart';
import '../../autenticacion/presentacion/componentes.dart';

/// Pantalla principal del encargado (M-02). El recorrido se construye en I3.
class RecorridoPantalla extends ConsumerWidget {
  const RecorridoPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion is ConPerfil ? sesion.usuario.nombre : '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorrido'),
        actions: const [BotonCerrarSesion()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Hola, $nombre.\nEl registro de asistencia estará disponible en el incremento I3.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
