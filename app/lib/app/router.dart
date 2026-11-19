import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dominio/sesion.dart';
import '../modulos/autenticacion/aplicacion/destino.dart';
import '../modulos/autenticacion/aplicacion/providers.dart';
import '../modulos/autenticacion/presentacion/componentes.dart';
import '../modulos/autenticacion/presentacion/entrar_pantalla.dart';
import '../modulos/autenticacion/presentacion/no_disponible_pantalla.dart';
import '../modulos/autenticacion/presentacion/primer_acceso_pantalla.dart';
import '../modulos/inicio/presentacion/coordinacion_pantalla.dart';
import '../modulos/recorrido/presentacion/recorrido_pantalla.dart';

/// Navegación protegida por sesión y rol (05_ARQUITECTURA, ADR-006).
GoRouter _crearRouter(Ref ref, Plataforma plataforma) {
  final sesion = ValueNotifier<EstadoSesion?>(null);
  ref.listen(
    sesionProvider,
    (_, siguiente) => sesion.value = siguiente.value,
    fireImmediately: true,
  );
  ref.onDispose(sesion.dispose);

  final router = GoRouter(
    initialLocation: Rutas.cargando,
    refreshListenable: sesion,
    redirect: (context, estado) => redirigir(
      sesion: sesion.value,
      ubicacion: estado.matchedLocation,
      plataforma: plataforma,
    ),
    routes: [
      GoRoute(
        path: Rutas.cargando,
        builder: (_, _) => const CargandoPantalla(),
      ),
      GoRoute(path: Rutas.entrar, builder: (_, _) => const EntrarPantalla()),
      GoRoute(
        path: Rutas.primerAcceso,
        builder: (_, _) => const PrimerAccesoPantalla(),
      ),
      GoRoute(
        path: Rutas.noDisponible,
        builder: (_, _) => NoDisponiblePantalla(plataforma: plataforma),
      ),
      if (plataforma == Plataforma.movil)
        GoRoute(
          path: Rutas.recorrido,
          builder: (_, _) => const RecorridoPantalla(),
        ),
      if (plataforma == Plataforma.web) ...[
        GoRoute(
          path: Rutas.coordinacion,
          builder: (_, _) => const CoordinacionPantalla(),
        ),
        GoRoute(
          path: Rutas.docente,
          builder: (_, _) => const DocentePantalla(),
        ),
      ],
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

final routerMovilProvider = Provider<GoRouter>(
  (ref) => _crearRouter(ref, Plataforma.movil),
);

final routerWebProvider = Provider<GoRouter>(
  (ref) => _crearRouter(ref, Plataforma.web),
);
