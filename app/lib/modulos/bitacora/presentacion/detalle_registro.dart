import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/estilo_situacion.dart';
import '../../../app/mensajes.dart';
import '../../../dominio/registro.dart';
import '../../../dominio/repositorios/registro_repositorio.dart';
import '../../../dominio/tiempo.dart';
import '../../recorrido/aplicacion/providers.dart';
import '../../reportes/aplicacion/generador_reportes.dart';

String horaLocal(DateTime? instante) {
  if (instante == null) return '—';
  final m = MomentoNegocio.desdeUtc(instante);
  return '${m.fecha} ${m.hora.toString().padLeft(2, '0')}:${m.minuto.toString().padLeft(2, '0')}';
}

/// Cambio de la bitácora en lenguaje claro ("Situación: Sin docente").
String describirCambio(Map<String, Object?> cambio) {
  final partes = <String>[];
  for (final MapEntry(:key, :value) in cambio.entries) {
    final texto = '${value ?? ''}';
    switch (key) {
      case 'estadoCaptura':
        partes.add(
          'Situación: ${EstadoCaptura.desdeCodigo(texto)?.etiqueta ?? texto}',
        );
      case 'suplenteNombre':
        partes.add('Suplente: $texto');
      case 'observacion':
        partes.add('Observación: $texto');
      case 'llegadaDispositivo':
        final llegada = DateTime.tryParse(texto);
        partes.add(
          llegada == null
              ? 'Llegada: sin registrar'
              : 'Llegada: ${horaLocal(llegada)}',
        );
      default:
        partes.add('$key: $texto');
    }
  }
  return partes.join(' · ');
}

/// Detalle de un registro con su bitácora y corrección con motivo
/// (W-03; RF-031, RF-032).
Future<void> mostrarDetalleRegistro(BuildContext context, FilaReporte fila) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: _DetalleRegistro(fila),
      ),
    ),
  );
}

class _DetalleRegistro extends ConsumerStatefulWidget {
  const _DetalleRegistro(this.fila);

  final FilaReporte fila;

  @override
  ConsumerState<_DetalleRegistro> createState() => _DetalleRegistroState();
}

class _DetalleRegistroState extends ConsumerState<_DetalleRegistro> {
  late EstadoCaptura _estado = widget.fila.registro.estado;
  final _motivo = TextEditingController();
  final _suplente = TextEditingController();
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _motivo.dispose();
    _suplente.dispose();
    super.dispose();
  }

  Future<void> _corregir() async {
    if (_motivo.text.trim().length < 3) {
      setState(() => _error = 'Escribe el motivo de la corrección.');
      return;
    }
    if (_estado == EstadoCaptura.suplente && _suplente.text.trim().length < 3) {
      setState(() => _error = 'Escribe el nombre del suplente.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(accionesRecorridoProvider)
          .corregir(
            widget.fila.registro,
            Captura(
              estado: _estado,
              suplenteNombre: _estado == EstadoCaptura.suplente
                  ? _suplente.text
                  : '',
              observacion: widget.fila.registro.observacion,
            ),
            motivo: _motivo.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.fila.registro;
    final bitacora = ref.watch(bitacoraProvider(r.id));
    final estilo = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${r.aulaId} · ${r.fecha} · ${r.hora.toString().padLeft(2, '0')}:00',
                    style: estilo.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text('${r.docenteNombre} (${r.docenteId})'),
            Text('${r.materia} · Grupo ${r.grupo}', style: estilo.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EtiquetaSituacion(
                  texto: r.estado == EstadoCaptura.suplente
                      ? 'Suplente: ${r.suplenteNombre}'
                      : widget.fila.situacion.etiqueta,
                  estilo: EstiloSituacion.de(widget.fila.situacion),
                ),
                if (widget.fila.horaDudosa)
                  const Tooltip(
                    message:
                        'El reloj del celular difería más de 5 minutos del servidor',
                    child: Chip(label: Text('Hora dudosa')),
                  ),
                if (r.capturadoSinConexion)
                  const Chip(label: Text('Capturado sin conexión')),
              ],
            ),
            if (r.observacion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Observación: ${r.observacion}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Captura (celular): ${horaLocal(r.horaDispositivo)} · Servidor: ${horaLocal(r.horaServidor)}'
              '${r.llegadaDispositivo != null ? ' · Llegada: ${horaLocal(r.llegadaDispositivo)}' : ''}',
              style: estilo.bodySmall,
            ),
            const Divider(height: 32),
            Text('Bitácora', style: estilo.titleMedium),
            const SizedBox(height: 8),
            bitacora.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(mensajeDeError(e)),
              data: (entradas) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in entradas)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'v${e.version} · ${e.accion} · ${horaLocal(e.horaServidor)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (e.antes.isNotEmpty)
                            Text('Antes: ${describirCambio(e.antes)}'),
                          Text('Después: ${describirCambio(e.despues)}'),
                          if (e.motivo.isNotEmpty) Text('Motivo: ${e.motivo}'),
                          Text(
                            '${e.usuarioNombre} · ${e.usuarioRol}',
                            style: estilo.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 32),
            Text('Corregir', style: estilo.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<EstadoCaptura>(
              initialValue: _estado,
              decoration: const InputDecoration(labelText: 'Nueva situación'),
              items: [
                for (final e in EstadoCaptura.values.where(
                  (e) => e != EstadoCaptura.noProgramada,
                ))
                  DropdownMenuItem(value: e, child: Text(e.etiqueta)),
              ],
              onChanged: (e) => setState(() => _estado = e ?? _estado),
            ),
            if (_estado == EstadoCaptura.suplente)
              TextField(
                controller: _suplente,
                decoration: const InputDecoration(
                  labelText: 'Nombre del suplente',
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _motivo,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motivo (obligatorio)',
              ),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFA3221A)),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _guardando ? null : _corregir,
                child: const Text('Guardar corrección'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
