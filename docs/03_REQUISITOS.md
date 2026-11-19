# 03_REQUISITOS — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo I · Etapa 3
**Versión:** 2 · **Fecha:** 2026-11-10 · **Estado:** Cerrada con excepción (ver §11)
**Entradas:** [01_CONTEXTO.md](01_CONTEXTO.md) v3 · [02_VIABILIDAD_RIESGOS.md](02_VIABILIDAD_RIESGOS.md) v1

Convenciones: **(C)** confirmado · **(S)** supuesto · **(P)** pendiente · **Origen**: problema (P#) de 01_CONTEXTO o ajuste (A#) / riesgo (R-##) de 02_VIABILIDAD.

---

## 1. Datos confirmados en esta etapa

| Dato | Valor |
|---|---|
| Docentes | ~40 (C) |
| Aulas | 40, en 1 edificio (C) |
| Turnos | Matutino 7:00–14:00 · Vespertino 14:00–21:00 (C) |
| Pase de lista | Cada hora → 14 recorridos/día, ~560 registros/día (C) |
| Carga del horario | Coordinación académica, al inicio de cada periodo (C) |
| Suplentes | Se registra su nombre (C) |
| Tipo de institución | Pública (C) → aplica la ley general de protección de datos personales en posesión de sujetos obligados (S: confirmar con el área de transparencia) |

## 2. Roles

| Rol | Quién | Medio de acceso |
|---|---|---|
| **ENC** — Encargado de recorridos | 1 persona | App Android |
| **DOC** — Docente | ~40 personas | Web |
| **COO** — Coordinación académica | 1+ personas | Web |

### Matriz de permisos

| Acción | ENC | DOC | COO |
|---|:-:|:-:|:-:|
| Registrar asistencia en el aula | ✅ | ❌ | ❌ |
| Corregir un registro durante el bloque de clase | ✅ | ❌ | ✅ |
| Corregir un registro después del bloque (con motivo) | ❌ | ❌ | ✅ |
| Ver registros propios | — | ✅ | — |
| Ver registros de todos | ✅ (día actual) | ❌ | ✅ |
| Enviar justificación | ❌ | ✅ (solo propios) | ❌ |
| Aprobar / rechazar justificación | ❌ | ❌ | ✅ |
| Importar y editar horario, aulas, docentes | ❌ | ❌ | ✅ |
| Gestionar usuarios y periodos | ❌ | ❌ | ✅ |
| Generar reportes | ❌ | ❌ | ✅ |
| Consultar bitácora de cambios | ❌ | ❌ | ✅ |
| Exportar respaldo completo | ❌ | ❌ | ✅ |

## 3. Requisitos funcionales (RF)

### 3.1 Acceso y usuarios

| ID | Requisito | Rol | Criterio de aceptación | Origen |
|---|---|---|---|---|
| RF-001 | Iniciar sesión con correo institucional y contraseña | Todos | Con credenciales válidas entra a la pantalla de su rol; con inválidas ve un mensaje genérico sin revelar cuál dato falló | RN-010 |
| RF-002 | Cerrar sesión | Todos | Al cerrar sesión no se puede volver a la información con el botón "atrás" | — |
| RF-003 | Restablecer contraseña por correo | Todos | Recibe un enlace de un solo uso y con vencimiento | — |
| RF-004 | Gestionar usuarios: alta, baja (desactivar) y asignación de rol | COO | Un usuario desactivado no puede iniciar sesión; sus registros históricos se conservan | — |
| RF-005 | Mantener la sesión del encargado abierta en el dispositivo | ENC | Abrir la app no exige volver a iniciar sesión, incluso sin conexión, salvo cierre de sesión o vencimiento configurado | A1 |

### 3.2 Periodo, catálogos y horario

| ID | Requisito | Rol | Criterio de aceptación | Origen |
|---|---|---|---|---|
| RF-006 | Gestionar periodos escolares (nombre, fecha inicio, fecha fin) | COO | Solo un periodo activo a la vez; los registros pertenecen al periodo en que se crearon | — |
| RF-007 | Registrar días inhábiles y clases canceladas | COO | En un día inhábil no se generan aulas por revisar ni cuentan faltas | — |
| RF-008 | Gestionar catálogo de aulas | COO | El número de aula es único | — |
| RF-009 | Gestionar catálogo de docentes | COO | El identificador del docente (número de empleado) es único | P2 |
| RF-010 | Importar horario desde plantilla Excel/CSV (aula, docente, día de la semana, hora inicio, hora fin, materia, grupo) | COO | Se ofrece la plantilla para descargar; un archivo válido carga todas las filas | A3, R-01, P4 |
| RF-011 | Validar la importación antes de guardar | COO | Se muestra la lista de errores por fila (docente o aula inexistente, hora fuera de turno, traslapes); si hay errores no se guarda nada | RN-011 |
| RF-012 | Consultar y editar el horario manualmente | COO | Los cambios aplican desde la fecha indicada y no alteran registros pasados | R-01 |

### 3.3 Recorrido y registro (app Android)

| ID | Requisito | Rol | Criterio de aceptación | Origen |
|---|---|---|---|---|
| RF-013 | Mostrar las aulas por revisar en el bloque horario actual, con docente, materia y grupo esperados precargados del horario | ENC | Al abrir el recorrido aparecen solo las aulas con clase en ese bloque, sin escribir datos | P1, P2, P4 |
| RF-014 | Registrar la situación de un aula con un toque: **Presente · Retardo · Suplente · Grupo sin alumnos · Sin docente** | ENC | Registrar un aula toma como máximo 3 toques | P1, P5, RN-001 |
| RF-015 | Tomar fecha y hora del registro automáticamente | ENC | El encargado no puede escribir ni modificar la fecha/hora | P3, A5 |
| RF-016 | Al elegir "Suplente", capturar el nombre del suplente | ENC | No se puede guardar un registro de suplente sin nombre | RN-007 |
| RF-017 | Agregar una observación opcional (texto breve) | ENC | Máximo 250 caracteres | — |
| RF-018 | Marcar a un docente como "aún no llega" y volver a registrar su llegada dentro del mismo bloque | ENC | El sistema calcula a tiempo / retardo / falta según la hora de llegada observada (RN-002, RN-003) | RN-003 |
| RF-019 | Ver el avance del recorrido (aulas registradas / pendientes) | ENC | Se muestran contadores y las aulas pendientes resaltadas | P1 |
| RF-020 | Registrar aula ocupada sin clase programada | ENC | Se guarda como "Clase no programada" con observación | Excepción E-03 |
| RF-021 | Registrar sin conexión y sincronizar automáticamente | ENC | Sin señal el registro se guarda en el dispositivo; al volver la conexión se envía sin intervención; se muestra el número de registros pendientes de envío | A1, R-02 |
| RF-022 | Corregir un registro durante el bloque de clase en curso | ENC | La corrección queda en bitácora con el valor anterior | RN-009, A5 |

### 3.4 Docentes (web)

| ID | Requisito | Rol | Criterio de aceptación | Origen |
|---|---|---|---|---|
| RF-023 | Consultar sus registros por rango de fechas | DOC | Solo ve sus propios registros (RN-010) | P8 |
| RF-024 | Ver aviso de registros nuevos de retardo o falta | DOC | Al entrar ve los registros que puede justificar y el plazo restante | P8 |
| RF-025 | Enviar justificación de un registro (motivo + adjunto opcional: imagen JPG/PNG o PDF, máx. 5 MB) | DOC | Solo dentro del plazo de 3 días hábiles; fuera de plazo el botón no está disponible; archivos de otro tipo o mayores a 5 MB se rechazan con mensaje claro | P8, RN-004 |
| RF-026 | Consultar el estado de sus justificaciones (pendiente, aprobada, rechazada + comentario) | DOC | El estado cambia al resolver Coordinación | P8 |

### 3.5 Coordinación (web)

| ID | Requisito | Rol | Criterio de aceptación | Origen |
|---|---|---|---|---|
| RF-027 | Revisar justificaciones pendientes y aprobarlas o rechazarlas con comentario | COO | El comentario es obligatorio al rechazar; la resolución queda en bitácora | RN-005 |
| RF-028 | Generar reporte **diario** en PDF y Excel | COO | Se genera en menos de 1 minuto; incluye todos los registros del día con situación y estado de justificación | P7, M2 |
| RF-029 | Generar reporte **semanal** en PDF y Excel | COO | Incluye totales por docente: asistencias, retardos, faltas, justificadas | P7, P9 |
| RF-030 | Filtrar registros y reportes por fecha, turno, docente, aula y situación | COO | Los filtros se combinan | P9 |
| RF-031 | Corregir un registro pasado indicando motivo | COO | Motivo obligatorio; queda en bitácora | RN-009, A5 |
| RF-032 | Consultar la bitácora de cambios | COO | Muestra quién, qué, cuándo, valor anterior y nuevo | A5, R-04 |
| RF-033 | Exportar respaldo completo de datos (CSV) | COO | El archivo contiene todos los registros, justificaciones y horario del periodo | A4, R-08 |

## 4. Reglas de negocio (RN)

| ID | Regla | Estado |
|---|---|---|
| RN-001 | Situaciones válidas: Presente, Retardo, Suplente, Grupo sin alumnos, Sin docente, Clase no programada | C |
| RN-002 | Tolerancia desde el inicio de la clase: **0–15 min a tiempo · 16–30 min retardo · > 30 min falta** | C |
| RN-003 | Si al pasar el encargado el docente no está, se marca "aún no llega". Si llega después, la situación se calcula con la hora de esa segunda observación. Si al minuto 30 no hay registro de llegada, se convierte en **Sin docente (falta)** | C |
| RN-004 | El docente puede justificar dentro de **3 días hábiles** contados desde el día siguiente al registro. Días hábiles: lunes a viernes, excluyendo días inhábiles del periodo | C (forma de conteo S) |
| RN-005 | Solo Coordinación aprueba o rechaza justificaciones. Un registro justificado aparece en reportes como "Justificado" y no cuenta como falta o retardo | C |
| RN-006 | Existe un solo registro por aula, fecha y bloque horario | S |
| RN-007 | El docente esperado se toma del horario oficial. "Suplente" exige el nombre del suplente | C |
| RN-008 | Los registros **nunca se borran**. Toda corrección conserva el valor anterior en la bitácora | A5 |
| RN-009 | El encargado puede corregir un registro solo mientras dure el bloque de clase; después, solo Coordinación y con motivo | S |
| RN-010 | Cada docente solo puede ver sus propios registros y justificaciones | C |
| RN-011 | El horario no admite traslapes: un aula no puede tener dos clases a la misma hora, ni un docente estar en dos aulas a la vez | C |
| RN-012 | Se pasa lista **por cada hora** de clase: una clase de 2 h genera 2 registros | C |
| RN-013 | "Grupo sin alumnos" significa que el docente sí está pero no hay alumnos; **no cuenta como falta** del docente | C |
| RN-014 | Turnos: matutino 7:00–14:00, vespertino 14:00–21:00 | C |

## 5. Requisitos no funcionales (RNF)

| ID | Categoría | Requisito | Criterio de aceptación | Origen |
|---|---|---|---|---|
| RNF-001 | Disponibilidad sin conexión | La app del encargado funciona completa sin internet durante un turno entero | Prueba: modo avión durante 7 h de registros sin pérdida de datos | A1, R-02 |
| RNF-002 | Sincronización | Los registros pendientes se envían automáticamente al recuperar conexión | Enviados en ≤ 5 min tras recuperar señal | A1 |
| RNF-003 | Rendimiento | Registrar un aula en ≤ 3 toques y ≤ 10 s | Medido en prueba con el encargado | M1 |
| RNF-004 | Rendimiento | Reporte diario o semanal generado en < 1 min | Medido con datos de una semana (~2 800 registros) | M2 |
| RNF-005 | Seguridad | Contraseñas almacenadas solo como hash seguro, nunca en texto plano | Revisión de la base de datos | — |
| RNF-006 | Seguridad | Toda comunicación cifrada (HTTPS) | Sin endpoints HTTP | — |
| RNF-007 | Seguridad | Los permisos por rol se validan en el servidor, no solo en la interfaz | Prueba: un DOC no puede leer registros de otro docente ni con peticiones directas | RN-010, R-05 |
| RNF-008 | Integridad | Cada registro guarda hora del dispositivo y hora del servidor al sincronizar; diferencias > 5 min se marcan | Prueba con reloj del celular alterado | R-11 |
| RNF-009 | Auditoría | La bitácora no puede modificarse ni borrarse por ningún rol | Prueba de intento de modificación | A5, R-04 |
| RNF-010 | Privacidad | Aviso de privacidad visible para docentes; solo se recaban datos necesarios | Aviso aprobado por el área de transparencia antes de producción | A6, R-05 |
| RNF-011 | Compatibilidad | App en Android 10 o superior (S); web en versiones actuales de Chrome, Edge, Firefox y Safari | Prueba en al menos 1 Android y 2 navegadores | A2 |
| RNF-012 | Usabilidad | Interfaz en español, botones grandes, uso con una sola mano en la app | Encargado completa un recorrido sin ayuda tras 10 min de capacitación | — |
| RNF-013 | Accesibilidad | Contraste suficiente y texto legible; la situación no se distingue solo por color | Revisión de contraste | — |
| RNF-014 | Respaldo | Respaldo exportable al menos semanal; la restauración se verifica | Restauración probada en entorno aislado | A4 |
| RNF-015 | Costo | Operación con servicios gratuitos ($0) | Sin cargos durante la operación del MVP | A4 |
| RNF-016 | Capacidad | Soportar ≥ 600 registros/día y 1 periodo completo de datos dentro de límites gratuitos | Cálculo de consumo en Etapa 5 | — |
| RNF-017 | Mantenibilidad | Lógica de negocio con pruebas automatizadas | Reglas RN-002 a RN-006 cubiertas por pruebas | Principio 4 |
| RNF-018 | Retención | Los datos se conservan el tiempo que indique la normativa institucional | (P) definir con el área de transparencia | A6 |
| RNF-019 | Privacidad | Los adjuntos de justificaciones (posibles datos sensibles, p. ej. médicos) solo los ven el docente que los subió y Coordinación | Prueba: otro docente no puede abrir el adjunto ni con el enlace directo | R-05 |
| RNF-020 | Capacidad | El almacenamiento de adjuntos cabe en el plan gratuito durante un periodo | Cálculo en Etapa 5 (estimado: 40 docentes × pocas justificaciones × ≤ 5 MB) | RES-03 |

## 6. Restricciones

| ID | Restricción |
|---|---|
| RES-01 | Un desarrollador con apoyo de IA |
| RES-02 | Primera versión funcional en 2–3 meses |
| RES-03 | Presupuesto $0: solo servicios gratuitos |
| RES-04 | Encargado con celular Android; docentes y Coordinación por web |
| RES-05 | Horario por plantilla Excel/CSV (sin integración con el sistema escolar en esta versión) |
| RES-06 | No usar en producción sin aviso de privacidad y autorización institucional |

## 7. Escenarios excepcionales

| ID | Escenario | Comportamiento esperado | Requisitos |
|---|---|---|---|
| E-01 | Sin señal durante el recorrido | Registra localmente y sincroniza después | RF-021, RNF-001 |
| E-02 | Se agota la batería o se cierra la app con registros sin enviar | Los registros guardados se conservan y se envían al reabrir | RF-021 |
| E-03 | Aula ocupada sin clase programada | Se registra como "Clase no programada" | RF-020 |
| E-04 | Está otro docente en lugar del esperado | Se registra como Suplente con su nombre | RF-016 |
| E-05 | Clase cancelada o día inhábil | El aula no aparece por revisar | RF-007 |
| E-06 | La clase se cambió de aula sin actualizar el horario | Se registra "Sin docente" en el aula original con observación; Coordinación corrige con motivo | RF-017, RF-031 |
| E-07 | Archivo de horario con errores | No se importa; se muestra la lista de errores | RF-011 |
| E-08 | Justificación fuera de plazo | No se permite enviar | RF-025 |
| E-09 | Dos registros de la misma aula y bloque (p. ej. al sincronizar) | Se conserva el primero y el segundo queda como corrección en bitácora | RN-006 |
| E-10 | Reloj del celular incorrecto | Se marca la diferencia con la hora del servidor | RNF-008 |
| E-11 | La app falla durante un recorrido | Contingencia: libreta y captura posterior por Coordinación marcada como "manual" | RF-031, A7 |
| E-12 | El encargado está ausente | Coordinación asigna el rol ENC a otra persona | RF-004 |

## 8. Trazabilidad problema → requisitos

| Problema (01_CONTEXTO) | Requisitos que lo atienden |
|---|---|
| P1 Anotación manual lenta | RF-013, RF-014, RF-019, RNF-003 |
| P2 Nombre de memoria | RF-009, RF-013 |
| P3 Hora no verificable | RF-015, RNF-008 |
| P4 Falta sin docente identificado | RF-010, RF-013 |
| P5 Situaciones en texto libre | RF-014, RN-001 |
| P6 Libreta como único respaldo | RF-021, RF-033, RNF-014 |
| P7 Reporte por transcripción | RF-028, RF-029, RNF-004 |
| P8 Sin canal de justificación | RF-023 a RF-027 |
| P9 Sin histórico | RF-029, RF-030 |

## 9. Ambigüedades a validar con el encargado y Coordinación

| # | Ambigüedad | Resolución |
|---|---|---|
| 1 | RN-003 — Cómo determinar el retardo | ✅ Marcar "aún no llega" y volver a pasar |
| 2 | RN-012 — Clase de 2 h | ✅ Un registro por cada hora |
| 3 | RN-013 — "Grupo sin alumnos" | ✅ Docente presente sin alumnos; no es falta |
| 4 | RF-025 — Adjuntos en justificaciones | ✅ Sí: imagen o PDF opcional, máx. 5 MB (se agregan RNF-019 y RNF-020) |
| 5 | RN-009 — Plazo de corrección del encargado | Supuesto aceptado: durante el bloque de clase; validar con el encargado |
| 6 | RNF-018 — Retención de datos | Pendiente con el área de transparencia; no bloquea el MVP |

## 10. Criterios de salida de la Etapa 3

- [x] Requisitos funcionales con ID y criterio de aceptación
- [x] Requisitos no funcionales con ID y criterio medible
- [x] Reglas de negocio identificadas
- [x] Restricciones documentadas
- [x] Roles y permisos definidos
- [x] Escenarios excepcionales documentados
- [x] Trazabilidad con el problema
- [x] Ambigüedades de §9 resueltas (2 con supuesto o pendiente que no bloquea)
- [~] **Validación con el encargado y Coordinación** → **excepción documentada (§11)**
- [x] Aprobación del desarrollador responsable

## 11. Cierre de etapa

**Resultado:** Etapa 3 cerrada con excepción.

**Excepción aprobada:** la validación de requisitos con el encargado de recorridos y Coordinación académica no se realizó en esta etapa. El desarrollador responsable aprueba los requisitos y traslada la validación a la **Etapa 7 (prototipo con usuarios representativos)** y, como máximo, a la **Etapa 17 (aceptación con usuarios)**.

**Riesgo asociado (R-14):** un requisito mal entendido se detectaría tarde. **Mitigación:** validar el prototipo de la Etapa 7 con el encargado y Coordinación; cualquier cambio vuelve a esta etapa como solicitud de cambio.

**Supuestos vigentes:** RN-009 (corrección durante el bloque de clase); RNF-011 (Android 10+).
**Pendientes no bloqueantes:** RNF-018 (retención, con el área de transparencia).

**Versión del documento:** 2 · **Aprobó:** desarrollador responsable · 2026-11-10
