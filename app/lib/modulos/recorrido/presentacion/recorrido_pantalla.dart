import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/estilo_situacion.dart';
import '../../../dominio/horario.dart';
import '../../../dominio/registro.dart';
import '../../../dominio/sesion.dart';
import '../../../dominio/situacion.dart';
import '../../../dominio/tiempo.dart';
import '../../../dominio/turno.dart';
import '../../autenticacion/aplicacion/providers.dart';
import '../../autenticacion/presentacion/componentes.dart';
import '../../horario/aplicacion/providers.dart';
import '../aplicacion/providers.dart';
import 'panel_registro.dart';

/// Recorrido del encargado (M-02; RF-013, RF-019, RF-021).
class RecorridoPantalla extends ConsumerStatefulWidget {
  const RecorridoPantalla({super.key});

  @override
  ConsumerState<RecorridoPantalla> createState() => _RecorridoPantallaState();
}

class _AulaDelBloque {
  _AulaDelBloque(this.clase, this.registro, this.situacion);

  final Clase clase;
  final Registro? registro;
  final Situacion? situacion;

  bool get pendiente => registro == null || situacion == Situacion.pendiente;
}

class _RecorridoPantallaState extends ConsumerState<RecorridoPantalla> {
  bool _soloPendientes = true;
  int _porEnviarAnterior = 0;

  @override
  Widget build(BuildContext context) {
    final reloj = ref.watch(relojProvider);
    final ahora = ref.watch(ahoraProvider).value ?? reloj.ahora();
    final momento = MomentoNegocio.desdeUtc(ahora);
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion is ConPerfil ? sesion.usuario.nombre : '';
    final turno = Turno.deBloque(momento.hora);
    ref.watch(desfaseRelojProvider);

    final vigente = ref.watch(horarioVigenteProvider);
    final clasesDia = ref.watch(clasesDelDiaProvider(momento.diaSemana));
    final registros = ref.watch(registrosDelDiaProvider(momento.fecha));
    final sinConexion =
        ref.watch(sinConexionProvider(momento.fecha)).value ?? false;

    final porId = {
      for (final r in registros.value ?? const <Registro>[]) r.id: r,
    };
    final porEnviar = porId.values.where((r) => r.pendienteDeEnvio).length;
    final enviados = (!sinConexion && _porEnviarAnterior > 0 && porEnviar == 0)
        ? _porEnviarAnterior
        : 0;
    _porEnviarAnterior = porEnviar;

    final aulas = [
      for (final clase in clasesDelBloque(
        clasesDia.value ?? const [],
        momento.diaSemana,
        momento.hora,
      ))
        () {
          final registro =
              porId[idRegistro(clase.aulaId, momento.fecha, momento.hora)];
          return _AulaDelBloque(
            clase,
            registro,
            registro == null ? null : situacionDe(registro, ahora),
          );
        }(),
    ];
    final hechas = aulas.where((a) => !a.pendiente).length;
    final visibles = _soloPendientes
        ? aulas.where((a) => a.pendiente).toList()
        : aulas;

    Widget cuerpo;
    if (vigente.isLoading || clasesDia.isLoading) {
      cuerpo = const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
      );
    } else if (vigente.value == null) {
      cuerpo = const _Vacio('Aún no hay horario activo. Avisa a Coordinación.');
    } else if (turno == null || momento.diaSemana == DateTime.sunday) {
      cuerpo = const _Vacio(
        'No hay clases en este momento. Los recorridos son de lunes a sábado, de 7:00 a 21:00.',
      );
    } else if (aulas.isEmpty) {
      cuerpo = const _Vacio('No hay clases programadas en este bloque.');
    } else if (visibles.isEmpty) {
      cuerpo = _Vacio(
        'Recorrido completo · $hechas de ${aulas.length} aulas registradas',
        exito: true,
      );
    } else {
      cuerpo = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: visibles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _TarjetaAula(
          aula: visibles[i],
          ahora: ahora,
          alTocar: () => mostrarPanelRegistro(
            context,
            clase: visibles[i].clase,
            registro: visibles[i].registro,
            fecha: momento.fecha,
            hora: momento.hora,
          ),
        ),
      );
    }

    final hora =
        '${momento.hora.toString().padLeft(2, '0')}:${momento.minuto.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorrido'),
        actions: const [BotonCerrarSesion()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${nombresDias[momento.diaSemana]} ${momento.fecha} · ${turno == Turno.vespertino ? 'Turno vespertino' : 'Turno matutino'} · $nombre',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        turno == null
                            ? 'Fuera de horario'
                            : 'Bloque ${momento.hora.toString().padLeft(2, '0')}:00–${momento.hora.toString().padLeft(2, '0')}:59',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Hora $hora',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _IndicadorConexion(
                  sinConexion: sinConexion,
                  porEnviar: porEnviar,
                ),
                if (enviados > 0) ...[
                  const SizedBox(height: 6),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '$enviados registros enviados',
                      style: const TextStyle(
                        color: Color(0xFF12663D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (aulas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$hechas de ${aulas.length} aulas',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${aulas.length - hechas} pendientes'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: hechas / aulas.length,
                      minHeight: 8,
                      semanticsLabel: 'Avance del recorrido',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Pendientes')),
                ButtonSegment(value: false, label: Text('Todas')),
              ],
              selected: {_soloPendientes},
              onSelectionChanged: (s) =>
                  setState(() => _soloPendientes = s.first),
            ),
          ),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}

class _IndicadorConexion extends StatelessWidget {
  const _IndicadorConexion({
    required this.sinConexion,
    required this.porEnviar,
  });

  final bool sinConexion;
  final int porEnviar;

  @override
  Widget build(BuildContext context) {
    final enLinea = !sinConexion && porEnviar == 0;
    final texto = sinConexion
        ? 'Sin conexión · $porEnviar por enviar'
        : porEnviar > 0
        ? 'Enviando · $porEnviar por enviar'
        : 'En línea · todo enviado';
    final color = enLinea ? const Color(0xFF12663D) : const Color(0xFF8A4B00);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enLinea ? const Color(0xFFE3F3EA) : const Color(0xFFFCEFD9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              enLinea ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAula extends StatelessWidget {
  const _TarjetaAula({
    required this.aula,
    required this.ahora,
    required this.alTocar,
  });

  final _AulaDelBloque aula;
  final DateTime ahora;
  final VoidCallback alTocar;

  String _etiqueta() {
    final r = aula.registro;
    final s = aula.situacion;
    if (r == null || s == null) return 'Pendiente';
    if (s == Situacion.suplencia) return 'Suplente: ${r.suplenteNombre}';
    if (s == Situacion.pendiente) {
      return 'Aún no llega · min ${r.minutoCaptura}';
    }
    if (r.estado == EstadoCaptura.aunNoLlega) {
      return r.minutoLlegada == null
          ? '${s.etiqueta} (no llegó)'
          : '${s.etiqueta} (llegó min ${r.minutoLlegada})';
    }
    return s.etiqueta;
  }

  @override
  Widget build(BuildContext context) {
    final clase = aula.clase;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE3E6EA)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    clase.aulaId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (aula.registro?.pendienteDeEnvio ?? false)
                    const Tooltip(
                      message: 'Guardado en el celular, por enviar',
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 18,
                        color: Color(0xFF8A4B00),
                      ),
                    ),
                  const SizedBox(width: 12),
                  // La etiqueta ocupa todo el espacio libre, alineada a la derecha.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: EtiquetaSituacion(
                        texto: _etiqueta(),
                        estilo: EstiloSituacion.de(aula.situacion),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                clase.docenteNombre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${clase.materia} · Grupo ${clase.grupo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio(this.mensaje, {this.exito = false});

  final String mensaje;
  final bool exito;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.check_circle_outline : Icons.info_outline,
              size: 40,
              color: exito ? const Color(0xFF12663D) : const Color(0xFF4A525C),
            ),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
