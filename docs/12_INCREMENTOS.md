# 12_INCREMENTOS — Registro de incrementos

**Metodología:** MIDE-IA 2.0 · Ciclo III · Etapas 12 y 13
Evidencia de cada incremento según la definición de terminado (09_ROADMAP §4).

---

## I1 — Acceso y roles

**Rama:** `incremento/I1-acceso` · **Fecha:** 2026-11-19 · **Estado:** Terminado — pendiente de PR y prueba manual PM-03

### Requisitos cubiertos

| Requisito | Cómo se cumple |
|---|---|
| RF-001 Iniciar sesión | Pantalla Entrar (M-01/W-01), mensaje genérico ante credenciales inválidas |
| RF-002 Cerrar sesión | Botón en todas las pantallas con sesión; regresa a Entrar |
| RF-004 Gestionar usuarios | Pestaña Usuarios (W-06): pre-registro, cancelar pre-registro, activar/desactivar |
| RF-005 Sesión persistente | Firebase Auth conserva la sesión en el dispositivo |
| RNF-005 Contraseñas | Las gestiona Firebase Auth; la app valida la política C-01 |
| RNF-007 Permisos en servidor | Reglas de `usuarios` y `preregistros` con pruebas |
| C-04 Baja inmediata | La app escucha el perfil en vivo: al desactivarlo se muestra "cuenta desactivada" |
| C-21 (nuevo) Correo verificado | El primer acceso exige confirmar el correo antes de crear el perfil |

### Implementación

| Capa | Archivos |
|---|---|
| Dominio | `dominio/correo.dart`, `contrasena.dart`, `rol.dart`, `usuario.dart`, `sesion.dart`, `fallas.dart`, `repositorios/autenticacion_repositorio.dart`, `repositorios/usuario_repositorio.dart` |
| Datos | `datos/firebase_autenticacion_repositorio.dart`, `firestore_usuario_repositorio.dart`, `mapeadores.dart` |
| Aplicación | `modulos/autenticacion/aplicacion/destino.dart` (navegación por rol), `providers.dart`; `modulos/usuarios/aplicacion/providers.dart` |
| Presentación | Entrar, Primer acceso, Acceso no disponible, Cargando, Recorrido (marcador para I3), panel de Coordinación con pestaña Usuarios, Portal docente (marcador v1.1) |
| App | `app/router.dart` (go_router protegido por sesión), `app/mensajes.dart` (07_UX_UI §6), `app/localizacion.dart` (es-MX) |
| Seguridad | `firestore.rules`: `usuarios`, `preregistros`; todo lo demás denegado |
| Herramientas | `test_reglas/sembrar.mjs`: primer usuario de Coordinación y un pre-registro de encargado en el emulador |

### Pruebas

| ID | Descripción | Tipo | Resultado |
|---|---|---|---|
| PU-20 | Normalización y formato de correo | Unitaria | ✅ |
| PU-21 | Política de contraseñas (C-01) | Unitaria | ✅ |
| PU-22 | Conversión de rol desde código | Unitaria | ✅ |
| PU-23 | Navegación por rol y plataforma | Unitaria | ✅ |
| PW-01 | Pantalla Entrar: validaciones, mensajes de error, enlace a Primer acceso | Widget | ✅ |
| PW-04 | Apps: rol correcto a su pantalla, rol en plataforma equivocada, desactivación en vivo, cerrar sesión | Widget | ✅ |
| PR-01 | Sin sesión no se lee ni escribe | Reglas | ✅ |
| PR-02 | Coordinación desactivada pierde permisos | Reglas | ✅ |
| PR-03 | Perfil solo desde pre-registro, con su rol, correo confirmado y en el mismo lote (7 casos) | Reglas | ✅ |
| PR-04 | Solo Coordinación pre-registra; formato del ID; no sobrescribe; cancelar pendientes (5 casos) | Reglas | ✅ |
| PR-18 | Activar/desactivar: solo Coordinación y no a sí misma | Reglas | ✅ |
| PR-19 | Nadie cambia roles | Reglas | ✅ |
| PR-20 | Nadie borra usuarios | Reglas | ✅ |
| PR-21 | Cada quien lee solo su perfil; Coordinación lista todos | Reglas | ✅ |
| PR-22 | En el MVP no se pre-registran docentes | Reglas | ✅ |
| PM-03 | Flujo completo en el emulador (sustituye a PI-01, ver decisión D-2) | Manual | ⏳ Pendiente |

**Resultados ejecutados:** `flutter analyze` → No issues found · `flutter test` → 31/31 · `npm test` → 23/23 · `flutter build web` → correcto · `npm run prueba-sembrado` → correcto.

### Prueba manual PM-03 (flujo completo)

1. Terminal 1: `cd app/test_reglas && npm run emuladores`
2. Terminal 2: `cd app/test_reglas && npm run sembrar`
3. Terminal 3: `cd app && flutter run -d chrome -t lib/main_web.dart`
4. Entrar como `coordinacion@demo.edu.mx` / `Coordinacion2026` → aparece la pestaña **Usuarios**.
5. Pre-registrar `prueba@demo.edu.mx` como Encargado → aparece en "Pre-registros pendientes".
6. Cerrar sesión → **¿Primera vez? Crear mi contraseña** con `encargado@demo.edu.mx` y una contraseña válida.
7. En la terminal 1 aparece un enlace de verificación del emulador → abrirlo → volver a la app → **Continuar**.
8. Resultado esperado: "Tu cuenta es de encargado de recorridos: usa la app Android" (es la web).
9. Entrar otra vez como Coordinación → el encargado aparece **Activo**; desactivarlo → confirmar.
10. Intentar Primer acceso con un correo **no** pre-registrado → "Este correo no está pre-registrado…".

Registrar aquí el resultado: ⏳

### Decisiones y hallazgos

| ID | Decisión | Motivo |
|---|---|---|
| D-1 | **Nuevo control C-21:** el primer acceso exige confirmar el correo | Sin esto, quien conociera un correo pre-registrado podría crear la cuenta antes que la persona real y obtener su rol. Se agregó la amenaza A-16 a 08_SEGURIDAD_CONTINUIDAD |
| D-2 | PI-01 se ejecuta como prueba manual guiada (PM-03) | Las pruebas de integración de Flutter contra el emulador requieren un dispositivo o navegador controlado; se automatizarán cuando el Android SDK esté completo. Los permisos ya están cubiertos por PR-01 a PR-22 |
| D-3 | Docentes no se pueden pre-registrar en el MVP | Su portal es v1.1 (EP7); se habilita junto con `docenteId` |
| D-4 | Se agregó `flutter_localizations` (SDK de Flutter) | Textos del sistema (calendarios, diálogos) en español (RNF-012) |
| D-5 | Una cuenta creada sin pre-registro se elimina de inmediato | Evita cuentas huérfanas en Firebase Auth |

### Limitaciones conocidas

- En producción, al desactivar a alguien también hay que **deshabilitar su cuenta en la consola de Firebase** (C-04); la app ya le bloquea el acceso a los datos de inmediato.
- La política de contraseñas también debe configurarse en la consola de Firebase en producción (Etapa 18).
- La app Android no se ha compilado en este equipo: falta Android SDK Command-line Tools (ver README).

---

## I2 a I6 — Horario, recorrido, sin conexión, bitácora y reportes (MVP completo)

**Rama:** `mvp/I2-I6` · **Fecha:** 2026-11-19 · **Estado:** Terminado — pendiente de PR, prueba manual PM-04 y validación con usuarios

### Excepciones al proceso (aprobadas por el desarrollador responsable para la presentación del 2026-11-19)

| # | Excepción | Riesgo | Cómo se salda |
|---|---|---|---|
| E-1 | **No se hizo la puerta de validación del prototipo antes de I3** (3.ª vez que se pospone la validación con usuarios) | R-14 alto: un requisito mal entendido llegó al código | Validar el MVP funcionando con el encargado y Coordinación en la **Etapa 17**, antes de producción. Cualquier hallazgo vuelve a la Etapa 3 |
| E-2 | I2–I6 se construyeron en **una sola rama** en vez de una por incremento (10_ESTANDARES §11.1) | Revisión de un PR grande | El PR se revisa por secciones (este documento las separa) |
| E-3 | Las pruebas de integración contra el emulador (PI-02 a PI-08) se sustituyen por la **prueba manual guiada PM-04** ([GUIA_DEMO.md](GUIA_DEMO.md)) + pruebas de widgets con repositorios falsos | Errores de integración con Firebase solo se detectan manualmente | Automatizarlas cuando el Android SDK esté completo (Etapa 14) |

### Requisitos cubiertos

| Incremento | Requisitos | Implementación principal |
|---|---|---|
| **I2** Horario | RF-006, RF-008, RF-009, RF-010, RF-011 · RN-011, RN-014 · C-13 | `dominio/horario.dart` (validación), `lector_archivo.dart` (.xlsx/.csv, 2 MB), importación versionada en `datos/firestore_horario_repositorio.dart`, pestaña **Horario** |
| **I3** Recorrido | RF-013 a RF-019, RF-022 · RN-001 a RN-003, RN-006, RN-007, RN-009, RN-012, RN-013 · C-08, C-09, C-11 | `dominio/situacion.dart`, `registro.dart`, `tiempo.dart`; `datos/firestore_registro_repositorio.dart` (lote registro + bitácora); pantalla **Recorrido** y panel de registro |
| **I4** Sin conexión | RF-021 · RNF-001, RNF-002, RNF-008 · C-10 | Memoria local de Firestore (también en web), indicador "Sin conexión · N por enviar" y "N registros enviados", medición del desfase del reloj y marca "Hora dudosa" |
| **I5** Consulta y bitácora | RF-030, RF-031, RF-032 · RN-008 · RNF-009 | Pestañas **Hoy** y **Registros** (filtros combinables), detalle con bitácora y corrección con motivo obligatorio |
| **I6** Reportes y respaldo | RF-028, RF-029, RF-033 · RNF-004, RNF-014 · C-14 | Reporte diario y semanal en **PDF y Excel** (totales por docente), neutralización de fórmulas, **respaldo .zip** con un CSV por colección; pestaña **Reportes** |

### Pruebas

| ID | Descripción | Resultado |
|---|---|---|
| PU-01 a PU-06 | Validación del horario: traslapes de aula y docente, turnos, filas inválidas, columnas faltantes, límites | ✅ |
| PU-07 a PU-11 | Situación efectiva: 0–15 a tiempo, 16–30 retardo, > 30 falta, "aún no llega", sin alumnos | ✅ |
| PU-12, PU-13 | Clase de 2 h = 2 bloques; ID determinista | ✅ |
| PU-14 | Hora dudosa: desfase > 5 min, registros sin conexión no son dudosos | ✅ |
| PU-15 a PU-17 | Totales por docente, neutralización de fórmulas, justificado no cuenta | ✅ |
| PW-02 | Recorrido: bloque actual, registro con un toque, suplente exige nombre, "aún no llega" → retardo, estados vacíos | ✅ |
| PW-05 | Lector de archivos: demo válido (480 clases), archivo con errores, Excel con números y horas, límites, plantilla | ✅ |
| PW-06 | Reportes: Excel con totales y celdas neutralizadas, PDF con acentos, respaldo .zip | ✅ |
| PR-05 | Solo Coordinación escribe horario; clases solo en importación en carga; lote de 400 clases | ✅ |
| PR-06 a PR-14 | Registros y bitácora: sin borrar, sin bitácora rechazado, versión +1, inmutables, fecha antigua, suplente, corrección del encargado solo el mismo día, Coordinación con motivo, lectura del encargado limitada | ✅ |
| PM-04 | Demostración completa en el emulador ([GUIA_DEMO.md](GUIA_DEMO.md)) | ⏳ |

**Resultados ejecutados:** `flutter analyze` → No issues found · `flutter test` → **72/72** · `npm test` → **42/42** · `flutter build web` (app del encargado y web de Coordinación) → correcto · `npm run prueba-sembrado` → correcto.

### Defectos encontrados por las pruebas y corregidos

| Defecto | Corrección |
|---|---|
| Los botones de situación se desbordaban en celulares angostos o con letra grande | Texto adaptable de hasta 2 líneas (RNF-012) |
| La previsión "quedará como Retardo" podía calcularse con una hora de hasta 20 s de antigüedad | El panel usa la hora exacta del reloj |

### Cambios al modelo de datos (06_MODELO_DATOS)

| Cambio | Motivo |
|---|---|
| `registros.actualizadoEn` (hora del servidor de la última escritura) | Las reglas verifican la hora de cada cambio |
| `bitacora.usuarioNombre` | La bitácora es legible sin cruzar con `usuarios` |
| Colección `sincronizacion/{uid}` con un solo campo `ping` | Medir el desfase del reloj (RNF-008) |

### Decisiones

| ID | Decisión |
|---|---|
| D-6 | Zona horaria fija UTC−6 (México sin horario de verano desde 2022) |
| D-7 | El encargado ve solo el **bloque actual**; para demostraciones fuera de horario existe `--dart-define=HORA_DEMO=09:05`, que desplaza el reloj (los registros quedan marcados como "hora dudosa", que es el comportamiento correcto) |
| D-8 | El respaldo neutraliza fórmulas en los CSV; el script de restauración deberá quitar el apóstrofo inicial |

### Pendientes

- `tool/restaurar.dart` (restauración desde el respaldo) y su prueba en entorno aislado → Etapa 16.
- Compilar y probar la app en un celular Android real (falta Android SDK Command-line Tools).
- Validación con usuarios (E-1) → Etapa 17.
