import 'package:asistencia_docente/dominio/contrasena.dart';
import 'package:asistencia_docente/dominio/correo.dart';
import 'package:asistencia_docente/dominio/rol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Correo', () {
    test('PU-20 se normaliza sin espacios y en minúsculas', () {
      expect(
        normalizarCorreo('  Ana.Ruiz@Universidad.EDU.mx '),
        'ana.ruiz@universidad.edu.mx',
      );
    });

    test('PU-20 acepta correos con formato válido', () {
      expect(esCorreoValido('ana.ruiz@universidad.edu.mx'), isTrue);
    });

    test('PU-20 rechaza correos sin @, sin dominio o con espacios', () {
      expect(esCorreoValido(''), isFalse);
      expect(esCorreoValido('ana.ruiz'), isFalse);
      expect(esCorreoValido('ana@'), isFalse);
      expect(esCorreoValido('ana@universidad'), isFalse);
      expect(esCorreoValido('ana ruiz@universidad.edu.mx'), isFalse);
    });
  });

  group('Contraseña (C-01)', () {
    test('PU-21 acepta 10+ caracteres con letras y números', () {
      expect(validarContrasena('asistencia2026'), isNull);
    });

    test('PU-21 rechaza menos de 10 caracteres', () {
      expect(validarContrasena('abc12345'), ProblemaContrasena.muyCorta);
    });

    test('PU-21 rechaza contraseñas sin números o sin letras', () {
      expect(
        validarContrasena('solamenteletras'),
        ProblemaContrasena.sinNumeros,
      );
      expect(validarContrasena('12345678901'), ProblemaContrasena.sinLetras);
    });
  });

  group('Rol', () {
    test('PU-22 se convierte desde el código guardado', () {
      expect(Rol.desdeCodigo('ENC'), Rol.encargado);
      expect(Rol.desdeCodigo('DOC'), Rol.docente);
      expect(Rol.desdeCodigo('COO'), Rol.coordinacion);
    });

    test('PU-22 un código desconocido devuelve null', () {
      expect(Rol.desdeCodigo('ADMIN'), isNull);
      expect(Rol.desdeCodigo(null), isNull);
    });
  });
}
