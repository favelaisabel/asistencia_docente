import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'localizacion.dart';
import 'router.dart';
import 'tema.dart';

/// Aplicación web de Coordinación (y docentes en v1.1).
class AppWeb extends ConsumerWidget {
  const AppWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Asistencia docente · Coordinación',
      theme: temaApp(),
      debugShowCheckedModeBanner: false,
      locale: idiomaApp,
      supportedLocales: idiomasSoportados,
      localizationsDelegates: delegadosLocalizacion,
      routerConfig: ref.watch(routerWebProvider),
    );
  }
}
