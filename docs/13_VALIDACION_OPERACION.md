# 13_VALIDACION_OPERACION — Estado de los Ciclos IV y V

**Metodología:** MIDE-IA 2.0 · Ciclos IV (Etapas 14–17) y V (Etapas 18–20)
**Fecha:** 2026-11-19 · **Estado:** Ciclo III (construcción del MVP) terminado; Ciclos IV y V **iniciados con evidencia parcial**

Este documento distingue con claridad **lo verificado**, **lo parcial** y **lo pendiente**, para no presentar como terminado algo que no lo está (principio de la metodología: la IA no es la autoridad final; todo se verifica con evidencia).

---

## Resumen

| Ciclo | Etapa | Estado | Evidencia |
|---|---|---|---|
| III | 10 Entorno | ✅ Cerrada | Repositorio, README, CI en verde |
| III | 11 Estándares | ✅ Cerrada | 10_ESTANDARES.md, AGENTS.md, prueba de arquitectura |
| III | 12 Incrementos I1–I6 | ✅ Terminados (con excepciones E-1 a E-3) | 12_INCREMENTOS.md |
| III | 13 Integración y versiones | 🟡 Parcial | PR #1 fusionado; PR de I1 y de I2–I6 pendientes de fusionar |
| IV | 14 Pruebas integrales | 🟡 Parcial | 72 pruebas de la app + 42 de reglas; faltan pruebas en Android real y de integración automatizadas |
| IV | 15 Seguridad y privacidad | 🟡 Parcial | Reglas probadas (§2); falta revisión de dependencias y aviso de privacidad aprobado |
| IV | 16 Rendimiento y recuperación | ⏳ Pendiente | Plan en §3 |
| IV | 17 Aceptación con usuarios | ⏳ Pendiente | Guion en 07_UX_UI §10 y GUIA_DEMO.md |
| V | 18 Despliegue | ⏳ Pendiente | Procedimiento en §5 |
| V | 19 Operación | 📝 Planificada | 08_SEGURIDAD_CONTINUIDAD §10 |
| V | 20 Mejora continua | 📝 Backlog definido | §6 |

**Decisión actual:** ¿Apto para producción? → **NO todavía.** El MVP está listo para **demostración y validación con usuarios**, no para usarse con datos reales.

---

## 1. Etapa 14 — Pruebas integrales (estado)

| Tipo | Cantidad | Resultado | Pendiente |
|---|---|---|---|
| Unitarias del dominio | 39 | ✅ | — |
| Widgets / pantallas (con repositorios falsos) | 25 | ✅ | — |
| Arquitectura (capas) | 2 | ✅ | — |
| Lectura de archivos y reportes | 8 | ✅ | — |
| Reglas de seguridad (emulador) | 42 | ✅ | — |
| Integración app ↔ emulador | — | ⏳ | Automatizar PI-01 a PI-08 |
| Extremo a extremo en Android real | — | ⏳ | Requiere Android SDK Command-line Tools |
| Manual guiada (PM-03, PM-04) | 2 guiones | ⏳ | Ejecutar y registrar resultados |
| Accesibilidad | Revisión de diseño (07 §8) | 🟡 | Prueba con lector de pantalla |

## 2. Etapa 15 — Seguridad (verificaciones de 08 §13)

| Verificación | Estado |
|---|---|
| Un docente/encargado no lee datos ajenos | ✅ PR-14, PR-21 |
| Nadie borra registros ni bitácora | ✅ PR-06, PR-09, PR-20 |
| Corrección sin bitácora rechazada | ✅ PR-07, PR-08 |
| Usuario inactivo pierde permisos | ✅ PR-02 |
| Registro con fecha antigua rechazado | ✅ PR-10 |
| Primer acceso exige correo confirmado (C-21) | ✅ PR-03 |
| Inyección de fórmulas neutralizada | ✅ PU-16, PW-06 |
| Sin secretos en el repositorio | ✅ Revisado en cada commit (`.gitignore`, sin credenciales) |
| Dependencias sin vulnerabilidades conocidas | ⏳ `flutter pub outdated` / `npm audit` |
| Aviso de privacidad aprobado | ⏳ Borrador en 08, Anexo A |
| Autorización institucional | ⏳ |

## 3. Etapa 16 — Rendimiento y recuperación (plan)

| Medición | Objetivo | Cómo |
|---|---|---|
| Registrar un aula | ≤ 3 toques / ≤ 10 s (RNF-003) | Cronometrar PM-04 escena 3 (el diseño ya cumple 1–2 toques) |
| Reporte semanal | < 1 min (RNF-004) | La pantalla de Reportes muestra el tiempo de generación |
| Turno completo sin conexión | Sin pérdidas (RNF-001) | 14 bloques en modo avión en Android real |
| Restauración desde respaldo | Datos completos | Crear `tool/restaurar.dart` y probar en el emulador |

## 4. Etapa 17 — Aceptación (pendiente obligatorio)

Salda las excepciones de las Etapas 1, 3, 7 y E-1. Ejecutar el guion de 07_UX_UI §10 con el **MVP funcionando** (no solo el prototipo) y registrar el acta de aceptación.

## 5. Etapa 18 — Despliegue (procedimiento preparado)

1. Crear el proyecto de Firebase de **producción** (plan gratuito) con dos propietarios (C-20).
2. `flutterfire configure` → opciones reales; compilar con `--dart-define=USAR_EMULADOR=false`.
3. Configurar política de contraseñas y protección de enumeración en Authentication (C-01, C-02).
4. `firebase deploy --only firestore:rules,firestore:indexes,hosting`.
5. Crear el primer usuario de Coordinación en la consola (ADR-005).
6. Instalar el APK en el celular del encargado.
7. Pruebas de humo: entrar con cada rol, registrar un aula, generar un reporte.
8. Respaldo inicial y registro de la versión 1.0.0.

## 6. Etapa 20 — Backlog de mejora continua

| Tipo | Elemento |
|---|---|
| Funcionalidad (v1.1) | EP7 Portal docente y justificaciones (RF-023 a RF-027) |
| Funcionalidad (v1.1) | EP8 Restablecer contraseña, días inhábiles, edición manual del horario, clase no programada |
| Calidad | Pruebas de integración automatizadas; pruebas en Android real |
| Operación | `tool/restaurar.dart`; monitoreo de cuotas del plan gratuito |
| Fuera de alcance (evaluar) | X-01 integración con el sistema escolar; X-06 notificaciones |
