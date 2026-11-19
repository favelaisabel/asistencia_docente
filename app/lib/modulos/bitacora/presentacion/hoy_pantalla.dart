import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/mensajes.dart';
import '../../../dominio/horario.dart';
import '../../../dominio/situacion.dart';
import '../../../dominio/tiempo.dart';
import '../../horario/aplicacion/providers.dart';
import '../../recorrido/aplicacion/providers.dart';
import '../../reportes/aplicacion/providers.dart';
import 'tabla_registros.dart';

/// Pestaña Hoy (W-02): resumen del día en vivo.
class HoyPantalla extends ConsumerWidget {
  const HoyPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ahora =
        ref.watch(ahoraProvider).value ?? ref.read(relojProvider).ahora();
    final momento = MomentoNegocio.desdeUtc(ahora);
    final filas = ref.watch(filasDelDiaProvider(momento.fecha));
    final clases =
        ref.watch(clasesDelDiaProvider(momento.diaSemana)).value ?? const [];
    final esperados = clases.fold<int>(
      0,
      (suma, c) => suma + c.bloques.where((h) => h <= momento.hora).length,
    );

    return filas.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(mensajeDeError(e))),
      data: (lista) {
        int contar(Situacion s) => lista.where((f) => f.situacion == s).length;
        final recientes = [...lista]
          ..sort(
            (a, b) => b.registro.horaDispositivo.compareTo(
              a.registro.horaDispositivo,
            ),
          );
        final indicadores = [
          (
            'Registros',
            '${lista.length}',
            'de $esperados previstos hasta ahora',
            const Color(0xFF1B1F24),
          ),
          (
            'Faltas',
            '${contar(Situacion.falta)}',
            'incluye "no llegó"',
            const Color(0xFFA3221A),
          ),
          (
            'Retardos',
            '${contar(Situacion.retardo)}',
            'llegada a los 16–30 min',
            const Color(0xFF8A4B00),
          ),
          (
            'Suplencias',
            '${contar(Situacion.suplencia)}',
            'con nombre registrado',
            const Color(0xFF1F4FBF),
          ),
          (
            'Horas dudosas',
            '${lista.where((f) => f.horaDudosa).length}',
            'reloj del celular desfasado',
            const Color(0xFF8A4B00),
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hoy · ${nombresDias[momento.diaSemana]} ${momento.fecha}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (titulo, valor, nota, color) in indicadores)
                  SizedBox(
                    width: 200,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titulo),
                            Text(
                              valor,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            Text(
                              nota,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Últimos registros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(child: TablaRegistros(filas: recientes.take(30).toList())),
          ],
        );
      },
    );
  }
}
