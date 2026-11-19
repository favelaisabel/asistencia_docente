# 09_ROADMAP — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo II · Etapa 9
**Versión:** 1 · **Fecha:** 2026-11-18 · **Estado:** Cerrada
**Entradas:** [03_REQUISITOS.md](03_REQUISITOS.md) v2 · [04_ALCANCE_MVP.md](04_ALCANCE_MVP.md) v2 · [05_ARQUITECTURA.md](05_ARQUITECTURA.md) · [06_MODELO_DATOS.md](06_MODELO_DATOS.md) · [07_UX_UI.md](07_UX_UI.md) · [08_SEGURIDAD_CONTINUIDAD.md](08_SEGURIDAD_CONTINUIDAD.md)

---

## 1. Objetivo de la etapa

Dividir la construcción en incrementos pequeños, cada uno con requisitos, dependencias, tareas, criterios de aceptación, pruebas y evidencias, y trazar cada requisito hasta su implementación y su prueba.

## 2. Estrategia

- **Primero el MVP a producción, después la v1.1.** La v1.1 pasa por el mismo ciclo de calidad una vez que el MVP opera (cumple RES-02: primera versión funcional en 2–3 meses). Reemplaza el calendario de 04_ALCANCE_MVP §4.
- **Incrementos de 1–2 semanas**, cada uno termina con software que funciona y está probado (Etapa 12).
- **Lo más riesgoso primero:** reglas de seguridad desde el Incremento 1; reglas de negocio con pruebas antes que las pantallas (TDD en el dominio).
- **Revisión semanal del avance** (R-07): si un incremento se retrasa más de 3 días, se replanifica y se recorta la v1.1, nunca el MVP.

## 3. Calendario

Semana 1 = la semana en que inicia la Etapa 10. Las fechas reales se fijan al iniciar; los periodos vacacionales no cuentan como semanas de trabajo (S).

| Semana | Incremento | Contenido | Etapas MIDE-IA |
|:-:|---|---|---|
| 1 | **I0** Entorno y estándares | Repositorio, proyecto Flutter, Firebase (desarrollo + emulador), CI, estándares, AGENTS.md | 10, 11 |
| 2 | **I1** Acceso y roles | EP1 | 12, 13 |
| 3–4 | **I2** Horario y catálogos | EP2 | 12, 13 |
| — | 🚦 **Puerta: validación del prototipo con usuarios** | Condición de la Etapa 7 | 7 |
| 5–6 | **I3** Recorrido y registro | EP3 | 12, 13 |
| 7 | **I4** Sin conexión e integridad | EP4 + parte de EP5 | 12, 13 |
| 8 | **I5** Consulta, corrección y bitácora | EP5 | 12, 13 |
| 9–10 | **I6** Reportes y respaldo | EP6 | 12, 13 |
| 11 | **Validación del MVP** | QA consolidado, seguridad, rendimiento, recuperación, aceptación | 14, 15, 16, 17 |
| 12 | **Despliegue v1.0** | Producción, pruebas de humo, operación | 18, 19 |
| 13–14 | **I7** Portal docente y justificaciones | EP7 (decidir ADR-008 antes) | 12, 13 |
| 15 | **I8** Administración complementaria | EP8 | 12, 13 |
| 16 | **Validación y despliegue v1.1** | | 14–19 |

**MVP en producción: semana 12 (~3 meses).** v1.1: semana 16.

## 4. Definición de terminado (aplica a todos los incrementos)

Un incremento está **terminado** solo si:

1. Cumple los criterios de aceptación de sus requisitos (03_REQUISITOS).
2. Las reglas de negocio nuevas tienen pruebas unitarias que pasan.
3. Los permisos nuevos tienen pruebas de reglas en el emulador que pasan.
4. `flutter analyze` sin errores ni advertencias; código formateado.
5. Todas las pruebas anteriores siguen pasando (sin regresiones).
6. Cambios revisados (autorrevisión con lista de la Etapa 11 + revisión asistida por IA) e integrados en `main` con CI en verde.
7. Documentación actualizada (README, decisiones nuevas, limitaciones conocidas).
8. Evidencia registrada en la sección del incremento en `docs/12_INCREMENTOS.md` (se crea en la Etapa 12).

## 5. Detalle de incrementos

Prefijos de pruebas: **PU** unitaria (dominio) · **PR** reglas de seguridad (emulador) · **PW** widget/pantalla · **PI** integración/extremo a extremo · **PM** manual guiada.

### I0 — Entorno y estándares (semana 1)

| Campo | Contenido |
|---|---|
| Requisitos | Prerrequisitos técnicos; RNF-017 |
| Depende de | Etapas 1–9 cerradas |
| Tareas | Repositorio Git · `flutter create` con entradas `main_movil.dart` y `main_web.dart` · estructura de carpetas (05 §9) · proyecto Firebase de desarrollo · Firebase CLI y emulador · `.gitignore` y `.env.example` · análisis estático estricto · CI (análisis + pruebas) · README de instalación · 10_ESTANDARES.md y AGENTS.md |
| Aceptación | Otra persona clona, configura, ejecuta la app (Android y web contra el emulador) y corre las pruebas siguiendo solo el README |
| Pruebas | Prueba de humo: la app arranca en ambas plataformas; CI en verde con una prueba de ejemplo |
| Evidencia | Repositorio, README, ejecución de CI |

### I1 — Acceso y roles (semana 2)

| Campo | Contenido |
|---|---|
| Requisitos | RF-001, RF-002, RF-004, RF-005 · RNF-005, RNF-006, RNF-007 · C-01 a C-06 |
| Depende de | I0 |
| Tareas | Pantallas de inicio de sesión (M-01, W-01) · pre-registro y alta del perfil (ADR-005) · navegación por rol (go_router) · pantalla Usuarios (W-06) · reglas base: denegar todo, perfil activo y rol · procedimiento para crear el primer COO |
| Aceptación | Cada rol entra a su pantalla; credenciales inválidas → mensaje genérico; usuario desactivado no entra; un usuario no puede asignarse otro rol |
| Pruebas | PR-01 sin sesión no lee nada · PR-02 inactivo bloqueado · PR-03 perfil solo con rol pre-registrado · PR-04 solo COO pre-registra · PW-01 formulario de inicio de sesión · PI-01 flujo pre-registro → primer inicio |
| Evidencia | Resultados de pruebas; capturas de cada rol |

### I2 — Horario y catálogos (semanas 3–4)

| Campo | Contenido |
|---|---|
| Requisitos | RF-006, RF-008, RF-009, RF-010, RF-011 · RN-011, RN-014 · C-13 |
| Depende de | I1 |
| Tareas | `ValidadorHorario` con TDD · plantilla descargable · lectura de Excel/CSV · tabla de errores por fila · importación versionada (06 §7.2) · periodo activo (`config/sistema`) · catálogos de aulas y docentes desde la importación · reglas de escritura solo COO · datos ficticios: 40 aulas, 40 docentes, ~1 500 clases |
| Aceptación | Archivo válido → horario activo; archivo con cualquier error → nada se guarda y se listan errores; una falla a mitad de carga deja vigente el horario anterior |
| Pruebas | PU-01 traslape de aula · PU-02 traslape de docente · PU-03 hora fuera de turno · PU-04 aula/docente inexistente · PU-05 columnas faltantes · PU-06 archivo > 2 MB · PR-05 solo COO escribe horario · PI-02 importar y activar · PI-03 falla a mitad → horario anterior vigente |
| Evidencia | Archivo de prueba con errores y su resultado; horario de ejemplo activo |

### 🚦 Puerta: validación del prototipo (antes de I3)

Ejecutar el guion de 07_UX_UI §10 con el encargado y Coordinación. Observaciones que cambien requisitos → solicitud de cambio y regreso a la Etapa 3. **I3 no inicia sin esta validación** (excepción de la Etapa 7).

### I3 — Recorrido y registro (semanas 5–6)

| Campo | Contenido |
|---|---|
| Requisitos | RF-013 a RF-019, RF-022 · RN-001 a RN-003, RN-006, RN-007, RN-009, RN-012, RN-013 · RNF-003, RNF-012, RNF-013 · C-08, C-09, C-11 |
| Depende de | I2 · puerta de validación |
| Tareas | `CalculadoraSituacion` con TDD · bloques por hora (una clase de 2 h = 2 bloques) · pantalla de recorrido (M-02) con avance y filtro · panel de registro (M-03, M-04, M-05) · lote registro + bitácora con ID determinista · corrección dentro del bloque · reglas de `registros` y `bitacora` (08 §5.1) |
| Aceptación | Registrar un aula en ≤ 3 toques; "aún no llega" → llegada calcula la situación correcta; suplente exige nombre; cada escritura tiene su bitácora |
| Pruebas | PU-07 0–15 min = a tiempo · PU-08 16–30 = retardo · PU-09 > 30 = falta · PU-10 sin llegada tras min 30 = falta · PU-11 sin alumnos ≠ falta · PU-12 clase de 2 h = 2 bloques · PU-13 ID determinista · PR-06 nadie borra registros · PR-07 registro sin bitácora rechazado · PR-08 versión debe aumentar en 1 · PR-09 bitácora inmodificable · PR-10 fecha > 2 días atrás rechazada · PR-11 suplente sin nombre rechazado · PW-02 panel de registro · PM-01 recorrido de 40 aulas cronometrado |
| Evidencia | Pruebas; tiempo medido por aula (M1) |

### I4 — Sin conexión e integridad (semana 7)

| Campo | Contenido |
|---|---|
| Requisitos | RF-021 · RNF-001, RNF-002, RNF-008 · C-10 · §5.2 de 08 |
| Depende de | I3 |
| Tareas | Persistencia local y precarga del horario del día · indicador "Sin conexión · N por enviar" y "N registros enviados" · medición de desfase del reloj · marca "Hora dudosa" · tolerancia de corrección hasta fin de día en reglas |
| Aceptación | Un turno completo en modo avión sin pérdida; envío ≤ 5 min tras recuperar señal; reinicio del celular con pendientes no pierde datos |
| Pruebas | PU-14 cálculo de hora dudosa · PR-12 corrección ENC al día siguiente rechazada · PI-04 modo avión 14 bloques → sincroniza · PI-05 reinicio con pendientes · PM-02 recorrido real sin señal en el edificio |
| Evidencia | Video o capturas del modo avión y la sincronización |

### I5 — Consulta, corrección y bitácora (semana 8)

| Campo | Contenido |
|---|---|
| Requisitos | RF-030, RF-031, RF-032 · RN-008 · RNF-009 |
| Depende de | I3 |
| Tareas | Pestañas Hoy y Registros (W-02, W-03) · filtros combinables · detalle con bitácora · corrección con motivo obligatorio · índices compuestos (06 §9) |
| Aceptación | Filtros combinados correctos; corrección sin motivo bloqueada; la bitácora muestra quién, qué, cuándo, antes y después |
| Pruebas | PR-13 corrección COO sin motivo rechazada · PR-14 ENC no lee registros de hace 3 días · PW-03 filtros · PI-06 corregir y ver bitácora |
| Evidencia | Pruebas; captura del historial de un registro |

### I6 — Reportes y respaldo (semanas 9–10)

| Campo | Contenido |
|---|---|
| Requisitos | RF-028, RF-029, RF-033 · RNF-004, RNF-014 · C-14 |
| Depende de | I5 |
| Tareas | Reporte diario y semanal en PDF y Excel (W-04) · totales por docente · neutralizar fórmulas en celdas · respaldo CSV completo · script de restauración (`tool/restaurar.dart`) |
| Aceptación | Reporte semanal con ~2 800 registros en < 1 min; totales correctos; respaldo contiene todo el periodo |
| Pruebas | PU-15 totales por docente · PU-16 celdas con `=`, `+`, `-`, `@` neutralizadas · PU-17 justificado no cuenta como falta (preparado para v1.1) · PI-07 reporte con datos de una semana · PI-08 respaldo → restauración en emulador |
| Evidencia | Archivos de reporte de ejemplo; tiempo medido (M2) |

**Al terminar I6:** demostración del criterio de MVP terminado (04 §6): 40 aulas, 14 recorridos en modo avión, sincronización sin pérdida, reportes correctos.

### I7 — Portal docente y justificaciones (semanas 13–14, v1.1)

| Campo | Contenido |
|---|---|
| Requisitos | RF-023 a RF-027 · RN-004, RN-005, RN-010 · RNF-019, RNF-020 · C-07 |
| Depende de | v1.0 en producción · ADR-008 decidida |
| Pruebas clave | PU-18 plazo de 3 días hábiles · PR-15 docente solo ve lo suyo · PR-16 adjunto solo dueño y COO · PR-17 justificación fuera de plazo rechazada |

### I8 — Administración complementaria (semana 15, v1.1)

| Campo | Contenido |
|---|---|
| Requisitos | RF-003, RF-007, RF-012, RF-020 |
| Depende de | I2 |
| Pruebas clave | PU-19 día inhábil sin aulas por revisar · PI-09 restablecer contraseña · PI-10 edición de horario no altera registros pasados |

## 6. Matriz de trazabilidad (MVP)

Requisito → incremento → implementación (módulo / componente) → pruebas.

| Requisito | Incr. | Implementación | Pruebas |
|---|:-:|---|---|
| RF-001 Iniciar sesión | I1 | `autenticacion` · AutenticacionRepositorio | PW-01, PI-01, PR-01 |
| RF-002 Cerrar sesión | I1 | `autenticacion` | PI-01 |
| RF-004 Gestionar usuarios | I1 | `usuarios` · UsuarioRepositorio · reglas `preregistros` | PR-03, PR-04, PI-01 |
| RF-005 Sesión persistente | I1 | `autenticacion` (Firebase Auth) | PI-05 |
| RF-006 Periodos | I2 | `horario` · `config/sistema` | PI-02 |
| RF-008 Aulas | I2 | `horario` · catálogo | PU-04, PI-02 |
| RF-009 Docentes | I2 | `horario` · catálogo | PU-04, PI-02 |
| RF-010 Importar horario | I2 | `horario` · importación versionada | PI-02, PI-03 |
| RF-011 Validar importación | I2 | `dominio` · ValidadorHorario | PU-01 a PU-06 |
| RF-013 Aulas del bloque | I3 | `recorrido` · HorarioRepositorio.clasesDelBloque | PU-12, PM-01 |
| RF-014 Registrar situación | I3 | `recorrido` · RegistroRepositorio.registrar | PW-02, PR-07, PM-01 |
| RF-015 Hora automática | I3 | `recorrido` · serverTimestamp | PR-07, PU-14 |
| RF-016 Suplente | I3 | `recorrido` · panel M-04 | PR-11, PW-02 |
| RF-017 Observación | I3 | `recorrido` | PW-02 |
| RF-018 Aún no llega / llegada | I3 | `dominio` · CalculadoraSituacion | PU-07 a PU-10 |
| RF-019 Avance del recorrido | I3 | `recorrido` · M-02 | PM-01 |
| RF-021 Sin conexión | I4 | Persistencia Firestore · indicador | PI-04, PI-05, PM-02 |
| RF-022 Corrección en bloque | I3 | `recorrido` · lote + bitácora | PR-08, PR-12 |
| RF-028 Reporte diario | I6 | `reportes` · ReporteServicio | PI-07, PU-16 |
| RF-029 Reporte semanal | I6 | `reportes` · ReporteServicio | PU-15, PI-07 |
| RF-030 Filtros | I5 | `bitacora`/Registros · índices | PW-03 |
| RF-031 Corrección COO | I5 | RegistroRepositorio.corregir | PR-13, PI-06 |
| RF-032 Bitácora | I5 | `bitacora` · BitacoraRepositorio | PR-09, PI-06 |
| RF-033 Respaldo CSV | I6 | `reportes` · exportación + `tool/restaurar.dart` | PI-08 |
| RN-001 Situaciones válidas | I3 | `dominio` · enumeración + reglas | PR-07 |
| RN-002 Tolerancias 15/30 | I3 | CalculadoraSituacion | PU-07, PU-08, PU-09 |
| RN-003 Aún no llega | I3 | CalculadoraSituacion | PU-10 |
| RN-006 Unicidad | I3 | ID determinista + reglas | PU-13 |
| RN-007 Docente esperado / suplente | I3 | Desnormalización + reglas | PR-11 |
| RN-008 Nunca borrar | I3 | Reglas | PR-06, PR-09 |
| RN-009 Corrección ENC | I3, I4 | App + reglas (08 §5.2) | PR-12 |
| RN-010 Docente ve lo suyo | I7 | Reglas | PR-15 |
| RN-011 Sin traslapes | I2 | ValidadorHorario | PU-01, PU-02 |
| RN-012 Un registro por hora | I3 | Bloques por hora | PU-12 |
| RN-013 Sin alumnos ≠ falta | I3 | CalculadoraSituacion | PU-11 |
| RN-014 Turnos | I2 | ValidadorHorario | PU-03 |
| RNF-001/002 Sin conexión | I4 | ADR-003 | PI-04, PI-05, PM-02 |
| RNF-003 ≤ 3 toques / 10 s | I3 | Diseño M-03 | PM-01 |
| RNF-004 Reporte < 1 min | I6 | ADR-007 | PI-07 |
| RNF-005/006 Contraseñas / HTTPS | I1 | Firebase Auth / Hosting | Revisión Etapa 15 |
| RNF-007 Permisos en servidor | I1–I5 | Reglas | PR-01 a PR-14 |
| RNF-008 Hora verificable | I4 | Desfase de reloj | PU-14 |
| RNF-009 Bitácora inmutable | I3 | Reglas | PR-09 |
| RNF-011 Compatibilidad | I0–I6 | Android 10+ / navegadores | Etapa 14 |
| RNF-012/013 Usabilidad / accesibilidad | I3, I5 | 07_UX_UI §5, §8 | Etapa 14 + aceptación |
| RNF-014 Respaldo | I6 | Respaldo CSV | PI-08, Etapa 16 |
| RNF-015/016 Costo / capacidad | I0–I6 | Plan gratuito | Monitoreo de cuotas, Etapa 16 |
| RNF-017 Pruebas | Todos | Dominio en Dart puro | CI |

Esta matriz se mantiene viva: cada incremento actualiza la columna de pruebas con los nombres reales de los archivos de prueba.

## 7. Riesgos del plan

| ID | Riesgo | Mitigación |
|---|---|---|
| R-07 | Retraso del MVP | Revisión semanal; v1.1 como holgura; incrementos ≤ 2 semanas |
| R-14 | Prototipo no validado | Puerta obligatoria antes de I3 |
| R-21 | Curva de aprendizaje de reglas de seguridad y emulador | Reglas desde I1 (temprano) con pruebas; ejemplos guiados por IA |
| R-22 | Periodos vacacionales o carga escolar reducen semanas efectivas | Calendario en semanas de trabajo, no de calendario |

## 8. Evaluación de salida del Ciclo II (Diseño y planificación)

| Condición | Evidencia | Estado |
|---|---|---|
| Arquitectura y decisiones justificadas | 05_ARQUITECTURA, 05_ADR | ✅ |
| Modelo de datos con restricciones | 06_MODELO_DATOS | ✅ |
| Interfaces y prototipo | 07_UX_UI, prototipo | ✅ con excepción (validación antes de I3) |
| Seguridad, privacidad y continuidad | 08_SEGURIDAD_CONTINUIDAD | ✅ |
| Plan incremental y trazabilidad | 09_ROADMAP | ✅ |

**Decisión del ciclo:** ¿Diseño validado? → **SÍ, con excepción documentada** → se habilita el **Ciclo III: Construcción e implementación**.

## 9. Criterios de salida de la Etapa 9

- [x] Incrementos pequeños con requisitos asociados
- [x] Dependencias entre incrementos
- [x] Tareas por incremento
- [x] Criterios de aceptación por incremento
- [x] Pruebas y evidencias por incremento
- [x] Definición de terminado común
- [x] Matriz de trazabilidad requisito → implementación → prueba
- [x] Aprobación del desarrollador responsable · 2026-11-18

---

## 10. Actualizaciones de la matriz de trazabilidad

### I1 (2026-11-19)

| Requisito | Implementación real | Pruebas reales |
|---|---|---|
| RF-001 | `modulos/autenticacion/presentacion/entrar_pantalla.dart`, `datos/firebase_autenticacion_repositorio.dart` | PW-01 (`test/modulos/autenticacion/entrar_pantalla_test.dart`), PM-03 |
| RF-002 | `componentes.dart` (BotonCerrarSesion) | PW-04 (`test/app_test.dart`) |
| RF-004 | `modulos/usuarios/`, `datos/firestore_usuario_repositorio.dart`, reglas `usuarios` y `preregistros` | PR-02, PR-03, PR-04, PR-18 a PR-22 (`test_reglas/acceso.test.js`), PM-03 |
| RF-005 | Firebase Auth (sesión persistente) | PM-03 |
| C-01 | `dominio/contrasena.dart` | PU-21 (`test/dominio/acceso_test.dart`) |
| C-21 | `firestore.rules` (`creaPerfilDesdePreregistro`) | PR-03 |
| Navegación por rol | `modulos/autenticacion/aplicacion/destino.dart`, `app/router.dart` | PU-23 (`test/modulos/autenticacion/destino_test.dart`), PW-04 |

Nuevos IDs de prueba: PU-20 a PU-23, PW-04, PR-18 a PR-22, PM-03. PI-01 se sustituye por PM-03 (12_INCREMENTOS, D-2).

### I2–I6 (2026-11-19)

| Requisito | Implementación real | Pruebas reales |
|---|---|---|
| RF-006, RF-008 a RF-011 | `dominio/horario.dart`, `modulos/horario/`, `datos/firestore_horario_repositorio.dart` | PU-01 a PU-06 (`test/dominio/horario_test.dart`), PW-05 (`test/modulos/horario/lector_archivo_test.dart`), PR-05 (`test_reglas/registro.test.js`) |
| RF-013 a RF-019, RF-022 | `modulos/recorrido/`, `datos/firestore_registro_repositorio.dart` | PU-07 a PU-13 (`test/dominio/situacion_test.dart`), PW-02 (`test/modulos/recorrido/recorrido_pantalla_test.dart`), PR-06 a PR-12 |
| RF-021, RNF-001/002/008 | `app/firebase_config.dart` (persistencia), indicador de conexión, `medirDesfaseReloj` | PU-14, PM-04 |
| RF-030 a RF-032 | `modulos/bitacora/` (Hoy, Registros, detalle) | PR-09, PR-13, PR-14, PM-04 |
| RF-028, RF-029, RF-033 | `modulos/reportes/`, `datos/firestore_respaldo.dart` | PU-15 a PU-17, PW-06 (`test/modulos/reportes/generador_reportes_test.dart`), PM-04 |
