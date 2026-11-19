import 'package:flutter/material.dart';

import '../../../app/estilo_situacion.dart';
import '../../../dominio/registro.dart';
import '../../reportes/aplicacion/generador_reportes.dart';
import 'detalle_registro.dart';

/// Tabla de registros reutilizada en Hoy y Registros.
class TablaRegistros extends StatelessWidget {
  const TablaRegistros({super.key, required this.filas});

  final List<FilaReporte> filas;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No hay registros con estos filtros.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Hora')),
          DataColumn(label: Text('Aula')),
          DataColumn(label: Text('Docente')),
          DataColumn(label: Text('Materia')),
          DataColumn(label: Text('Situación')),
          DataColumn(label: Text('Avisos')),
        ],
        rows: [
          for (final f in filas)
            DataRow(
              onSelectChanged: (_) => mostrarDetalleRegistro(context, f),
              cells: [
                DataCell(
                  Text('${f.registro.hora.toString().padLeft(2, '0')}:00'),
                ),
                DataCell(Text(f.registro.aulaId)),
                DataCell(Text(f.registro.docenteNombre)),
                DataCell(Text(f.registro.materia)),
                DataCell(
                  EtiquetaSituacion(
                    texto: f.registro.estado == EstadoCaptura.suplente
                        ? 'Suplente: ${f.registro.suplenteNombre}'
                        : f.situacion.etiqueta,
                    estilo: EstiloSituacion.de(f.situacion),
                  ),
                ),
                DataCell(
                  Text(
                    [
                      if (f.horaDudosa) 'Hora dudosa',
                      if (f.registro.capturadoSinConexion) 'Sin conexión',
                      if (f.registro.version > 1) 'Corregido',
                    ].join(' · '),
                    style: const TextStyle(color: Color(0xFF8A4B00)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
