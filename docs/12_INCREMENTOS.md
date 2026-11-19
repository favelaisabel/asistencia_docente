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
