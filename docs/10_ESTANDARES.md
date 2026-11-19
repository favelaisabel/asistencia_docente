# 10_ESTANDARES — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo III · Etapa 11
**Versión:** 1 · **Fecha:** 2026-11-19 · **Estado:** Cerrada
**Entradas:** [05_ARQUITECTURA.md](05_ARQUITECTURA.md) · [08_SEGURIDAD_CONTINUIDAD.md](08_SEGURIDAD_CONTINUIDAD.md) · [09_ROADMAP.md](09_ROADMAP.md)
**Instrucciones para agentes de IA:** [../AGENTS.md](../AGENTS.md)

---

## 1. Objetivo de la etapa

Fijar reglas claras para implementar, revisar y aceptar cambios, de forma que el código sea consistente sin importar si lo escribe una persona o un agente de IA.

Las reglas marcadas con 🤖 se verifican automáticamente (análisis estático, pruebas o CI). Las demás se verifican en la revisión (§11).

## 2. Idioma

| Elemento | Idioma |
|---|---|
| Identificadores (clases, variables, archivos) | **Español sin acentos ni ñ** (`Turno`, `deBloque`, `registro_repositorio.dart`, `anio`) |
| Comentarios y documentación | Español |
| Mensajes al usuario | Español, según 07_UX_UI §6 |
| Mensajes de commit y PR | Español |
| Términos técnicos sin buena traducción | Se conservan (`provider`, `widget`, `batch`, `snapshot`) |

## 3. Nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case` | `calculadora_situacion.dart` |
| Clases, enums, typedefs | `PascalCase` | `CalculadoraSituacion` |
| Variables, funciones, parámetros, constantes | `lowerCamelCase` | `horaDispositivo`, `proyectoDemo` |
| Privados | Prefijo `_` | `_opcionesDemo` |
| Providers de Riverpod | Sufijo `Provider` | `registroRepositorioProvider` |
| Interfaces de repositorio | Sustantivo + `Repositorio` | `RegistroRepositorio` |
| Implementaciones Firestore | Prefijo `Firestore` | `FirestoreRegistroRepositorio` |
| Pantallas | Sufijo `Pantalla` | `RecorridoPantalla` |
| Campos de Firestore | `camelCase` en español, igual que 06_MODELO_DATOS | `estadoCaptura` |
| Valores de enumeraciones guardados | MAYÚSCULAS | `AUN_NO_LLEGA` |

Nombres descriptivos; sin abreviaturas salvo las de negocio (`ENC`, `DOC`, `COO`, `RF`, `RN`).

## 4. Estructura y capas

```
lib/
├── app/          Arranque, tema, router, configuración de Firebase
├── core/         Utilidades sin lógica de negocio (reloj, formato de fechas, errores base)
├── dominio/      Entidades, reglas de negocio e interfaces de repositorio — Dart puro
├── datos/        Implementaciones de repositorios con Firestore y mapeadores
└── modulos/<funcionalidad>/
    ├── aplicacion/   Providers y controladores (casos de uso, estado de pantalla)
    └── presentacion/ Pantallas y widgets
```

| Regla | Verificación |
|---|---|
| `dominio/` **no** importa Flutter, Firebase ni Riverpod | 🤖 `test/arquitectura_test.dart` |
| `presentacion/` no usa Firebase directamente; pasa por `aplicacion/` | 🤖 `test/arquitectura_test.dart` |
| Una regla de negocio vive en **un solo lugar** (`dominio/`); pantallas, reportes y reglas de la app la reutilizan | Revisión |
| Un archivo = una responsabilidad principal; si supera ~300 líneas, dividir | Revisión |

## 5. Estado y dependencias (Riverpod)

- Los repositorios se exponen con providers en `datos/` o `modulos/*/aplicacion/` y **se sustituyen por falsos en las pruebas**.
- Las pantallas leen estado con `ref.watch` y ejecutan acciones con `ref.read(...notifier)`.
- Nada de estado global mutable fuera de Riverpod.

## 6. Fechas y horas

- Toda fecha/hora de negocio usa la zona `America/Mexico_City` (06_MODELO_DATOS §2).
- El dominio **no llama a `DateTime.now()`**: recibe la hora como parámetro o a través de la interfaz `Reloj` (`core/reloj.dart`, se crea en I3), para poder probar casos como "minuto 31".
- Fechas de negocio como texto `AAAA-MM-DD`; horas de bloque como entero 7–20.

## 7. Manejo de errores

| Capa | Regla |
|---|---|
| Dominio | Errores esperados como resultados tipados (clases `sealed` de fallas, p. ej. `ErrorImportacion`), no excepciones |
| Datos | Captura `FirebaseException` y la traduce a una falla del dominio (`SinPermiso`, `SinConexion`, `NoEncontrado`, `Desconocido`) |
| Aplicación | Convierte fallas en estado de pantalla (`AsyncValue.error`) |
| Presentación | Muestra los mensajes de 07_UX_UI §6; nunca el texto técnico de la excepción |

- Prohibido `catch (_) {}` vacío: todo error se maneja o se registra.
- Prohibido `!` (null assertion) sobre datos externos (Firestore, archivos); validar primero.

## 8. Validaciones

Doble validación (C-12): la app valida para dar mensajes claros **y** las reglas de Firestore validan para proteger. Ningún cambio de validación en la app se considera completo sin revisar la regla equivalente.

## 9. Registro técnico (logging)

- Usar `log()` de `dart:developer` con un `name` por módulo (`'recorrido'`, `'horario'`).
- 🤖 `print` está prohibido (`avoid_print`).
- **Nunca** registrar: contraseñas, correos, nombres de docentes, motivos o adjuntos de justificaciones (08 §8). Usar identificadores técnicos (`registroId`, `uid`).

## 10. Pruebas

| Tipo | Ubicación | Convención |
|---|---|---|
| Unitarias del dominio (PU) | `test/dominio/` | El nombre del `test` inicia con el ID: `'PU-07 llegada al minuto 15 es a tiempo'` |
| Widgets (PW) | `test/modulos/<funcionalidad>/` | Con repositorios falsos vía Riverpod |
| Integración (PI) | `integration_test/` | Contra el emulador |
| Reglas de seguridad (PR) | `test_reglas/*.test.js` | El nombre inicia con el ID: `'PR-06 nadie borra registros'` |
| Arquitectura | `test/arquitectura_test.dart` | Reglas de §4 |

- **TDD en el dominio:** primero la prueba que falla, luego el código.
- Estructura Preparar / Actuar / Verificar; una conducta por prueba.
- Casos positivos, negativos y límites (p. ej. minuto 15, 16, 30, 31).
- Toda corrección de un defecto agrega una prueba que lo reproduce.
- Meta de cobertura del dominio: ≥ 90 % (se mide desde I2 con `flutter test --coverage`).
- Datos de prueba siempre **ficticios**.

## 11. Git, ramas y revisión

### 11.1 Ramas

| Rama | Uso |
|---|---|
| `main` | Siempre estable; solo recibe cambios por pull request con CI en verde |
| `incremento/I<n>-<tema>` | Trabajo de un incremento (`incremento/I1-acceso`) |
| `fix/<tema>` | Corrección de un defecto |
| `docs/<tema>` | Solo documentación |

### 11.2 Commits

Formato: `tipo(ámbito): descripción en presente` + IDs de requisitos cuando aplique.

| Tipo | Uso |
|---|---|
| `feat` | Funcionalidad nueva |
| `fix` | Corrección |
| `test` | Solo pruebas |
| `refactor` | Cambio interno sin cambiar comportamiento |
| `docs` | Documentación |
| `chore` | Configuración, dependencias, CI |

Ejemplo: `feat(recorrido): registrar situación con un toque (RF-014, RN-001)`

Commits pequeños que compilan y pasan las pruebas.

### 11.3 Pull requests y lista de revisión

Todo cambio entra a `main` por PR usando la plantilla `.github/pull_request_template.md`. Antes de integrar:

- [ ] CI en verde 🤖
- [ ] Solo contiene el alcance del incremento / requisito indicado
- [ ] Cada requisito tocado cumple su criterio de aceptación
- [ ] Reglas de negocio nuevas con prueba unitaria; permisos nuevos con prueba de reglas
- [ ] Sin reglas de negocio duplicadas
- [ ] Sin secretos, datos reales ni datos personales en logs
- [ ] Mensajes al usuario según 07_UX_UI
- [ ] Documentación y matriz de trazabilidad (09_ROADMAP §6) actualizadas

Con un solo desarrollador, la revisión es **autorrevisión con esta lista + revisión asistida por IA** (09_ROADMAP §4).

## 12. Dependencias

- Agregar un paquete solo cuando el incremento lo necesita y se justifica en el PR.
- Preferir paquetes oficiales o de publicadores verificados, con mantenimiento activo y licencia compatible.
- No agregar paquetes para tareas triviales.
- Versiones fijadas por `pubspec.lock` y `package-lock.json` (en el repositorio).
- Revisión mensual con `flutter pub outdated` y `npm outdated`; actualizar en un PR propio.

## 13. Seguridad en el código

- Nunca credenciales, claves de cuenta de servicio ni `.env` en el repositorio 🤖 (`.gitignore`).
- Cambios en `firestore.rules` **siempre** acompañados de pruebas en `test_reglas/`.
- Exportaciones a Excel/CSV con neutralización de fórmulas (C-14).
- Texto de usuarios siempre tratado como texto, nunca como código o HTML.

## 14. Criterios de salida de la Etapa 11

- [x] Convenciones de nombres e idioma
- [x] Estructura de módulos y separación de responsabilidades
- [x] Manejo de errores, validaciones y logging
- [x] Convenciones de pruebas
- [x] Flujo de Git, commits y revisión de código
- [x] Política de dependencias
- [x] Instrucciones persistentes para agentes de IA (AGENTS.md)
- [x] Verificación automática de la arquitectura (test/arquitectura_test.dart)
- [x] Aprobación del desarrollador responsable · 2026-11-19
