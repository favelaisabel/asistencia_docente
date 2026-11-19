import 'package:asistencia_docente/dominio/turno.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Turno.deBloque (RN-014)', () {
    test('7:00 y 13:00 pertenecen al turno matutino', () {
      expect(Turno.deBloque(7), Turno.matutino);
      expect(Turno.deBloque(13), Turno.matutino);
    });

    test('14:00 y 20:00 pertenecen al turno vespertino', () {
      expect(Turno.deBloque(14), Turno.vespertino);
      expect(Turno.deBloque(20), Turno.vespertino);
    });

    test('fuera de 7:00–20:59 no hay turno', () {
      expect(Turno.deBloque(6), isNull);
      expect(Turno.deBloque(21), isNull);
    });

    test('los códigos coinciden con el modelo de datos', () {
      expect(Turno.matutino.codigo, 'MAT');
      expect(Turno.vespertino.codigo, 'VES');
    });
  });
}
