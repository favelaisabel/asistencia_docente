import 'turno.dart';

/// Una clase del horario oficial (`clases/{id}`, 06_MODELO_DATOS §4.8).
class Clase {
  const Clase({
    required this.aulaId,
    required this.docenteId,
    required this.docenteNombre,
    required this.materia,
    required this.grupo,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.id = '',
  });

  final String id;
  final String aulaId;
  final String docenteId;
  final String docenteNombre;
  final String materia;
  final String grupo;

  /// 1 = lunes … 6 = sábado.
  final int diaSemana;

  /// Primer bloque (7–20).
  final int horaInicio;

  /// Hora de término (8–21), exclusiva.
  final int horaFin;

  /// Bloques de una hora que cubre la clase: una clase de 2 h genera 2 (RN-012).
  List<int> get bloques => [for (var h = horaInicio; h < horaFin; h++) h];

  bool cubre(int diaSemana, int hora) =>
      this.diaSemana == diaSemana && hora >= horaInicio && hora < horaFin;
}

/// Clases que tienen lugar en un día y bloque, ordenadas por aula (RF-013).
List<Clase> clasesDelBloque(Iterable<Clase> clases, int diaSemana, int hora) {
  return clases.where((c) => c.cubre(diaSemana, hora)).toList()
    ..sort((a, b) => a.aulaId.compareTo(b.aulaId));
}

/// Normaliza el número de aula para usarlo como ID (`A-101 ` → `A101`).
String normalizarAula(String aula) =>
    aula.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_/]'), '');

/// Columnas de la plantilla de importación (RF-010).
const columnasPlantilla = [
  'aula',
  'num_empleado',
  'docente',
  'dia',
  'hora_inicio',
  'hora_fin',
  'materia',
  'grupo',
];

const _dias = {
  'lunes': 1,
  'martes': 2,
  'miercoles': 3,
  'miércoles': 3,
  'jueves': 4,
  'viernes': 5,
  'sabado': 6,
  'sábado': 6,
};

const nombresDias = [
  '',
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Error de una fila del archivo (RF-011).
class ErrorImportacion {
  const ErrorImportacion(this.fila, this.columna, this.problema);

  /// Número de fila tal como la ve Coordinación en Excel (encabezado = 1).
  final int fila;
  final String columna;
  final String problema;

  @override
  String toString() => 'Fila $fila · $columna: $problema';
}

/// Resultado de validar un archivo de horario.
class ResultadoImportacion {
  const ResultadoImportacion(this.clases, this.errores);

  final List<Clase> clases;
  final List<ErrorImportacion> errores;

  bool get esValido => errores.isEmpty && clases.isNotEmpty;

  Set<String> get aulas => {for (final c in clases) c.aulaId};

  Map<String, String> get docentes => {
    for (final c in clases) c.docenteId: c.docenteNombre,
  };
}

const maxFilasHorario = 5000;

int? _hora(String texto) {
  final limpio = texto.trim();
  // Acepta 7, 07:00, 07:00:00 (Excel) y 7.0 (número de Excel).
  final coincidencia = RegExp(
    r'^(\d{1,2})(?:(?::00){1,2}|\.0+)?$',
  ).firstMatch(limpio);
  if (coincidencia == null) return null;
  return int.tryParse(coincidencia.group(1) ?? '');
}

int? _dia(String texto) {
  final limpio = texto.trim().toLowerCase();
  return _dias[limpio] ?? int.tryParse(limpio);
}

/// Valida las filas leídas del archivo (sin encabezado ya separado):
/// columnas, tipos, rangos, turnos (RN-014), coherencia de docentes y
/// traslapes de aula y de docente (RN-011). Si hay cualquier error, no se
/// importa nada (RF-011).
ResultadoImportacion validarHorario(List<List<String>> filasConEncabezado) {
  final errores = <ErrorImportacion>[];
  if (filasConEncabezado.isEmpty) {
    return const ResultadoImportacion([], [
      ErrorImportacion(1, 'archivo', 'El archivo está vacío.'),
    ]);
  }

  final encabezado = [
    for (final c in filasConEncabezado.first) c.trim().toLowerCase(),
  ];
  final indice = <String, int>{};
  for (final columna in columnasPlantilla) {
    final i = encabezado.indexOf(columna);
    if (i < 0) {
      errores.add(ErrorImportacion(1, columna, 'Falta la columna "$columna".'));
    } else {
      indice[columna] = i;
    }
  }
  if (errores.isNotEmpty) return ResultadoImportacion(const [], errores);

  final datos = filasConEncabezado.skip(1).toList();
  if (datos.length > maxFilasHorario) {
    return const ResultadoImportacion([], [
      ErrorImportacion(
        1,
        'archivo',
        'El archivo tiene más de $maxFilasHorario filas.',
      ),
    ]);
  }

  final clases = <Clase>[];
  final filaDeClase = <Clase, int>{};
  final nombrePorDocente = <String, (String, int)>{};

  for (var i = 0; i < datos.length; i++) {
    final numeroFila = i + 2;
    final fila = datos[i];
    if (fila.every((c) => c.trim().isEmpty)) continue;
    String valor(String columna) {
      final pos = indice[columna] ?? 0;
      return pos < fila.length ? fila[pos].trim() : '';
    }

    final erroresFila = errores.length;
    void error(String columna, String problema) =>
        errores.add(ErrorImportacion(numeroFila, columna, problema));

    final aula = normalizarAula(valor('aula'));
    if (aula.isEmpty || aula.length > 10) {
      error('aula', 'Aula vacía o demasiado larga.');
    }

    final docenteId = valor('num_empleado');
    if (!RegExp(r'^[A-Za-z0-9]{1,20}$').hasMatch(docenteId)) {
      error(
        'num_empleado',
        'Número de empleado vacío o con caracteres no válidos.',
      );
    }
    final docente = valor('docente');
    if (docente.length < 3 || docente.length > 120) {
      error('docente', 'Nombre del docente vacío o inválido.');
    }

    final dia = _dia(valor('dia'));
    if (dia == null || dia < 1 || dia > 6) {
      error('dia', 'Día no válido (usa lunes a sábado o 1–6).');
    }

    final inicio = _hora(valor('hora_inicio'));
    final fin = _hora(valor('hora_fin'));
    if (inicio == null) error('hora_inicio', 'Hora no válida (usa 7 o 07:00).');
    if (fin == null) error('hora_fin', 'Hora no válida (usa 9 o 09:00).');
    if (inicio != null && fin != null) {
      final turno = Turno.deBloque(inicio);
      if (turno == null) {
        error(
          'hora_inicio',
          'La hora $inicio está fuera de los turnos (7:00–21:00).',
        );
      } else if (fin <= inicio) {
        error('hora_fin', 'La hora de fin debe ser mayor que la de inicio.');
      } else if (fin - 1 > turno.ultimoBloque) {
        error(
          'hora_fin',
          'La clase sale del turno (${turno.primerBloque}:00–${turno.ultimoBloque + 1}:00).',
        );
      }
    }

    final materia = valor('materia');
    final grupo = valor('grupo');
    if (materia.isEmpty || materia.length > 120) {
      error('materia', 'Materia vacía o demasiado larga.');
    }
    if (grupo.isEmpty || grupo.length > 20) {
      error('grupo', 'Grupo vacío o demasiado largo.');
    }

    if (docenteId.isNotEmpty && docente.length >= 3) {
      final previo = nombrePorDocente[docenteId];
      if (previo == null) {
        nombrePorDocente[docenteId] = (docente, numeroFila);
      } else if (previo.$1 != docente) {
        error(
          'docente',
          'El empleado $docenteId aparece con otro nombre en la fila ${previo.$2}.',
        );
      }
    }

    if (errores.length == erroresFila) {
      final clase = Clase(
        aulaId: aula,
        docenteId: docenteId,
        docenteNombre: docente,
        materia: materia,
        grupo: grupo,
        diaSemana: dia ?? 0,
        horaInicio: inicio ?? 0,
        horaFin: fin ?? 0,
      );
      clases.add(clase);
      filaDeClase[clase] = numeroFila;
    }
  }

  // RN-011: sin traslapes de aula ni de docente.
  final ocupacionAula = <String, int>{};
  final ocupacionDocente = <String, int>{};
  for (final clase in clases) {
    final fila = filaDeClase[clase] ?? 0;
    for (final h in clase.bloques) {
      final claveAula = '${clase.aulaId}|${clase.diaSemana}|$h';
      final claveDocente = '${clase.docenteId}|${clase.diaSemana}|$h';
      final otraAula = ocupacionAula[claveAula];
      if (otraAula != null) {
        errores.add(
          ErrorImportacion(
            fila,
            'aula / día / hora',
            'El aula ${clase.aulaId} ya tiene clase el ${nombresDias[clase.diaSemana].toLowerCase()} a las $h:00 (fila $otraAula).',
          ),
        );
        break;
      }
      final otraDocente = ocupacionDocente[claveDocente];
      if (otraDocente != null) {
        errores.add(
          ErrorImportacion(
            fila,
            'num_empleado / día / hora',
            'El docente ${clase.docenteId} ya tiene clase el ${nombresDias[clase.diaSemana].toLowerCase()} a las $h:00 (fila $otraDocente).',
          ),
        );
        break;
      }
      ocupacionAula[claveAula] = fila;
      ocupacionDocente[claveDocente] = fila;
    }
  }

  if (clases.isEmpty && errores.isEmpty) {
    errores.add(
      const ErrorImportacion(2, 'archivo', 'El archivo no tiene clases.'),
    );
  }
  errores.sort((a, b) => a.fila.compareTo(b.fila));
  return ResultadoImportacion(errores.isEmpty ? clases : const [], errores);
}
