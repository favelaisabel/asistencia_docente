import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/rol.dart';
import '../../../dominio/sesion.dart';
import '../aplicacion/destino.dart';
import '../aplicacion/providers.dart';
import 'componentes.dart';

/// Cuenta desactivada o rol que no corresponde a esta plataforma.
class NoDisponiblePantalla extends ConsumerWidget {
  const NoDisponiblePantalla({super.key, required this.plataforma});

  final Plataforma plataforma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final mensaje = switch (sesion) {
      SesionDesactivada() =>
        'Tu cuenta está desactivada. Consulta a Coordinación.',
      ConPerfil(:final usuario) when usuario.rol == Rol.encargado =>
        'Tu cuenta es de encargado de recorridos: usa la app Android.',
      ConPerfil() when plataforma == Plataforma.movil =>
        'Esta app es para el encargado de recorridos. Coordinación usa la versión web.',
      _ => 'Esta cuenta no tiene acceso a esta aplicación.',
    };
    return MarcoAcceso(
      titulo: 'Acceso no disponible',
      hijos: [
        Semantics(liveRegion: true, child: Text(mensaje)),
        const SizedBox(height: 24),
        const BotonCerrarSesion(),
      ],
    );
  }
}
