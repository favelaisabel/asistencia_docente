# 01_CONTEXTO — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo I · Etapa 1
**Versión:** 3 · **Fecha:** 2026-11-09 · **Estado:** Cerrada (con excepción documentada, ver §12)

Convenciones: **(C)** dato confirmado · **(S)** supuesto · **(P)** pendiente.

---

## 1. Antecedentes

La universidad cuenta con **1 edificio, 40 aulas y 2 turnos (C)**. Un **único encargado (C)** verifica **cada hora (C)** que los docentes estén impartiendo su clase, mediante un recorrido de **~30 minutos (C)**, anotando en una libreta aula, docente, fecha, hora y situación. Con esas anotaciones se elabora un reporte que toma **1 hora (C)**. Las faltas pueden derivar en **actas administrativas (C)**. Existe un **horario oficial aula–docente–hora (C)**, que no se utiliza durante el recorrido.

## 2. Problema

| # | Problema | Efecto |
|---|---|---|
| P1 | Anotar a mano 4–5 datos en cada una de 40 aulas | ~45 s por aula; recorridos de 30 min |
| P2 | Nombre del docente escrito de memoria | Errores de identidad que pueden generar actas contra la persona equivocada |
| P3 | Hora escrita a mano | No verificable si un docente impugna un acta |
| P4 | "No hay maestro" sin identificar al docente | Hay que cruzar después con el horario oficial |
| P5 | Situaciones (presente, retardo, suplente, grupo sin alumnos, sin docente) en texto libre | Registros inconsistentes y difíciles de contabilizar |
| P6 | La libreta es el único respaldo | Pérdida de la evidencia que sustenta actas |
| P7 | Reporte por transcripción manual | 1 h de trabajo y errores de transcripción |
| P8 | El docente no puede consultar ni justificar formalmente | Disputas sin canal claro; actas sin respaldo |
| P9 | Sin histórico de datos | No se detectan faltas recurrentes ni patrones por aula u horario |

### Enunciado del problema

> El control de asistencia docente en un edificio de 40 aulas depende de anotaciones manuales que un solo encargado realiza cada hora. Esto consume cerca de la mitad de su jornada, produce registros inexactos y no verificables, retrasa los reportes y deja sin evidencia confiable decisiones sensibles como el levantamiento de actas. Además, los docentes no cuentan con un canal formal para consultar o justificar sus registros.

## 3. Objetivos

1. Reducir el tiempo de registro por aula y por recorrido.
2. Identificar al docente a partir del horario oficial, sin escribirlo.
3. Registrar fecha y hora de forma automática y verificable.
4. Generar reportes al instante.
5. Conservar la evidencia de forma segura, sin pérdidas.
6. Dar a los docentes un canal para consultar y justificar sus registros.

## 4. Interesados y usuarios

| Rol | Relación | ¿Usuario? |
|---|---|---|
| Encargado de recorridos (1) | Registra asistencia | Sí, principal |
| Docentes | Son registrados; consultan y justifican | Sí (C) |
| Coordinación académica | Recibe reportes diarios y semanales; aprueba o rechaza justificaciones; puede levantar actas | Sí (C) |
| Administrador del sistema escolar | Mantiene el horario oficial | Indirecto |

## 5. Proceso actual (AS-IS)

1. Cada hora, el encargado recorre las 40 aulas (~30 min).
2. En cada aula anota aula, docente, fecha, hora y situación.
3. Al final, alguien transcribe la libreta y elabora el reporte (1 h).
4. El reporte llega a Coordinación académica (C), que puede levantar un acta.
5. No existe un paso formal de consulta o justificación del docente (S).

## 6. Situaciones a registrar (C)

Presente · Retardo · Suplente · Grupo sin alumnos · Sin docente (falta)

### Reglas de negocio identificadas (C)

| Regla | Definición |
|---|---|
| Puntualidad | 0–15 min tras el inicio de la clase: a tiempo |
| Retardo | 16–30 min tras el inicio de la clase |
| Falta | Más de 30 min tras el inicio, o docente ausente |
| Justificación | El docente puede justificar un registro en un plazo máximo de **3 días hábiles** |
| Aprobación | **Coordinación académica** aprueba o rechaza cada justificación |
| Reportes | **Diario y semanal**, en **PDF y Excel**, dirigidos a Coordinación académica |
| Horario oficial | Reside en el **sistema escolar** institucional |

## 7. Volumen estimado

- Turnos de ~7 h (S) → ~14 recorridos/día.
- 40 aulas × 14 recorridos ≈ **560 registros/día** (S).
- 14 × 30 min ≈ 7 h/día de recorridos → ~50 % de la jornada del encargado (S).

## 8. Métricas de éxito

| ID | Métrica | Línea base | Meta propuesta |
|---|---|---|---|
| M1 | Tiempo por recorrido completo | 30 min (C) | ≤ 15 min |
| M2 | Tiempo de generación del reporte | 60 min (C) | < 1 min |
| M3 | % del tiempo del encargado en recorridos | ~50 % (S) | ≤ 25 % |
| M4 | Registros con docente identificado según el horario | ~0 % | 100 % |
| M5 | Registros con fecha y hora automáticas y verificables | 0 % | 100 % |
| M6 | Registros perdidos o ilegibles | desconocido | 0 |
| M7 | Justificaciones resueltas por Coordinación dentro del plazo | no existe | 100 % (plazo: 3 días hábiles) |

> Nota M1: el tiempo de caminar entre aulas no se elimina; la meta supone que la mayor parte de los ~45 s/aula corresponde a escribir. Debe medirse en un recorrido real.

## 9. Consideraciones para etapas posteriores

No forman parte del problema, pero se registran para no perderlas:

- Conectividad irregular en el edificio (C) → el registro debe funcionar sin conexión.
- Datos sensibles por su uso en actas (C) → trazabilidad, evidencia y control de acceso.
- Horario oficial en el sistema escolar (C) → evaluar en Etapa 2 si existe exportación o integración; riesgo de dependencia externa.
- Propuesta inicial de solución: aplicación móvil (Flutter) con generación de reportes; se evalúa en Etapas 2 y 5.

## 10. Pendientes

| # | Pendiente | Estado |
|---|---|---|
| 1 | Receptor, frecuencia y formato del reporte | Resuelto: Coordinación, diario + semanal, PDF y Excel |
| 2 | Duración de cada turno | Resuelto en Etapa 3: 7:00–14:00 y 14:00–21:00 (14 recorridos/día) |
| 3 | Tolerancia de retardo | Resuelto: 15 min retardo / 30 min falta |
| 4 | Plazo y aprobador de justificaciones | Resuelto: 3 días hábiles, Coordinación |
| 5 | Formato del horario oficial | Resuelto: sistema escolar (forma de acceso por definir en Etapa 2) |

## 11. Criterios de salida de la Etapa 1

- [x] Problema descrito sin mencionar tecnología
- [x] Interesados y usuarios identificados
- [x] Proceso actual documentado
- [x] Línea base de M1 y M2 obtenida
- [x] Destinatario del reporte identificado
- [x] Reglas de negocio iniciales identificadas
- [~] Documento validado por el encargado y Coordinación → **excepción documentada (§12)**

## 12. Cierre de etapa

**Resultado:** Etapa 1 cerrada con una excepción.

**Excepción aprobada:** la validación formal con el encargado de recorridos y Coordinación académica aún no se realiza. El desarrollador responsable aprueba continuar a la Etapa 2 con la condición de obtener esa validación **antes de aprobar los requisitos (Etapa 3)**.

**Supuestos vigentes:** duración del turno ~7 h; volumen ~560 registros/día; ~50 % de la jornada del encargado en recorridos.

**Aprobó:** desarrollador responsable · 2026-11-09
