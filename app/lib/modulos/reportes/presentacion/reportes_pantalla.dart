import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/mensajes.dart';
import '../../../core/archivos.dart';
import '../../../dominio/tiempo.dart';
import '../../recorrido/aplicacion/providers.dart';
import '../aplicacion/generador_reportes.dart';
import '../aplicacion/providers.dart';

/// Pestaña Reportes (W-04; RF-028, RF-029, RF-033).
class ReportesPantalla extends ConsumerStatefulWidget {
  const ReportesPantalla({super.key});

  @override
  ConsumerState<ReportesPantalla> createState() => _ReportesPantallaState();
}

class _ReportesPantallaState extends ConsumerState<ReportesPantalla> {
  bool _semanal = false;
  bool _excel = true;
  String? _fecha;
  bool _trabajando = false;
  String? _mensaje;
  String? _error;

  Future<void> _ejecutar(Future<String> Function() tarea) async {
    setState(() {
      _trabajando = true;
      _mensaje = null;
      _error = null;
    });
    final cronometro = Stopwatch()..start();
    try {
      final archivo = await tarea();
      final segundos = (cronometro.elapsedMilliseconds / 1000).toStringAsFixed(
        1,
      );
      if (mounted) {
        setState(
          () => _mensaje = 'Se descargó $archivo (generado en $segundos s).',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<String> _generar(String fecha) async {
    final dias = _semanal ? semanaDe(fecha) : [fecha];
    final registros = await ref
        .read(registroRepositorioProvider)
        .registrosEntre(dias.first, dias.last);
    final filas = filasDeReporte(registros, ref.read(relojProvider).ahora());
    final nombre = _semanal
        ? 'reporte_semanal_${dias.first}_al_${dias.last}'
        : 'reporte_diario_$fecha';
    final titulo = _semanal
        ? 'Reporte semanal de asistencia docente'
        : 'Reporte diario de asistencia docente';
    final subtitulo = _semanal
        ? 'Semana del ${dias.first} al ${dias.last}'
        : 'Fecha: $fecha';
    if (_excel) {
      await descargarArchivo(
        nombre,
        reporteExcel(filas: filas, conTotales: _semanal),
        TipoArchivo.excel,
      );
      return '$nombre.xlsx';
    }
    final pdf = await reportePdf(
      titulo: titulo,
      subtitulo: subtitulo,
      filas: filas,
      conTotales: _semanal,
    );
    await descargarArchivo(nombre, pdf, TipoArchivo.pdf);
    return '$nombre.pdf';
  }

  Future<String> _respaldar(String hoy) async {
    final tablas = await ref.read(respaldoProvider).exportar();
    final nombre = 'respaldo_asistencia_$hoy';
    await descargarArchivo(nombre, respaldoZip(tablas), TipoArchivo.zip);
    return '$nombre.zip';
  }

  @override
  Widget build(BuildContext context) {
    final hoy = MomentoNegocio.desdeUtc(ref.read(relojProvider).ahora()).fecha;
    final fecha = _fecha ?? hoy;
    final estilo = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Reportes', style: estilo.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tipo'),
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Diario')),
                    ButtonSegment(value: true, label: Text('Semanal')),
                  ],
                  selected: {_semanal},
                  onSelectionChanged: (s) => setState(() => _semanal = s.first),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _semanal
                        ? 'Semana que contiene el $fecha'
                        : 'Fecha: $fecha',
                  ),
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
                const SizedBox(height: 16),
                const Text('Formato'),
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('PDF')),
                    ButtonSegment(value: true, label: Text('Excel')),
                  ],
                  selected: {_excel},
                  onSelectionChanged: (s) => setState(() => _excel = s.first),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Generar reporte'),
                  onPressed: _trabajando
                      ? null
                      : () => _ejecutar(() => _generar(fecha)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Respaldo completo', style: estilo.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Descarga todos los datos (registros, bitácora, horario, catálogos y usuarios) en un .zip '
                  'con un archivo CSV por colección. Guárdalo cada semana en la unidad institucional (RF-033).',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text('Descargar respaldo'),
                  onPressed: _trabajando
                      ? null
                      : () => _ejecutar(() => _respaldar(hoy)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_trabajando) const LinearProgressIndicator(),
        if (_mensaje != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _mensaje!,
              style: const TextStyle(
                color: Color(0xFF12663D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Color(0xFFA3221A))),
      ],
    );
  }
}
