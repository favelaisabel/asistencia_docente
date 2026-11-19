import 'package:asistencia_docente/dominio/registro.dart';
import 'package:asistencia_docente/dominio/reportes.dart';
import 'package:asistencia_docente/dominio/situacion.dart';
import 'package:asistencia_docente/dominio/tiempo.dart';
import 'package:flutter_test/flutter_test.dart';

Situacion aunNoLlega({int? llegada, required int ahora}) => calcularSituacion(
  estado: EstadoCaptura.aunNoLlega,
  minutoLlegada: llegada,
  minutoActual: ahora,
);

Registro registro({
  String docenteId = '1001',
  String nombre = 'Laura Pérez',
  EstadoCaptura estado = EstadoCaptura.presente,
  JustificacionEstado justificacion = JustificacionEstado.ninguna,
}) => Registro(
  id: 'A101_20261119_09',
  periodoId: 'p',
  claseId: 'c',
  aulaId: 'A101',
  fecha: '2026-11-19',
  hora: 9,
  turno: 'MAT',
  docenteId: docenteId,
  docenteNombre: nombre,
  materia: 'M',
  grupo: 'G',
  estado: estado,
  suplenteNombre: '',
  observacion: '',
  horaDispositivo: inicioDelBloqueUtc(
    '2026-11-19',
    9,
  ).add(const Duration(minutes: 5)),
  horaServidor: null,
  llegadaDispositivo: null,
  desfaseRelojMs: 0,
  capturadoSinConexion: false,
  origen: 'APP',
  registradoPor: 'u',
  version: 1,
  actualizadoPor: 'u',
  justificacion: justificacion,
);

void main() {
  group('Situación efectiva (RN-002, RN-003)', () {
    test('PU-07 llegada en los minutos 0–15 es a tiempo', () {
      expect(aunNoLlega(llegada: 0, ahora: 40), Situacion.aTiempo);
      expect(aunNoLlega(llegada: 15, ahora: 40), Situacion.aTiempo);
    });

    test('PU-08 llegada en los minutos 16–30 es retardo', () {
      expect(aunNoLlega(llegada: 16, ahora: 40), Situacion.retardo);
      expect(aunNoLlega(llegada: 30, ahora: 40), Situacion.retardo);
    });

    test('PU-09 llegada después del minuto 30 es falta', () {
      expect(aunNoLlega(llegada: 31, ahora: 40), Situacion.falta);
    });

    test('PU-10 sin llegada: pendiente hasta el minuto 30, después falta', () {
      expect(aunNoLlega(ahora: 30), Situacion.pendiente);
      expect(aunNoLlega(ahora: 31), Situacion.falta);
    });

    test('PU-11 sin alumnos no es falta (RN-013)', () {
      final s = calcularSituacion(
        estado: EstadoCaptura.sinAlumnos,
        minutoLlegada: null,
        minutoActual: 50,
      );
      expect(s, Situacion.sinAlumnos);
      expect(s.incidencia, isFalse);
    });

    test('presente es a tiempo y sin docente es falta', () {
      expect(
        calcularSituacion(
          estado: EstadoCaptura.presente,
          minutoLlegada: null,
          minutoActual: 25,
        ),
        Situacion.aTiempo,
      );
      expect(
        calcularSituacion(
          estado: EstadoCaptura.sinDocente,
          minutoLlegada: null,
          minutoActual: 5,
        ),
        Situacion.falta,
      );
    });

    test(
      'PU-17 una justificación aprobada convierte en justificado (RN-005)',
      () {
        final s = calcularSituacion(
          estado: EstadoCaptura.sinDocente,
          minutoLlegada: null,
          minutoActual: 50,
          justificacion: JustificacionEstado.aprobada,
        );
        expect(s, Situacion.justificado);
        expect(s.incidencia, isFalse);
      },
    );
  });

  group('Identificador y tiempo', () {
    test('PU-13 ID determinista aula_fecha_hora (RN-006)', () {
      expect(idRegistro('A101', '2027-01-15', 9), 'A101_20270115_09');
      expect(idRegistro('B2', '2027-01-15', 14), 'B2_20270115_14');
    });

    test('hora de México: UTC−6 y día de la semana', () {
      final m = MomentoNegocio.desdeUtc(DateTime.utc(2026, 11, 19, 15, 7));
      expect(m.fecha, '2026-11-19');
      expect(m.hora, 9);
      expect(m.minuto, 7);
      expect(m.diaSemana, DateTime.thursday);
      expect(
        MomentoNegocio.desdeUtc(DateTime.utc(2026, 11, 20, 2)).fecha,
        '2026-11-19',
      );
    });

    test('minutos desde el inicio del bloque', () {
      final llegada = DateTime.utc(2026, 11, 19, 15, 22);
      expect(minutosDesdeInicioDelBloque('2026-11-19', 9, llegada), 22);
    });

    test('semana de lunes a domingo', () {
      final semana = semanaDe('2026-11-19');
      expect(semana.first, '2026-11-16');
      expect(semana.last, '2026-11-22');
    });
  });

  group('Hora dudosa (RNF-008)', () {
    final servidor = DateTime.utc(2026, 11, 19, 15);

    test('PU-14 desfase del reloj mayor a 5 minutos', () {
      expect(
        esHoraDudosa(
          horaDispositivo: servidor,
          horaServidor: servidor,
          desfaseRelojMs: 6 * 60000,
        ),
        isTrue,
      );
      expect(
        esHoraDudosa(
          horaDispositivo: servidor,
          horaServidor: servidor,
          desfaseRelojMs: 4 * 60000,
        ),
        isFalse,
      );
    });

    test(
      'PU-14 registro sin conexión que llega horas después NO es dudoso',
      () {
        final capturado = servidor.subtract(const Duration(hours: 3));
        expect(
          esHoraDudosa(
            horaDispositivo: capturado,
            horaServidor: servidor,
            desfaseRelojMs: 0,
          ),
          isFalse,
        );
      },
    );

    test('PU-14 hora del celular posterior a la del servidor es dudosa', () {
      final futuro = servidor.add(const Duration(minutes: 8));
      expect(
        esHoraDudosa(
          horaDispositivo: futuro,
          horaServidor: servidor,
          desfaseRelojMs: 0,
        ),
        isTrue,
      );
    });
  });

  group('Reportes', () {
    test('PU-15 totales por docente', () {
      final filas = [
        (registro(), Situacion.aTiempo),
        (registro(), Situacion.retardo),
        (registro(), Situacion.falta),
        (registro(docenteId: '1002', nombre: 'Jorge Ramírez'), Situacion.falta),
        (registro(), Situacion.justificado),
      ];
      final totales = totalesPorDocente(filas);
      expect(totales.map((t) => t.docenteNombre), [
        'Jorge Ramírez',
        'Laura Pérez',
      ]);
      final laura = totales.last;
      expect(
        (
          laura.aTiempo,
          laura.retardos,
          laura.faltas,
          laura.justificados,
          laura.total,
        ),
        (1, 1, 1, 1, 4),
      );
    });

    test('PU-16 celdas que empiezan con = + - @ se neutralizan (C-14)', () {
      expect(celdaSegura('=HYPERLINK("x")'), "'=HYPERLINK(\"x\")");
      expect(celdaSegura('+52'), "'+52");
      expect(celdaSegura('-1'), "'-1");
      expect(celdaSegura('@SUM(A1)'), "'@SUM(A1)");
      expect(celdaSegura('Laura Pérez'), 'Laura Pérez');
      expect(celdaSegura(''), '');
    });
  });
}
