/// Fuente de la hora actual (10_ESTANDARES §6). El dominio nunca llama a
/// `DateTime.now()`: recibe la hora de aquí, y las pruebas usan [RelojFijo].
abstract interface class Reloj {
  /// Instante actual en UTC.
  DateTime ahora();
}

class RelojSistema implements Reloj {
  const RelojSistema();

  @override
  DateTime ahora() => DateTime.now().toUtc();
}

/// Reloj desplazado: hace que la app "viva" en otra fecha/hora, para la
/// demostración (`--dart-define=FECHA_HORA_DEMO=2026-11-19T09:05`).
class RelojDesplazado implements Reloj {
  RelojDesplazado(DateTime inicioDemoUtc)
    : _desplazamiento = inicioDemoUtc.difference(DateTime.now().toUtc());

  final Duration _desplazamiento;

  @override
  DateTime ahora() => DateTime.now().toUtc().add(_desplazamiento);
}

class RelojFijo implements Reloj {
  RelojFijo(this.instante);

  DateTime instante;

  @override
  DateTime ahora() => instante;
}
