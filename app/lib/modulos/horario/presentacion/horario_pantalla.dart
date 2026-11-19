import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/mensajes.dart';
import '../../../core/archivos.dart';
import '../../../dominio/horario.dart';
import '../../../dominio/tiempo.dart';
import '../../bitacora/presentacion/detalle_registro.dart';
import '../aplicacion/lector_archivo.dart';
import '../aplicacion/providers.dart';

/// Pestaña Horario (W-05; RF-006, RF-010, RF-011; flujo F6).
class HorarioPantalla extends ConsumerStatefulWidget {
  const HorarioPantalla({
    super.key,
    this.resultadoInicial,
    this.archivoInicial,
  });

  /// Solo para pruebas y capturas del manual: muestra un resultado de
  /// validación sin abrir el selector de archivos.
  @visibleForTesting
  final ResultadoImportacion? resultadoInicial;

  @visibleForTesting
  final String? archivoInicial;

  @override
  ConsumerState<HorarioPantalla> createState() => _HorarioPantallaState();
}

class _HorarioPantallaState extends ConsumerState<HorarioPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _periodo = TextEditingController(text: '2026-2');
  final _inicio = TextEditingController(text: '2026-08-10');
  final _fin = TextEditingController(text: '2026-12-11');
  late String? _archivo = widget.archivoInicial;
  late ResultadoImportacion? _resultado = widget.resultadoInicial;
  String? _error;
  double? _progreso;
  bool _activado = false;

  @override
  void dispose() {
    _periodo.dispose();
    _inicio.dispose();
    _fin.dispose();
    super.dispose();
  }

  Future<void> _seleccionar() async {
    setState(() {
      _error = null;
      _resultado = null;
      _activado = false;
    });
    final archivos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    if (archivos.isEmpty) return;
    final archivo = archivos.first;
    try {
      final filas = leerFilas(await archivo.readAsBytes(), archivo.name);
      setState(() {
        _archivo = archivo.name;
        _resultado = validarHorario(filas);
      });
    } on ArchivoNoValido catch (e) {
      setState(() => _error = e.mensaje);
    }
  }

  Future<void> _activar() async {
    final resultado = _resultado;
    if (resultado == null || !resultado.esValido) return;
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _progreso = 0;
      _error = null;
    });
    try {
      await ref
          .read(horarioRepositorioProvider)
          .importar(
            clases: resultado.clases,
            periodoNombre: _periodo.text,
            fechaInicio: _inicio.text.trim(),
            fechaFin: _fin.text.trim(),
            archivoNombre: _archivo ?? 'horario',
            progreso: (p) => mounted ? setState(() => _progreso = p) : null,
          );
      if (mounted) {
        setState(() {
          _activado = true;
          _resultado = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              '${mensajeDeError(e)} El horario anterior sigue vigente.',
        );
      }
    } finally {
      if (mounted) setState(() => _progreso = null);
    }
  }

  String? _validarFecha(String? v) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v?.trim() ?? '')
      ? null
      : 'Usa AAAA-MM-DD.';

  @override
  Widget build(BuildContext context) {
    final vigente = ref.watch(horarioVigenteProvider);
    final estilo = Theme.of(context).textTheme;
    final resultado = _resultado;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Horario', style: estilo.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: vigente.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(mensajeDeError(e)),
              data: (v) => v == null
                  ? const Text(
                      'Aún no hay horario activo. Sube el archivo del sistema escolar.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Periodo activo: ${v.periodoNombre} (${v.fechaInicio} a ${v.fechaFin})',
                          style: estilo.titleMedium,
                        ),
                        Text(
                          'Horario vigente: ${v.archivoNombre} · ${v.totalClases} clases · importado ${horaLocal(v.importadoEn)}',
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importar nuevo horario', style: estilo.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Columnas: ${columnasPlantilla.join(', ')}.',
                    style: estilo.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _periodo,
                          decoration: const InputDecoration(
                            labelText: 'Periodo',
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Escribe el periodo.'
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _inicio,
                          decoration: const InputDecoration(
                            labelText: 'Inicio (AAAA-MM-DD)',
                          ),
                          validator: _validarFecha,
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _fin,
                          decoration: const InputDecoration(
                            labelText: 'Fin (AAAA-MM-DD)',
                          ),
                          validator: (v) {
                            final formato = _validarFecha(v);
                            if (formato != null) return formato;
                            return (v ?? '').trim().compareTo(
                                      _inicio.text.trim(),
                                    ) <=
                                    0
                                ? 'Debe ser posterior al inicio.'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Descargar plantilla'),
                        onPressed: () => descargarArchivo(
                          'plantilla_horario',
                          plantillaCsv(),
                          TipoArchivo.csv,
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Subir archivo (.xlsx o .csv)'),
                        onPressed: _progreso != null ? null : _seleccionar,
                      ),
                    ],
                  ),
                  if (_progreso != null) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _progreso),
                    const Text('Cargando horario…'),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFA3221A)),
                    ),
                  ],
                  if (_activado) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: const Text(
                        'Horario activado. El horario anterior quedó archivado.',
                        style: TextStyle(
                          color: Color(0xFF12663D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (resultado != null && !resultado.esValido) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFFBE4E2),
                      child: Text(
                        'No se guardó nada. Corrige el archivo y vuelve a subirlo. (${resultado.errores.length} errores en $_archivo)',
                        style: const TextStyle(
                          color: Color(0xFFA3221A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Fila')),
                          DataColumn(label: Text('Columna')),
                          DataColumn(label: Text('Problema')),
                        ],
                        rows: [
                          for (final e in resultado.errores.take(200))
                            DataRow(
                              cells: [
                                DataCell(Text('${e.fila}')),
                                DataCell(Text(e.columna)),
                                DataCell(Text(e.problema)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (resultado != null && resultado.esValido) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFE4ECFB),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${resultado.clases.length} clases listas · ${resultado.aulas.length} aulas · '
                              '${resultado.docentes.length} docentes · sin errores',
                              style: const TextStyle(
                                color: Color(0xFF1F4FBF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _progreso != null ? null : _activar,
                            child: const Text('Activar horario'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Días: ${nombresDias.sublist(1, 7).join(', ')} · Turnos 7:00–14:00 y 14:00–21:00 · Hoy: ${MomentoNegocio.desdeUtc(DateTime.now().toUtc()).fecha}',
          style: estilo.bodySmall,
        ),
      ],
    );
  }
}
