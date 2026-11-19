# Asistencia Docente

Aplicación para registrar la asistencia de los docentes en el aula y generar reportes. Sustituye a la libreta que se usa hoy en los recorridos.

Se desarrolla con la metodología **MIDE-IA 2.0**.

- **App Android** para el encargado de recorridos (funciona sin internet).
- **Web** para Coordinación académica (y docentes en la v1.1).
- **Backend:** Firebase (Authentication + Firestore), plan gratuito.

## Estructura

```
asistencia_docente/
├── docs/                     Entregables de la metodología (01_ a 13_) y prototipo
├── .github/workflows/ci.yml  Integración continua
└── app/                      Proyecto Flutter
    ├── lib/
    │   ├── main.dart         Entrada por defecto (elige según plataforma)
    │   ├── main_movil.dart   Entrada Android (encargado)
    │   ├── main_web.dart     Entrada web (Coordinación)
    │   ├── app/              Configuración, tema, Firebase
    │   ├── core/             Utilidades comunes
    │   ├── dominio/          Reglas de negocio en Dart puro (con pruebas)
    │   ├── datos/            Repositorios de Firestore
    │   └── modulos/          Funcionalidades (autenticacion, horario, recorrido, ...)
    ├── test/                 Pruebas unitarias y de widgets
    ├── test_reglas/          Pruebas de reglas de seguridad (Node + emulador)
    ├── tool/                 Scripts de administración
    ├── firestore.rules       Reglas de seguridad
    └── firebase.json         Configuración de Firebase y del emulador
```

## Requisitos

| Herramienta | Versión | Para qué |
|---|---|---|
| Flutter | 3.38.9 (stable) | App Android y web |
| Node.js | 20 o superior (probado con 24) | Firebase CLI y pruebas de reglas |
| Java (JDK) | 21 o superior | Emulador de Firestore |
| Android Studio + SDK | Con *Android SDK Command-line Tools* y licencias aceptadas | Compilar para Android |
| Git | Cualquiera reciente | Control de versiones |

No se necesita una cuenta de Firebase para desarrollar: se usa el **emulador local** con el proyecto de demostración `demo-asistencia-docente` y datos ficticios.

## Instalación

```bash
git clone <url-del-repositorio>
cd asistencia_docente/app
flutter pub get

cd test_reglas
npm ci            # instala Firebase CLI y herramientas de prueba en el proyecto
```

## Ejecución

1. **Iniciar el emulador de Firebase** (una terminal, se queda abierta):

   ```bash
   cd app/test_reglas
   npm run emuladores
   ```

   Consola del emulador: http://localhost:4000

2. **Ejecutar la app** (otra terminal):

   ```bash
   cd app
   flutter run -d chrome -t lib/main_web.dart       # web de Coordinación
   flutter run -t lib/main_movil.dart               # Android (emulador de Android)
   ```

   Con un **celular físico**, agrega `--dart-define=HOST_EMULADOR=<IP de tu PC>` (ver `.env.example`).

## Pruebas

```bash
cd app
dart format lib test        # formato
flutter analyze             # análisis estático (debe decir "No issues found!")
flutter test                # pruebas unitarias y de widgets

cd test_reglas
npm test                    # reglas de seguridad (levanta el emulador automáticamente)
```

El CI de GitHub ejecuta lo mismo en cada push y pull request.

## Errores frecuentes

| Error | Solución |
|---|---|
| `cmdline-tools component is missing` en `flutter doctor` | Android Studio → *Settings* → *Languages & Frameworks* → *Android SDK* → pestaña *SDK Tools* → marcar **Android SDK Command-line Tools** → *Apply* |
| `Android license status unknown` | `flutter doctor --android-licenses` y aceptar todo con `y` |
| La app Android no conecta con el emulador de Firebase | El emulador de Android usa `10.0.2.2` automáticamente; con celular físico usa `--dart-define=HOST_EMULADOR=<IP>` y que PC y celular estén en la misma red |
| `Could not start Firestore Emulator, port taken` | Otro emulador está abierto; ciérralo o termina el proceso en el puerto 8080 |
| Las pruebas de reglas fallan por tiempo de espera | La primera conexión es lenta; vuelve a ejecutar. El límite está en `test_reglas/vitest.config.js` |
| Archivos bloqueados al compilar (la carpeta está en OneDrive) | Pausa la sincronización de OneDrive mientras compilas, o mueve el repositorio fuera de OneDrive |

## Avance

| Etapa | Entregable | Estado |
|---|---|---|
| 1. Problema | docs/01_CONTEXTO.md | Cerrada (excepción: validación con usuarios) |
| 2. Viabilidad y riesgos | docs/02_VIABILIDAD_RIESGOS.md | Cerrada: viable con ajustes |
| 3. Requisitos | docs/03_REQUISITOS.md | Cerrada (excepción: validación con usuarios) |
| 4. Alcance y MVP | docs/04_ALCANCE_MVP.md | Cerrada (v2, CR-001) |
| **Ciclo I** | Definición y análisis | **Completado** |
| 5. Arquitectura | docs/05_ARQUITECTURA.md + docs/05_ADR.md | Cerrada |
| 6. Modelo de datos | docs/06_MODELO_DATOS.md | Cerrada |
| 7. Interfaces y UX | docs/07_UX_UI.md + docs/prototipo/ | Cerrada (excepción: validar prototipo antes de I3) |
| 8. Seguridad y continuidad | docs/08_SEGURIDAD_CONTINUIDAD.md | Cerrada (CR-001 aprobada) |
| 9. Plan incremental | docs/09_ROADMAP.md | Cerrada |
| **Ciclo II** | Diseño y planificación | **Completado** (excepción: validar prototipo antes de I3) |
| 10. Entorno de desarrollo | app/ + README + CI | Cerrada (CI en verde en GitHub) |
| 11. Estándares de codificación | docs/10_ESTANDARES.md + AGENTS.md | Cerrada |
