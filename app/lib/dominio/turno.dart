/// Turnos de la universidad (RN-014): matutino 7:00–14:00, vespertino 14:00–21:00.
///
/// Las horas son bloques de una hora: el bloque 7 es 7:00–7:59 (06_MODELO_DATOS §2).
enum Turno {
  matutino('MAT', 7, 13),
  vespertino('VES', 14, 20);

  const Turno(this.codigo, this.primerBloque, this.ultimoBloque);

  /// Código guardado en la base de datos.
  final String codigo;
  final int primerBloque;
  final int ultimoBloque;

  /// Turno al que pertenece un bloque horario, o `null` si está fuera de horario.
  static Turno? deBloque(int hora) {
    for (final turno in Turno.values) {
      if (hora >= turno.primerBloque && hora <= turno.ultimoBloque) {
        return turno;
      }
    }
    return null;
  }
}
