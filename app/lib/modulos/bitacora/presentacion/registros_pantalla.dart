import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/mensajes.dart';
import '../../../dominio/situacion.dart';
import '../../../dominio/tiempo.dart';
import '../../recorrido/aplicacion/providers.dart';
import '../../reportes/aplicacion/generador_reportes.dart';
import '../../reportes/aplicacion/providers.dart';
import 'tabla_registros.dart';

/// Pestaña Registros (W-03; RF-030): filtros combinables.
class RegistrosPantalla extends ConsumerStatefulWidget {
  const RegistrosPantalla({super.key});

  @override
  ConsumerState<RegistrosPantalla> createState() => _RegistrosPantallaState();
}

class _RegistrosPantallaState extends ConsumerState<RegistrosPantalla> {
  String? _fecha;
  String _turno = 'Todos';
  Situacion? _situacion;
  final _docente = TextEditingController();
  final _aula = TextEditingController();

  @override
  void dispose() {
    _docente.dispose();
    _aula.dispose();
    super.dispose();
  }

  List<FilaReporte> _filtrar(List<FilaReporte> filas) {
    final docente = _docente.text.trim().toLowerCase();
    final aula = _aula.text.trim().toUpperCase();
    return ordenar(
      filas.where((f) {
        final r = f.registro;
        if (_turno == 'Matutino' && r.turno != 'MAT') return false;
        if (_turno == 'Vespertino' && r.turno != 'VES') return false;
        if (_situacion != null && f.situacion != _situacion) return false;
        if (docente.isNotEmpty &&
            !r.docenteNombre.toLowerCase().contains(docente) &&
            !r.docenteId.toLowerCase().contains(docente)) {
          return false;
        }
        if (aula.isNotEmpty && !r.aulaId.contains(aula)) return false;
        return true;
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoy = MomentoNegocio.desdeUtc(ref.read(relojProvider).ahora()).fecha;
    final fecha = _fecha ?? hoy;
    final filas = ref.watch(filasDelDiaProvider(fecha));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Registros', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Fecha: $fecha'),
                  onPressed: () async {
                    final elegida = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(fecha),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                    );
                    if (elegida != null) {
                      setState(
                        () => _fecha = formatoFecha(
                          elegida.year,
                          elegida.month,
                          elegida.day,
                        ),
                      );
                    }
                  },
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: _turno,
                    decoration: const InputDecoration(labelText: 'Turno'),
                    items: [
                      for (final t in ['Todos', 'Matutino', 'Vespertino'])
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (t) => setState(() => _turno = t ?? 'Todos'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _docente,
                    decoration: const InputDecoration(
                      labelText: 'Docente o núm. de empleado',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _aula,
                    decoration: const InputDecoration(labelText: 'Aula'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<Situacion?>(
                    initialValue: _situacion,
                    decoration: const InputDecoration(labelText: 'Situación'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      for (final s in Situacion.values)
                        DropdownMenuItem(value: s, child: Text(s.etiqueta)),
                    ],
                    onChanged: (s) => setState(() => _situacion = s),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _turno = 'Todos';
                    _situacion = null;
                    _docente.clear();
                    _aula.clear();
                  }),
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        filas.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(mensajeDeError(e)),
          data: (lista) {
            final filtradas = _filtrar(lista);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${filtradas.length} de ${lista.length} registros · toca uno para ver su bitácora o corregirlo',
                ),
                const SizedBox(height: 8),
                Card(child: TablaRegistros(filas: filtradas)),
              ],
            );
          },
        ),
      ],
    );
  }
}
