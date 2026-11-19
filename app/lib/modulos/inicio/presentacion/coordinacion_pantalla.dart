import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/sesion.dart';
import '../../autenticacion/aplicacion/providers.dart';
import '../../autenticacion/presentacion/componentes.dart';
import '../../bitacora/presentacion/hoy_pantalla.dart';
import '../../bitacora/presentacion/registros_pantalla.dart';
import '../../horario/presentacion/horario_pantalla.dart';
import '../../reportes/presentacion/reportes_pantalla.dart';
import '../../usuarios/presentacion/usuarios_pantalla.dart';

/// Panel web de Coordinación (W-02 a W-06).
class CoordinacionPantalla extends ConsumerWidget {
  const CoordinacionPantalla({super.key});

  static const _pestanas = <(String, Widget)>[
    ('Hoy', HoyPantalla()),
    ('Registros', RegistrosPantalla()),
    ('Reportes', ReportesPantalla()),
    ('Horario', HorarioPantalla()),
    ('Usuarios', UsuariosPantalla()),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion is ConPerfil ? sesion.usuario.nombre : '';
    return DefaultTabController(
      length: _pestanas.length,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Asistencia docente'),
              Text(
                'Coordinación · $nombre',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: const [BotonCerrarSesion(), SizedBox(width: 8)],
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final (titulo, _) in _pestanas) Tab(text: titulo)],
          ),
        ),
        body: TabBarView(
          children: [for (final (_, pantalla) in _pestanas) pantalla],
        ),
      ),
    );
  }
}

/// Portal docente (v1.1, EP7).
class DocentePantalla extends StatelessWidget {
  const DocentePantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia docente'),
        actions: const [BotonCerrarSesion()],
      ),
      body: const Center(
        child: Text('El portal docente estará disponible en la versión 1.1.'),
      ),
    );
  }
}
