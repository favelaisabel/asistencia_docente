# AGENTS.md — Instrucciones para agentes de IA

Instrucciones persistentes para cualquier agente de programación (Codex, Claude Code u otro) que trabaje en este repositorio. Complementan [docs/10_ESTANDARES.md](docs/10_ESTANDARES.md); si hay conflicto, manda el documento de estándares.

## Proyecto

Control de asistencia docente para una universidad pública: un encargado registra en una **app Android** (que funciona sin internet) si cada docente está en su aula; Coordinación consulta, corrige y genera reportes en una **web**. Backend: Firebase (Auth + Firestore). Metodología: **MIDE-IA 2.0**.

Los registros son **evidencia para actas administrativas**: la integridad de los datos es prioritaria.

## Documentos que debes leer antes de cambiar código

| Para | Lee |
|---|---|
| Qué construir | `docs/03_REQUISITOS.md` (RF, RN, RNF con criterios de aceptación) |
| Qué entra en cada incremento | `docs/09_ROADMAP.md` §5 y la matriz §6 |
| Cómo está organizado | `docs/05_ARQUITECTURA.md`, `docs/05_ADR.md` |
| Datos y restricciones | `docs/06_MODELO_DATOS.md` |
| Pantallas y mensajes | `docs/07_UX_UI.md` |
| Seguridad | `docs/08_SEGURIDAD_CONTINUIDAD.md` |
| Cómo escribir código | `docs/10_ESTANDARES.md` |

## Comandos

```bash
cd app
flutter pub get
dart format lib test                 # formato
flutter analyze                      # debe terminar en "No issues found!"
flutter test                         # pruebas unitarias, widgets y arquitectura

cd test_reglas
npm ci
npm test                             # reglas de seguridad en el emulador
```

Antes de dar una tarea por terminada, **ejecuta los cuatro** y reporta el resultado real.

## Reglas obligatorias

1. **Alcance:** implementa solo el incremento o requisito indicado. No agregues funcionalidades, pantallas ni paquetes fuera de alcance; si crees que hacen falta, propónlo sin implementarlo.
2. **Requisitos aprobados:** no cambies requisitos, reglas de negocio ni el modelo de datos por tu cuenta. Si encuentras una contradicción, detente y repórtala.
3. **Capas:** `lib/dominio/` es Dart puro (sin Flutter, Firebase ni Riverpod). Las reglas de negocio viven solo ahí.
4. **TDD en el dominio:** escribe primero la prueba (nombre con su ID, p. ej. `PU-07`), luego el código.
5. **Reglas de Firestore:** todo cambio en `app/firestore.rules` lleva pruebas en `app/test_reglas/` (ID `PR-xx`). Por defecto, todo denegado.
6. **Integridad:** nunca permitas borrar registros ni bitácora; toda modificación de un registro se escribe en lote junto con su entrada de bitácora.
7. **Datos:** usa solo datos ficticios. Nunca escribas datos personales en logs.
8. **Secretos:** nunca crees, pidas ni subas credenciales, claves de cuenta de servicio ni archivos `.env`.
9. **Hora:** el dominio no llama a `DateTime.now()`; recibe la hora como parámetro o por la interfaz `Reloj`.
10. **Git:** trabaja en una rama `incremento/I<n>-<tema>`; commits con formato `tipo(ámbito): descripción (RF-xxx)`; nunca hagas push directo a `main` ni reescribas su historial.

## Operaciones que requieren autorización explícita del desarrollador responsable

- Push, merge a `main`, crear o cerrar PRs.
- Agregar o actualizar dependencias.
- Modificar `firestore.rules`, `firebase.json`, el CI o la configuración de Android.
- Cualquier operación contra un proyecto real de Firebase (no el emulador).
- Borrar archivos o carpetas.

## Formato del reporte al terminar

1. Qué se implementó (con IDs de requisitos).
2. Archivos creados o modificados.
3. Pruebas agregadas (con IDs) y resultado de los cuatro comandos.
4. Decisiones tomadas y supuestos.
5. Limitaciones o pendientes conocidos.
6. Cambios sugeridos a la matriz de trazabilidad (09_ROADMAP §6).

No afirmes que algo funciona si no lo ejecutaste.
