import 'package:asistencia_docente/dominio/horario.dart';
import 'package:flutter_test/flutter_test.dart';

const encabezado = [
  'aula',
  'num_empleado',
  'docente',
  'dia',
  'hora_inicio',
  'hora_fin',
  'materia',
  'grupo',
];

List<List<String>> archivo(List<List<String>> filas) => [encabezado, ...filas];

List<String> fila({
  String aula = 'A101',
  String empleado = '1001',
  String docente = 'Laura Pérez Soto',
  String dia = 'lunes',
  String inicio = '7',
  String fin = '9',
  String materia = 'Cálculo',
  String grupo = '1A',
}) => [aula, empleado, docente, dia, inicio, fin, materia, grupo];

void main() {
  test('un archivo correcto produce sus clases, aulas y docentes', () {
    final r = validarHorario(
      archivo([
        fila(),
        fila(
          aula: 'A102',
          empleado: '1002',
          docente: 'Jorge Ramírez',
          dia: 'Martes',
          inicio: '14:00',
          fin: '16:00',
        ),
      ]),
    );
    expect(r.esValido, isTrue);
    expect(r.clases, hasLength(2));
    expect(r.aulas, {'A101', 'A102'});
    expect(r.docentes['1002'], 'Jorge Ramírez');
    expect(r.clases[1].diaSemana, 2);
    expect(r.clases[1].horaInicio, 14);
  });

  test('PU-12 una clase de 2 horas cubre 2 bloques (RN-012)', () {
    final clase = validarHorario(
      archivo([fila(inicio: '9', fin: '11')]),
    ).clases.single;
    expect(clase.bloques, [9, 10]);
    expect(clasesDelBloque([clase], 1, 10), [clase]);
    expect(clasesDelBloque([clase], 1, 11), isEmpty);
  });

  test('PU-01 traslape de aula (RN-011)', () {
    final r = validarHorario(
      archivo([
        fila(),
        fila(empleado: '1002', docente: 'Otro Docente', inicio: '8', fin: '10'),
      ]),
    );
    expect(r.esValido, isFalse);
    expect(r.clases, isEmpty, reason: 'con errores no se importa nada');
    expect(
      r.errores.single.problema,
      contains('El aula A101 ya tiene clase el lunes a las 8:00'),
    );
  });

  test('PU-02 traslape de docente (RN-011)', () {
    final r = validarHorario(
      archivo([fila(), fila(aula: 'A105', inicio: '8', fin: '9')]),
    );
    expect(
      r.errores.single.problema,
      contains('El docente 1001 ya tiene clase'),
    );
  });

  test('PU-03 horas fuera de turno o que cruzan de turno (RN-014)', () {
    expect(
      validarHorario(
        archivo([fila(inicio: '6', fin: '8')]),
      ).errores.single.columna,
      'hora_inicio',
    );
    expect(
      validarHorario(
        archivo([fila(inicio: '13', fin: '15')]),
      ).errores.single.problema,
      contains('sale del turno'),
    );
    expect(
      validarHorario(
        archivo([fila(inicio: '20', fin: '22')]),
      ).errores.single.problema,
      contains('sale del turno'),
    );
    expect(
      validarHorario(
        archivo([fila(inicio: '9', fin: '9')]),
      ).errores.single.columna,
      'hora_fin',
    );
  });

  test('PU-04 datos inválidos por fila, con número de fila de Excel', () {
    final r = validarHorario(
      archivo([fila(), fila(aula: 'A103', empleado: '', dia: 'domingo')]),
    );
    expect(r.errores.map((e) => e.fila).toSet(), {3});
    expect(
      r.errores.map((e) => e.columna),
      containsAll(['num_empleado', 'dia']),
    );
  });

  test('PU-04 un mismo empleado con dos nombres distintos', () {
    final r = validarHorario(
      archivo([
        fila(),
        fila(aula: 'A102', docente: 'Laura Perez', dia: 'martes'),
      ]),
    );
    expect(
      r.errores.single.problema,
      contains('aparece con otro nombre en la fila 2'),
    );
  });

  test('PU-05 columnas faltantes', () {
    final r = validarHorario([
      ['aula', 'docente'],
      ['A101', 'X'],
    ]);
    expect(r.esValido, isFalse);
    expect(r.errores.map((e) => e.columna), contains('num_empleado'));
  });

  test('PU-05 archivo vacío o sin clases', () {
    expect(validarHorario([]).esValido, isFalse);
    expect(
      validarHorario([encabezado]).errores.single.problema,
      'El archivo no tiene clases.',
    );
  });

  test('PU-06 límite de filas', () {
    final r = validarHorario(
      archivo(List.generate(maxFilasHorario + 1, (_) => fila())),
    );
    expect(
      r.errores.single.problema,
      contains('más de $maxFilasHorario filas'),
    );
  });

  test('el aula se normaliza para usarse como ID', () {
    expect(normalizarAula(' a-101 '), 'A101');
  });
}
