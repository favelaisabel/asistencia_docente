import 'package:flutter/material.dart';

import '../dominio/situacion.dart';

/// Colores e iconos por situación (07_UX_UI §5): siempre icono + texto + color,
/// con contraste ≥ 4.5:1 (RNF-013).
class EstiloSituacion {
  const EstiloSituacion(this.texto, this.fondo, this.borde, this.icono);

  final Color texto;
  final Color fondo;
  final Color borde;
  final IconData icono;

  static const pendiente = EstiloSituacion(
    Color(0xFF4A525C),
    Colors.white,
    Color(0xFFC9CED6),
    Icons.radio_button_unchecked,
  );

  static EstiloSituacion de(Situacion? situacion) => switch (situacion) {
    null => pendiente,
    Situacion.aTiempo => const EstiloSituacion(
      Color(0xFF12663D),
      Color(0xFFE3F3EA),
      Color(0xFFBFE3CE),
      Icons.check,
    ),
    Situacion.retardo => const EstiloSituacion(
      Color(0xFF8A4B00),
      Color(0xFFFCEFD9),
      Color(0xFFF2D3A1),
      Icons.schedule,
    ),
    Situacion.falta => const EstiloSituacion(
      Color(0xFFA3221A),
      Color(0xFFFBE4E2),
      Color(0xFFF1BDB8),
      Icons.close,
    ),
    Situacion.suplencia => const EstiloSituacion(
      Color(0xFF1F4FBF),
      Color(0xFFE4ECFB),
      Color(0xFFBFD0F3),
      Icons.person,
    ),
    Situacion.sinAlumnos => const EstiloSituacion(
      Color(0xFF4A525C),
      Color(0xFFECEEF1),
      Color(0xFFD5D9DF),
      Icons.meeting_room_outlined,
    ),
    Situacion.pendiente => const EstiloSituacion(
      Color(0xFF5B3BB0),
      Color(0xFFEFEAFB),
      Color(0xFFD6CBF3),
      Icons.hourglass_bottom,
    ),
    Situacion.noProgramada => const EstiloSituacion(
      Color(0xFF4A525C),
      Color(0xFFECEEF1),
      Color(0xFFD5D9DF),
      Icons.event_busy,
    ),
    Situacion.justificado => const EstiloSituacion(
      Color(0xFF12663D),
      Color(0xFFE3F3EA),
      Color(0xFFBFE3CE),
      Icons.verified_outlined,
    ),
  };
}

/// Etiqueta de situación (chip) reutilizable.
class EtiquetaSituacion extends StatelessWidget {
  const EtiquetaSituacion({
    super.key,
    required this.texto,
    required this.estilo,
  });

  final String texto;
  final EstiloSituacion estilo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estilo.fondo,
        border: Border.all(color: estilo.borde),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estilo.icono, size: 16, color: estilo.texto),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: estilo.texto,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
