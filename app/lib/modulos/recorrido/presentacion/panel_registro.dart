import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/estilo_situacion.dart';
import '../../../dominio/horario.dart';
import '../../../dominio/registro.dart';
import '../../../dominio/repositorios/registro_repositorio.dart';
import '../../../dominio/situacion.dart';
import '../../../dominio/tiempo.dart';
import '../aplicacion/providers.dart';

/// Panel de registro de un aula (M-03, M-04, M-05).
Future<void> mostrarPanelRegistro(
  BuildContext context, {
  required Clase clase,
  required Registro? registro,
  required String fecha,
  required int hora,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PanelRegistro(
      clase: clase,
      registro: registro,
      fecha: fecha,
      hora: hora,
    ),
  );
}

enum _Modo { opciones, suplente, llegada }

class PanelRegistro extends ConsumerStatefulWidget {
  const PanelRegistro({
    super.key,
    required this.clase,
    required this.registro,
    required this.fecha,
    required this.hora,
  });

  final Clase clase;
  final Registro? registro;
  final String fecha;
  final int hora;

  @override
  ConsumerState<PanelRegistro> createState() => _PanelRegistroState();
}

class _PanelRegistroState extends ConsumerState<PanelRegistro> {
  late _Modo _modo;
  final _observacion = TextEditingController();
  final _suplente = TextEditingController();
  String? _error;

  static const _opciones = [
    (EstadoCaptura.presente, Situacion.aTiempo),
    (EstadoCaptura.aunNoLlega, Situacion.pendiente),
    (EstadoCaptura.retardo, Situacion.retardo),
    (EstadoCaptura.suplente, Situacion.suplencia),
    (EstadoCaptura.sinAlumnos, Situacion.sinAlumnos),
    (EstadoCaptura.sinDocente, Situacion.falta),
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.registro;
    final ahora = ref.read(relojProvider).ahora();
    final enEspera =
        r != null &&
        r.estado == EstadoCaptura.aunNoLlega &&
        r.llegadaDispositivo == null &&
        minutosDesdeInicioDelBloque(r.fecha, r.hora, ahora) <= minutosRetardo;
    _modo = enEspera ? _Modo.llegada : _Modo.opciones;
  }

  @override
  void dispose() {
    _observacion.dispose();
    _suplente.dispose();
    super.dispose();
  }

  Future<void> _guardar(EstadoCaptura estado, {String suplente = ''}) async {
    final captura = Captura(
      estado: estado,
      suplenteNombre: suplente,
      observacion: _observacion.text,
    );
    final acciones = ref.read(accionesRecorridoProvider);
    final registro = widget.registro;
    try {
      if (registro == null) {
        await acciones.registrar(
          clase: widget.clase,
          fecha: widget.fecha,
          hora: widget.hora,
          captura: captura,
        );
      } else {
        await acciones.corregir(registro, captura);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar. Inténtalo de nuevo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;
    // Se reconstruye con cada tic de `ahoraProvider`, pero toma la hora exacta
    // del reloj para que la previsión de retardo no quede desfasada.
    ref.watch(ahoraProvider);
    final ahora = ref.read(relojProvider).ahora();
    final minuto = minutosDesdeInicioDelBloque(
      widget.fecha,
      widget.hora,
      ahora,
    );
    final hora = MomentoNegocio.desdeUtc(ahora);
    final horaTexto =
        '${hora.hora.toString().padLeft(2, '0')}:${hora.minuto.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aula ${clase.aulaId}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              clase.docenteNombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              '${clase.materia} · Grupo ${clase.grupo} · Hora $horaTexto (automática)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...switch (_modo) {
              _Modo.opciones => _contenidoOpciones(),
              _Modo.suplente => _contenidoSuplente(),
              _Modo.llegada => _contenidoLlegada(minuto),
            },
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFA3221A))),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _contenidoOpciones() => [
    if (widget.registro != null) ...[
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEFD9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Corregir este registro. El cambio queda en la bitácora.',
          style: TextStyle(color: Color(0xFF8A4B00)),
        ),
      ),
      const SizedBox(height: 12),
    ],
    GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: [
        for (final (estado, situacion) in _opciones)
          _BotonSituacion(
            texto: estado.etiqueta,
            estilo: EstiloSituacion.de(situacion),
            alTocar: () {
              if (estado == EstadoCaptura.suplente) {
                setState(() {
                  _modo = _Modo.suplente;
                  _error = null;
                });
              } else {
                _guardar(estado);
              }
            },
          ),
      ],
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _observacion,
      maxLength: 250,
      decoration: const InputDecoration(
        labelText: 'Observación (opcional)',
        hintText: 'Ej. el grupo está en el laboratorio',
      ),
    ),
  ];

  List<Widget> _contenidoSuplente() => [
    TextField(
      controller: _suplente,
      autofocus: true,
      maxLength: 120,
      decoration: InputDecoration(
        labelText: 'Nombre del suplente',
        errorText: _error == null
            ? null
            : 'Escribe el nombre del suplente para guardar.',
      ),
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() {
              _modo = _Modo.opciones;
              _error = null;
            }),
            child: const Text('Volver'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                final nombre = _suplente.text.trim();
                if (nombre.length < 3) {
                  setState(() => _error = 'suplente');
                  return;
                }
                _guardar(EstadoCaptura.suplente, suplente: nombre);
              },
              child: const Text('Guardar suplente'),
            ),
          ),
        ),
      ],
    ),
  ];

  List<Widget> _contenidoLlegada(int minuto) {
    final registro = widget.registro;
    final prevision = minuto <= minutosATiempo
        ? Situacion.aTiempo
        : minuto <= minutosRetardo
        ? Situacion.retardo
        : Situacion.falta;
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Marcado "Aún no llega" en el minuto ${registro?.minutoCaptura ?? 0}. '
          'Ahora es el minuto $minuto: si registras la llegada quedará como ${prevision.etiqueta}.',
          style: const TextStyle(color: Color(0xFF5B3BB0)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 64,
        child: FilledButton(
          onPressed: registro == null
              ? null
              : () async {
                  await ref
                      .read(accionesRecorridoProvider)
                      .marcarLlegada(registro);
                  if (mounted) Navigator.pop(context);
                },
          child: const Text('Ya llegó', style: TextStyle(fontSize: 17)),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => setState(() => _modo = _Modo.opciones),
        child: const Text('Cambiar situación'),
      ),
    ];
  }
}

class _BotonSituacion extends StatelessWidget {
  const _BotonSituacion({
    required this.texto,
    required this.estilo,
    required this.alTocar,
  });

  final String texto;
  final EstiloSituacion estilo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: estilo.fondo,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: estilo.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(estilo.icono, color: estilo.texto, size: 20),
              const SizedBox(width: 6),
              // Se adapta a pantallas angostas y a letra grande (RNF-012).
              Flexible(
                child: Text(
                  texto,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: estilo.texto,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
