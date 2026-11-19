# Guía de demostración — Asistencia Docente (MVP)

Guion para presentar el sistema funcionando en el emulador local (≈ 15 minutos). También es la **prueba manual PM-04** del MVP.

---

## 1. Preparación (antes de presentar, ~5 min)

Abre **tres terminales** en la carpeta del repositorio (`Documentos\GitHub\asistencia_docente`).

**Terminal 1 — emulador de Firebase** (se queda abierta):

```bash
cd app/test_reglas
npm run emuladores
```

Espera a ver `All emulators ready!`. Consola del emulador: http://localhost:4000

**Terminal 2 — datos de demostración** (una sola vez, con el emulador encendido):

```bash
cd app/test_reglas
npm run sembrar
```

Crea las cuentas y activa el horario 2026-2 (480 clases, aulas A101–A110, lunes a sábado de 7:00 a 21:00).

**Terminal 3 — web de Coordinación:**

```bash
cd app
flutter run -d chrome -t lib/main_web.dart --web-port 5000
```

**Terminal 4 — app del encargado** (en Chrome, simulando el celular):

```bash
cd app
flutter run -d chrome -t lib/main_movil.dart --web-port 5001
```

Reduce esa ventana al ancho de un celular, o usa las herramientas de desarrollador (F12) → icono de dispositivo móvil.

> **Si presentas fuera del horario de clases** (antes de las 7:00, después de las 21:00 o en domingo), agrega `--dart-define=HORA_DEMO=09:05` al comando de la app del encargado. Los registros saldrán marcados como **"Hora dudosa"**, porque el reloj está desplazado: es justo el control RNF-008 funcionando.

### Cuentas

| Rol | Correo | Contraseña |
|---|---|---|
| Coordinación | `coordinacion@demo.edu.mx` | `Coordinacion2026` |
| Encargado | `encargado@demo.edu.mx` | `Encargado2026` |
| Pre-registro pendiente | `nuevo.encargado@demo.edu.mx` | (se crea en "Primer acceso") |

---

## 2. Guion

### Escena 1 — El problema (Etapa 1) · 1 min
Hoy: libreta, ~45 s por aula, 30 min por recorrido, 1 hora para el reporte, sin evidencia confiable para actas.

### Escena 2 — Acceso por rol (I1) · 2 min
1. App del encargado → entra como **encargado**: va directo al **Recorrido**.
2. Web → entra como **Coordinación**: ve el panel con 5 pestañas.
3. Mostrar que si alguien de Coordinación abre la app del encargado, el sistema lo rechaza (seguridad por rol).

### Escena 3 — El recorrido (I3) · 4 min
En la app del encargado:
1. Se ve el **bloque actual**, la fecha y "0 de 10 aulas" con el **docente ya precargado** (no se escribe nada).
2. Toca **A101 → Presente**: un toque; el aula pasa a "A tiempo" y el avance sube.
3. Toca **A102 → Suplente** → intenta guardar vacío (mensaje) → escribe un nombre → Guardar.
4. Toca **A103 → Aún no llega**. Explica: si llega después, el sistema calcula **a tiempo / retardo / falta** con la regla 15/30 min; si pasa el minuto 30, se vuelve falta solo.
5. Toca **A104 → Sin docente**.

### Escena 4 — Sin internet (I4) · 2 min
1. En la ventana del encargado: F12 → pestaña **Network** → **Offline**.
2. Registra 2 aulas: el indicador cambia a **"Sin conexión · 2 por enviar"** y las aulas muestran el icono de nube.
3. Vuelve a **Online**: aparece **"2 registros enviados"**.

### Escena 5 — Coordinación en vivo (I5) · 3 min
En la web:
1. **Hoy**: los indicadores (registros, faltas, retardos, suplencias, horas dudosas) ya reflejan lo que hizo el encargado.
2. **Registros**: filtra por situación "Falta" → abre el registro → muestra la **bitácora** (quién, qué, cuándo).
3. **Corregir** sin motivo → mensaje; con motivo → aparece la versión 2 en la bitácora. Explica: **nada se borra**; toda corrección deja rastro (evidencia para actas).

### Escena 6 — Reportes y respaldo (I6) · 2 min
1. **Reportes → Diario → Excel → Generar**: se descarga en segundos (antes: 1 hora). Mostrar el tiempo de generación.
2. **Semanal → PDF**: incluye **totales por docente**.
3. **Descargar respaldo**: .zip con un CSV por colección.

### Escena 7 — Horario y usuarios (I2, I1) · 2 min
1. **Horario → Subir archivo** → `docs/demo/horario_con_errores.csv`: tabla de errores por fila y **"No se guardó nada"**.
2. **Subir** `docs/demo/horario_demo.csv` → "480 clases listas" → **Activar horario**.
3. **Usuarios**: pre-registrar un correo; mostrar el pendiente `nuevo.encargado@demo.edu.mx`.

### Escena 8 — Calidad (MIDE-IA 2.0) · 1 min
- 72 pruebas automáticas de la app + 42 de reglas de seguridad, en CI de GitHub.
- Trazabilidad requisito → código → prueba (09_ROADMAP §6 y §10).
- Pendientes honestos: validación con usuarios, restauración probada, despliegue (ver 13_VALIDACION_OPERACION.md).

---

## 3. Si algo falla

| Problema | Solución |
|---|---|
| La app se queda en "Cargando" | El emulador no está encendido: revisa la Terminal 1 |
| "Aún no hay horario activo" | Ejecuta `npm run sembrar` en la Terminal 2 |
| "No hay clases en este momento" | Estás fuera de horario: reinicia la app del encargado con `--dart-define=HORA_DEMO=09:05` |
| Correo o contraseña incorrectos | Ejecuta de nuevo `npm run sembrar` (los datos del emulador se borran al cerrarlo) |
| Puerto ocupado | Cambia `--web-port` o cierra la otra instancia |

## 4. Resultado de la prueba PM-04

| Escena | ¿Funcionó? | Observaciones |
|---|---|---|
| 2 Acceso | | |
| 3 Recorrido | | |
| 4 Sin internet | | |
| 5 Coordinación | | |
| 6 Reportes | | |
| 7 Horario y usuarios | | |
