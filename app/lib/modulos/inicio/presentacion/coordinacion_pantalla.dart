import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/sesion.dart';
import '../../autenticacion/aplicacion/providers.dart';
import '../../autenticacion/presentacion/componentes.dart';
import '../../usuarios/presentacion/usuarios_pantalla.dart';

/// Panel web de Coordinación (W-02 a W-06). Las pestañas se completan en
/// los incrementos indicados.
class CoordinacionPantalla extends ConsumerWidget {
  const CoordinacionPantalla({super.key});

  static const _pestanas = <(String, String?)>[
    ('Hoy', 'I5'),
    ('Registros', 'I5'),
    ('Reportes', 'I6'),
    ('Horario', 'I2'),
    ('Usuarios', null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion is ConPerfil ? sesion.usuario.nombre : '';
    return DefaultTabController(
      length: _pestanas.length,
      initialIndex: _pestanas.length - 1,
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
          children: [
            for (final (titulo, incremento) in _pestanas)
              if (incremento == null)
                const UsuariosPantalla()
              else
                Center(
                  child: Text(
                    '$titulo: disponible en el incremento $incremento.',
                  ),
                ),
          ],
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
