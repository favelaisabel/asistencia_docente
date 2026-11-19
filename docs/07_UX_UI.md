# 07_UX_UI — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo II · Etapa 7
**Versión:** 1 · **Fecha:** 2026-11-18 · **Estado:** Cerrada con excepción (ver §12)
**Entradas:** [03_REQUISITOS.md](03_REQUISITOS.md) v2 · [04_ALCANCE_MVP.md](04_ALCANCE_MVP.md) v1 · [06_MODELO_DATOS.md](06_MODELO_DATOS.md) v1
**Prototipo navegable:** https://claude.ai/artifact/CRTdu9PFcqWfqrejbkHQXi (privado hasta que se comparta desde el menú *Compartir*)

---

## 1. Objetivo de la etapa

Diseñar recorridos de usuario, navegación, formularios, validaciones, mensajes de error, estados vacíos y accesibilidad, y validar con usuarios representativos un prototipo en el que los procesos principales se completen con claridad.

## 2. Principios de diseño

| # | Principio | Por qué |
|---|---|---|
| D1 | **Un toque por aula** en el caso normal | M1: bajar de ~45 s a ≤ 15 s por aula (RNF-003) |
| D2 | **Nada se escribe** si el horario ya lo sabe | P2, P4: docente, materia y grupo precargados |
| D3 | **El estado de conexión siempre visible** | R-02: el encargado debe confiar en que nada se pierde |
| D4 | **Situación = icono + texto + color** | RNF-013: nunca solo color |
| D5 | **Botones grandes en la mitad inferior** | Uso con una mano mientras camina (RNF-012) |
| D6 | **Errores que dicen qué hacer** | Cada mensaje indica la causa y la acción |
| D7 | **Toda corrección deja rastro visible** | RN-008, RNF-009: confianza para las actas |

## 3. Recorridos de usuario

### F1 — Recorrido normal (Encargado, Android) · RF-013, RF-014, RF-019
1. Abre la app → ve el bloque actual (p. ej. 09:00–09:59) y las aulas pendientes.
2. Toca un aula → se abre el panel con el docente esperado.
3. Toca **Presente** → el aula pasa a "A tiempo" y sale de pendientes. (1 toque tras abrir)
4. Repite hasta que el contador muestra 40 de 40.

### F2 — Sin señal · RF-021, RNF-001
1. La app muestra **"Sin conexión · N por enviar"** en el encabezado.
2. El encargado registra igual que en F1.
3. Al recuperar señal: **"N registros enviados"** y el indicador vuelve a "En línea · todo enviado".

### F3 — Docente aún no llega · RF-018, RN-003
1. En el panel toca **Aún no llega** → el aula muestra "Aún no llega · min 12" y sigue en pendientes.
2. Si más tarde lo ve, toca el aula → **Ya llegó** → el sistema calcula A tiempo (≤ 15), Retardo (16–30) o Falta (> 30).
3. Si pasa el minuto 30 sin llegada → el aula muestra **Falta** automáticamente.

### F4 — Suplente · RF-016, RN-007
1. Toca **Suplente** → aparece el campo "Nombre del suplente".
2. Si intenta guardar vacío: *"Escribe el nombre del suplente para guardar."*
3. Guarda → el aula muestra "Suplente: <nombre>".

### F5 — Corrección durante la clase (Encargado) · RF-022, RN-009
1. Toca un aula ya registrada → el panel avisa *"Corregir este registro. El cambio queda en la bitácora."*
2. Elige la nueva situación.

### F6 — Importar horario (Coordinación, web) · RF-010, RF-011
1. Pestaña **Horario** → **Descargar plantilla**.
2. **Subir archivo** → la app valida.
3. Con errores: tabla con fila, columna y problema; *"No se guardó nada. Corrige el archivo y vuelve a subirlo."*
4. Sin errores: *"1 512 clases listas"* → **Activar horario**. El horario anterior sigue vigente hasta este paso.

### F7 — Reporte diario o semanal (Coordinación, web) · RF-028, RF-029
1. Pestaña **Reportes** → elige Diario/Semanal, fecha y formato (PDF/Excel).
2. **Generar** → se descarga el archivo; mensaje con el nombre del archivo.

### F8 — Corrección con motivo (Coordinación, web) · RF-031, RF-032
1. Pestaña **Registros** → filtra → selecciona un registro → ve su historial.
2. **Corregir** → nueva situación + **motivo obligatorio**.
3. Sin motivo: *"Escribe el motivo de la corrección."* Con motivo: se agrega una versión a la bitácora.

### F9 — Alta del encargado (Coordinación, web) · RF-004, ADR-005
1. Pestaña **Usuarios** → **Pre-registrar** con correo, nombre y rol.
2. La persona entra a la app, crea su contraseña y obtiene el rol pre-registrado.

## 4. Mapa de pantallas

### App Android (Encargado)

| ID | Pantalla | Contenido principal |
|---|---|---|
| M-01 | Inicio de sesión | Correo, contraseña, "Olvidé mi contraseña" (v1.1) |
| M-02 | Recorrido (pantalla principal) | Fecha, bloque, turno, indicador de conexión, avance (x de 40), filtro Pendientes/Todas, lista de aulas |
| M-03 | Panel de registro (hoja inferior) | Aula, docente, materia, grupo, hora automática, 6 botones de situación, observación opcional |
| M-04 | Panel de suplente | Campo de nombre + Guardar |
| M-05 | Panel de llegada | "Ya llegó" / "Cambiar situación" |
| M-06 | Ajustes | Registros por enviar, último envío, cerrar sesión |

### Web (Coordinación)

| ID | Pestaña | Contenido principal |
|---|---|---|
| W-01 | Inicio de sesión | Correo, contraseña |
| W-02 | Hoy | Resumen del día (registros, faltas, retardos, suplencias, horas dudosas) y últimos registros |
| W-03 | Registros | Filtros (fecha, turno, docente, aula, situación), tabla, detalle con bitácora y corrección |
| W-04 | Reportes | Tipo, fecha, formato, Generar |
| W-05 | Horario | Periodo activo, plantilla, importación con validación, activación |
| W-06 | Usuarios | Lista, pre-registro, desactivar |

## 5. Sistema visual

| Elemento | Definición |
|---|---|
| Tipografía | Inter (texto) · tamaños 14/16/20/24 px; mínimo 14 px en la app |
| Color base | Fondo #F5F6F8 · superficies blancas · texto #1B1F24 · acento #1F4FBF |
| Objetivos táctiles | ≥ 48 dp en la app; botones de situación ≥ 64 px de alto |

**Situaciones** (siempre con icono y texto; los colores difieren también en claridad):

| Situación | Color de texto | Fondo | Icono |
|---|---|---|---|
| A tiempo | #12663D | #E3F3EA | ✓ palomita |
| Retardo | #8A4B00 | #FCEFD9 | reloj |
| Falta | #A3221A | #FBE4E2 | ✕ |
| Suplente | #1F4FBF | #E4ECFB | persona |
| Sin alumnos | #4A525C | #ECEEF1 | grupo vacío |
| Aún no llega | #5B3BB0 | #EFEAFB | reloj de arena |
| Pendiente | #4A525C | blanco con borde | círculo vacío |

Todas las combinaciones de texto/fondo superan 4.5:1.

## 6. Validaciones y mensajes

| Situación | Mensaje | Requisito |
|---|---|---|
| Suplente sin nombre | "Escribe el nombre del suplente para guardar." | RF-016 |
| Observación > 250 caracteres | "La observación admite hasta 250 caracteres." | RF-017 |
| Credenciales inválidas | "Correo o contraseña incorrectos." (sin indicar cuál) | RF-001 |
| Usuario desactivado | "Tu cuenta está desactivada. Consulta a Coordinación." | RF-004 |
| Sin conexión | "Sin conexión · N por enviar" (informativo, no error) | RF-021 |
| Envío completado | "N registros enviados" | RF-021 |
| Importación con errores | "No se guardó nada. Corrige el archivo y vuelve a subirlo." + tabla de errores | RF-011 |
| Corrección sin motivo | "Escribe el motivo de la corrección." | RF-031 |
| Reporte sin datos | "No hay registros para esta fecha." | RF-028 |
| Hora dudosa | Etiqueta "Hora dudosa" con explicación al pasar el cursor | RNF-008 |

## 7. Estados vacíos y de carga

| Pantalla | Estado | Qué se muestra |
|---|---|---|
| M-02 | Fuera de horario (antes 7:00 / después 21:00) | "No hay clases en este momento. El siguiente bloque inicia a las 7:00." |
| M-02 | Todas las aulas registradas | "Recorrido completo · 40 de 40" |
| M-02 | Sin horario cargado | "Aún no hay horario activo. Avisa a Coordinación." |
| M-02 | Día inhábil (v1.1) | "Hoy es día inhábil." |
| W-03 | Filtros sin resultados | "No hay registros con estos filtros." + Limpiar filtros |
| Cualquiera | Cargando | Esqueleto de la lista, nunca pantalla en blanco |

## 8. Accesibilidad (RNF-013)

- Contraste de texto ≥ 4.5:1; situaciones con icono + texto.
- Botones y enlaces reales, navegables con teclado en la web; etiquetas en todos los campos.
- Texto escalable: la app respeta el tamaño de letra del sistema.
- Objetivos táctiles ≥ 48 dp; acciones principales en la mitad inferior de la pantalla.
- Mensajes de estado anunciados a lectores de pantalla.

## 9. Dispositivos

| Plataforma | Objetivo |
|---|---|
| Android | Teléfonos de 360–430 px de ancho, Android 10+ (RNF-011), orientación vertical |
| Web | Escritorio 1280 px+; usable en tableta y teléfono (columnas apiladas, tablas con desplazamiento) |

## 10. Validación del prototipo con usuarios

Esta validación salda la **excepción de la Etapa 3** (R-14).

### Guion de tareas

| # | Usuario | Tarea | Éxito si… |
|---|---|---|---|
| T1 | Encargado | Registrar 5 aulas como presentes | Lo hace sin ayuda, ≤ 15 s por aula |
| T2 | Encargado | Activar "Sin señal", registrar 2 aulas, volver a "En línea" | Entiende que los registros se enviaron |
| T3 | Encargado | Marcar "Aún no llega", avanzar 10 min y registrar la llegada | Entiende por qué salió Retardo o A tiempo |
| T4 | Encargado | Registrar un suplente | Escribe el nombre y guarda |
| T5 | Coordinación | Generar el reporte diario en Excel | Lo encuentra sin ayuda |
| T6 | Coordinación | Subir un horario con errores y luego uno correcto | Entiende los errores y activa el horario |
| T7 | Coordinación | Corregir un registro | Escribe el motivo y ve la bitácora |

### Preguntas de cierre

1. ¿Las situaciones (Presente, Aún no llega, Retardo, Suplente, Sin alumnos, Sin docente) cubren todo lo que ves en los recorridos?
2. ¿El cálculo de retardo y falta (15/30 min) es correcto?
3. ¿Falta algún dato en el reporte?
4. ¿Algo de lo que hoy anotas en la libreta no aparece aquí?

### Registro de resultados

| Tarea | Usuario | ¿Completó? | Tiempo | Observaciones |
|---|---|---|---|---|
| T1–T7 | | | | |

Cada observación que cambie un requisito se registra como **solicitud de cambio** y vuelve a la Etapa 3.

## 11. Criterios de salida de la Etapa 7

- [x] Recorridos de usuario definidos para los procesos del MVP
- [x] Navegación y mapa de pantallas
- [x] Formularios, validaciones y mensajes de error
- [x] Estados vacíos y de carga
- [x] Accesibilidad y dispositivos
- [x] Prototipo navegable de los procesos principales
- [~] Prototipo validado con el encargado y Coordinación (§10) → **excepción documentada (§12)**
- [x] Aprobación del desarrollador responsable · 2026-11-18

## 12. Cierre de etapa

**Resultado:** Etapa 7 cerrada con excepción.

**Excepción aprobada (2.ª vez para la validación con usuarios):** la validación del prototipo con el encargado y Coordinación no se realizó. Se pospone y se convierte en **condición obligatoria antes de iniciar el Incremento 3 (EP3, recorrido)** en la Etapa 12, para que un malentendido no llegue a la funcionalidad central ya construida. Como límite absoluto queda la Etapa 17.

**Riesgo R-14 (actualizado):** P 3 · I 2 · nivel 6 (alto). Mitigación: validación antes de EP3; el prototipo queda disponible para compartir.
