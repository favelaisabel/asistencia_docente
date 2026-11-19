import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../aplicacion/providers.dart';

/// Contenedor centrado y de ancho limitado para las pantallas de acceso.
class MarcoAcceso extends StatelessWidget {
  const MarcoAcceso({super.key, required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Asistencia docente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  ...hijos,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje de error anunciado a lectores de pantalla (07_UX_UI §8).
class AvisoError extends StatelessWidget {
  const AvisoError(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colores.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(mensaje, style: TextStyle(color: colores.onErrorContainer)),
      ),
    );
  }
}

class BotonCerrarSesion extends ConsumerWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () =>
          ref.read(autenticacionRepositorioProvider).cerrarSesion(),
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar sesión'),
    );
  }
}

class CargandoPantalla extends StatelessWidget {
  const CargandoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
      ),
    );
  }
}
