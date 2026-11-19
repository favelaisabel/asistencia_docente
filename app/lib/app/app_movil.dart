import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'localizacion.dart';
import 'router.dart';
import 'tema.dart';

/// App Android del encargado de recorridos.
class AppMovil extends ConsumerWidget {
  const AppMovil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Asistencia docente',
      theme: temaApp(),
      debugShowCheckedModeBanner: false,
      locale: idiomaApp,
      supportedLocales: idiomasSoportados,
      localizationsDelegates: delegadosLocalizacion,
      routerConfig: ref.watch(routerMovilProvider),
    );
  }
}
