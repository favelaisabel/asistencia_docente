# 04_ALCANCE_MVP — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo I · Etapa 4
**Versión:** 2 · **Fecha:** 2026-11-18 · **Estado:** Cerrada (ver §9 y §10)
**Entradas:** [01_CONTEXTO.md](01_CONTEXTO.md) v3 · [02_VIABILIDAD_RIESGOS.md](02_VIABILIDAD_RIESGOS.md) v1 · [03_REQUISITOS.md](03_REQUISITOS.md) v2

---

## 1. Objetivo de la etapa

Priorizar los requisitos aprobados por valor, riesgo, esfuerzo y dependencias, y definir un **MVP que complete un proceso real de principio a fin** dentro de las restricciones: 1 desarrollador + IA, 2–3 meses, $0 (RES-01 a RES-03).

## 2. Proceso de principio a fin que cubre el MVP

> **El encargado registra la asistencia en el aula (aun sin señal) → los datos se sincronizan → Coordinación obtiene el reporte diario y semanal en PDF y Excel.**

Es exactamente el proceso que hoy se hace con libreta (01_CONTEXTO §5), por lo que el MVP sustituye a la libreta desde el primer día de uso. El proceso de justificación por parte del docente es **nuevo** (hoy no existe) y se entrega en la segunda versión.

## 3. Agrupación en épicas y priorización

Escalas: Valor y Riesgo que reduce (1 bajo – 3 alto). Esfuerzo en semanas de 1 desarrollador con IA (estimación).

| Épica | Requisitos | Valor | Riesgo que reduce | Esfuerzo | Depende de | Prioridad |
|---|---|:-:|:-:|:-:|---|---|
| **EP1** Acceso y roles | RF-001, RF-002, RF-004, RF-005 · RNF-005, RNF-006, RNF-007 | 3 | 3 (R-05) | 1 | — | **Must** |
| **EP2** Horario y catálogos | RF-006, RF-008, RF-009, RF-010, RF-011 · RN-011, RN-014 | 3 | 3 (R-01) | 1.5 | EP1 | **Must** |
| **EP3** Recorrido y registro | RF-013 a RF-019, RF-022 · RN-001 a RN-003, RN-006, RN-007, RN-009, RN-012, RN-013 · RNF-003, RNF-012, RNF-013 | 3 | 2 | 2 | EP2 | **Must** |
| **EP4** Sin conexión y sincronización | RF-021 · RNF-001, RNF-002 | 3 | 3 (R-02) | 1.5 | EP3 | **Must** |
| **EP5** Integridad y bitácora | RF-031, RF-032 · RN-008 · RNF-008, RNF-009 | 3 | 3 (R-04, R-11) | 1 | EP3, EP4 | **Must** |
| **EP6** Reportes y respaldo | RF-028, RF-029, RF-030, RF-033 · RNF-004, RNF-014 | 3 | 3 (R-08, CR-001) | 2 | EP3 | **Must** |
| **EP7** Portal docente y justificaciones | RF-023 a RF-027 · RN-004, RN-005, RN-010 · RNF-019, RNF-020 | 2 | 2 (P8) | 2.5 | EP1, EP3 | **Should** |
| **EP8** Administración complementaria | RF-003, RF-007, RF-012, RF-020 | 2 | 1 | 0.5 | EP2 | **Should** |

**Total estimado:** MVP (EP1–EP6) ≈ **9 semanas** · Versión 1.1 (EP7–EP8) ≈ **3 semanas** · Total ≈ 12 semanas (3 meses).

> Las estimaciones son preliminares; se ajustan en la Etapa 9 (Plan incremental) cuando la arquitectura esté definida.

## 4. Versiones

### Versión 1.0 — MVP (semanas 1–9)

| Incluye | Detalle |
|---|---|
| Inicio de sesión por rol | Encargado (app Android) y Coordinación (web) |
| Alta de usuarios | Coordinación crea usuarios y asigna rol |
| Periodo activo | Un periodo a la vez |
| Importación del horario | Plantilla Excel/CSV con validación previa |
| Recorrido | Aulas del bloque actual con docente precargado; registro con un toque; "aún no llega"; suplente con nombre; observación; avance del recorrido |
| Sin conexión | Registro local y sincronización automática |
| Integridad | Hora automática (dispositivo + servidor), bitácora inmutable, corrección con motivo por Coordinación |
| Reportes y respaldo | Diario y semanal en PDF y Excel, con filtros; respaldo completo CSV (CR-001) |

**Docentes en el MVP:** existen como **catálogo** (vienen en el horario), pero **no inician sesión** todavía.

### Versión 1.1 (semanas 10–12)

| Incluye | Detalle |
|---|---|
| Portal docente (web) | Consulta de registros propios y avisos de retardo/falta |
| Justificaciones | Envío con adjunto opcional, plazo de 3 días hábiles, aprobación/rechazo por Coordinación |
| Administración | Restablecer contraseña, días inhábiles, edición manual del horario, "clase no programada" |

### Holgura

La versión 1.1 es la **holgura del proyecto**: si el MVP se retrasa, la 1.1 se recorta o se mueve, pero el MVP no se reduce (R-07).

## 5. Fuera de alcance (NO se desarrollará inicialmente)

| # | Funcionalidad | Motivo |
|---|---|---|
| X-01 | Integración directa con el sistema escolar | Forma de acceso desconocida (R-01); se sustituye por plantilla |
| X-02 | App para iPhone | Costo de publicación (RES-03); docentes y Coordinación usan web |
| X-03 | Publicación en Google Play | Pago de registro; se instala por APK |
| X-04 | Que el docente marque su propia asistencia (QR, geolocalización, biometría) | Cambia el proceso actual; riesgo de suplantación; fuera del problema planteado |
| X-05 | Generación o firma de actas administrativas | Proceso jurídico de Coordinación; el sistema solo aporta la evidencia |
| X-06 | Notificaciones push o por correo | Complejidad y costo; el aviso se muestra al entrar al portal |
| X-07 | Tableros con gráficas y estadísticas avanzadas | Los reportes cubren la necesidad inicial |
| X-08 | Varios edificios, campus o encargados simultáneos | Hoy hay 1 edificio y 1 encargado |
| X-09 | Integración con nómina o Recursos Humanos | No es parte del proceso actual |
| X-10 | Varios idiomas | Todos los usuarios hablan español |

Cualquiera de estos puntos entra al backlog de la **Etapa 20 (Mejora continua)** y vuelve a la Etapa 1 si se solicita.

## 6. Criterios de éxito del MVP

| Métrica (01_CONTEXTO) | Medible en | Meta |
|---|---|---|
| M1 Tiempo por recorrido | v1.0 | ≤ 15 min |
| M2 Tiempo del reporte | v1.0 | < 1 min |
| M4 Docente identificado según horario | v1.0 | 100 % |
| M5 Fecha y hora automáticas | v1.0 | 100 % |
| M6 Registros perdidos | v1.0 | 0 |
| M3 % de jornada en recorridos | v1.0 (tras 2 semanas de uso) | ≤ 25 % |
| M7 Justificaciones resueltas en plazo | v1.1 | 100 % |

**El MVP está terminado cuando:** con datos ficticios de 40 aulas y 40 docentes, el encargado completa los 14 recorridos de un día en modo avión, los registros se sincronizan sin pérdida y Coordinación descarga el reporte diario y semanal correctos en PDF y Excel.

## 7. Riesgos del alcance

| ID | Riesgo | Mitigación |
|---|---|---|
| R-07 | El MVP no cabe en 9 semanas | V1.1 es holgura; incrementos pequeños; revisar avance cada semana |
| R-14 | Requisitos no validados con usuarios (excepción Etapa 3) | Validar el prototipo en la Etapa 7 |
| R-15 | Presión para agregar funciones fuera de alcance durante el desarrollo | Toda solicitud nueva pasa por la Etapa 20 y no entra al MVP |

## 8. Evaluación de salida del Ciclo I (Definición y análisis)

| Condición de salida | Evidencia | Estado |
|---|---|---|
| Problema y objetivos documentados | 01_CONTEXTO v3 | ✅ |
| Viabilidad y riesgos evaluados | 02_VIABILIDAD_RIESGOS v1 | ✅ Viable con ajustes |
| Requisitos verificables y aprobados | 03_REQUISITOS v2 | ✅ Con excepción (validación con usuarios en Etapa 7) |
| MVP y alcance definidos | 04_ALCANCE_MVP v1 | ✅ |

**Decisión del ciclo:** ¿Requisitos aprobados y viables? → **SÍ (con excepción documentada)** → se habilita el **Ciclo II: Diseño y planificación**.

## 9. Criterios de salida de la Etapa 4

- [x] Requisitos priorizados por valor, riesgo, esfuerzo y dependencias
- [x] MVP definido que completa un proceso real de principio a fin
- [x] Versiones posteriores definidas
- [x] Lista explícita de lo que NO se desarrollará inicialmente
- [x] Criterios de éxito del MVP medibles

**Aprobó:** desarrollador responsable · 2026-11-10

## 10. Historial de cambios

| Versión | Fecha | Cambio | Origen |
|---|---|---|---|
| 1 | 2026-11-10 | Versión inicial | Etapa 4 |
| 2 | 2026-11-18 | RF-033 y RNF-014 (respaldo completo) pasan de EP8 (v1.1) a EP6 (MVP) | CR-001, Etapa 8 |
| 2 | 2026-11-18 | Calendario reemplazado por [09_ROADMAP.md](09_ROADMAP.md): la v1.1 se construye después de liberar el MVP | Etapa 9 |
