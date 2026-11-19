# 05_ARQUITECTURA — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo II · Etapa 5
**Versión:** 1 · **Fecha:** 2026-11-18 · **Estado:** Cerrada
**Entradas:** [03_REQUISITOS.md](03_REQUISITOS.md) v2 · [04_ALCANCE_MVP.md](04_ALCANCE_MVP.md) v1
**Decisiones:** [05_ADR.md](05_ADR.md)

Convenciones: **(C)** confirmado · **(S)** supuesto · **(V)** verificar en Etapa 10 contra la documentación vigente del proveedor.

---

## 1. Objetivo de la etapa

Definir cómo se estructura el sistema: enfoque arquitectónico, tecnologías, componentes, responsabilidades e interfaces, justificando cada decisión por los requisitos y restricciones, no por popularidad.

## 2. Requisitos que más condicionan la arquitectura

| Requisito / restricción | Implicación arquitectónica |
|---|---|
| RNF-001, RNF-002 · R-02 (nivel 9) | Persistencia local en el dispositivo y sincronización automática: **offline-first** |
| RES-03 · RNF-015 | Solo servicios con plan gratuito; sin servidores propios que mantener |
| RES-01 · RES-02 | Una sola base de código y el menor número de piezas posible |
| RES-04 · A2 | Una app Android (encargado) y una web (docentes y Coordinación) |
| RNF-007 · RN-010 | Permisos validados en el servidor, no solo en la interfaz |
| RNF-008, RNF-009 · RN-008 | Hora del servidor, bitácora inmutable, registros que nunca se borran |
| RNF-017 | Reglas de negocio aisladas y probables sin red ni interfaz |
| RF-028, RF-029 | Generación de PDF y Excel |

## 3. Enfoque arquitectónico

**Monolito modular cliente-servidor sin servidor propio (serverless gestionado):**

- **Cliente:** un solo proyecto Flutter, organizado en módulos por funcionalidad, con dos puntos de entrada:
  - `main_movil.dart` → app Android del encargado.
  - `main_web.dart` → aplicación web de Coordinación (y docentes en v1.1).
- **Servidor:** servicios gestionados de **Firebase** (plan gratuito): autenticación, base de datos Firestore con caché local y hosting web. La seguridad del lado servidor se implementa con **reglas de seguridad de Firestore**.

Justificación y alternativas descartadas: ver ADR-001 y ADR-002.

## 4. Diagrama de componentes

```
 ┌────────────────────────────┐        ┌────────────────────────────┐
 │  App Android (Encargado)   │        │  Web (Coordinación/Docente)│
 │  Flutter · main_movil.dart │        │  Flutter · main_web.dart   │
 │                            │        │                            │
 │  Presentación (pantallas)  │        │  Presentación (pantallas)  │
 │  Aplicación (controladores)│        │  Aplicación (controladores)│
 │  Dominio (reglas, Dart)  ◄─┼─ código compartido ─►  Dominio       │
 │  Datos (repositorios)      │        │  Datos (repositorios)      │
 │  Caché local Firestore     │        │  Reportes PDF / Excel      │
 └─────────────┬──────────────┘        └─────────────┬──────────────┘
               │ HTTPS (sincroniza al haber señal)   │ HTTPS
               ▼                                     ▼
 ┌──────────────────────────────────────────────────────────────────┐
 │                    Firebase (plan gratuito)                       │
 │  Authentication  ·  Cloud Firestore + Reglas de seguridad  ·      │
 │  Hosting (web)   ·  [v1.1: almacenamiento de adjuntos, ADR-008]   │
 └──────────────────────────────────────────────────────────────────┘
               ▲
               │ Plantilla Excel/CSV (importación manual por Coordinación)
 ┌─────────────┴──────────────┐
 │ Sistema escolar (externo)  │  Sin integración directa (X-01)
 └────────────────────────────┘
```

## 5. Capas y responsabilidades

| Capa | Responsabilidad | No debe |
|---|---|---|
| **Presentación** | Pantallas, navegación, formularios, mensajes, estados de carga/vacío/error | Contener reglas de negocio ni acceder directo a Firebase |
| **Aplicación** | Casos de uso y estado de pantalla (p. ej. "registrar situación", "generar reporte diario") | Conocer detalles de Firestore |
| **Dominio** | Entidades y reglas de negocio puras en Dart: cálculo de situación (RN-002/003), plazo de justificación (RN-004), unicidad (RN-006), validación de horario (RN-011) | Depender de Flutter, Firebase o red |
| **Datos** | Repositorios que implementan las interfaces del dominio con Firestore; conversión documento ↔ entidad | Decidir reglas de negocio |
| **Infraestructura (Firebase)** | Autenticación, persistencia, sincronización, reglas de seguridad, hosting | — |

**Regla de dependencia:** Presentación → Aplicación → Dominio ← Datos. El dominio no depende de nadie; así las reglas se prueban sin red (RNF-017) y el proveedor puede cambiarse sustituyendo la capa de datos (mitiga R-16).

## 6. Módulos (por funcionalidad)

| Módulo | Épica | Plataforma | Requisitos principales |
|---|---|---|---|
| `autenticacion` | EP1 | Ambas | RF-001, RF-002, RF-005 |
| `usuarios` | EP1 | Web | RF-004 |
| `horario` (periodos, aulas, docentes, importación) | EP2 | Web | RF-006, RF-008 a RF-011 |
| `recorrido` | EP3, EP4 | Android | RF-013 a RF-019, RF-021, RF-022 |
| `bitacora` | EP5 | Web | RF-031, RF-032 |
| `reportes` | EP6 | Web | RF-028 a RF-030 |
| `justificaciones` (v1.1) | EP7 | Web | RF-023 a RF-027 |
| `administracion` (v1.1) | EP8 | Web | RF-003, RF-007, RF-012, RF-020, RF-033 |

## 7. Interfaces principales (contratos del dominio)

Definidas en el dominio e implementadas en la capa de datos:

| Interfaz | Operaciones |
|---|---|
| `AutenticacionRepositorio` | iniciarSesion, cerrarSesion, usuarioActual (con rol), registrarDesdePreregistro |
| `UsuarioRepositorio` | preregistrar(correo, rol), desactivar, listar |
| `HorarioRepositorio` | periodoActivo, importar(filas validadas), clasesDelBloque(fecha, hora), listar |
| `RegistroRepositorio` | registrar, marcarLlegada, corregir(motivo), observarDelDia, consultar(filtros) |
| `BitacoraRepositorio` | listar(filtros) — solo lectura; las entradas se crean junto con cada corrección |
| `ReporteServicio` | generarDiarioPdf/Excel, generarSemanalPdf/Excel (a partir de registros consultados) |
| `CalculadoraSituacion` (dominio puro) | situacionEfectiva(registro, inicioClase, horaActual) |
| `ValidadorHorario` (dominio puro) | validar(filas) → lista de errores por fila |

## 8. Tecnologías seleccionadas

| Necesidad | Tecnología | Motivo | ADR |
|---|---|---|---|
| Cliente Android + web | **Flutter 3.38 / Dart 3.10** (C, instalado) | Una base de código para ambas plataformas; disponible en el equipo | ADR-001 |
| Autenticación | **Firebase Authentication** (correo y contraseña) | Gratuito; sesión persistente sin conexión (RF-005) | ADR-002 |
| Base de datos + sincronización | **Cloud Firestore** con persistencia local | Offline-first integrado en Android; hora del servidor; plan gratuito suficiente | ADR-002, ADR-003 |
| Seguridad servidor | **Reglas de seguridad de Firestore** | Permisos por rol, inmutabilidad de bitácora, sin servidor propio | ADR-005 |
| Hosting web | **Firebase Hosting** | Gratuito, HTTPS incluido | ADR-002 |
| Estado y dependencias | **Riverpod** | Separación clara de capas, fácil de probar | ADR-006 |
| Navegación | **go_router** | Rutas por rol y protección de rutas | ADR-006 |
| PDF | Paquete **pdf** (+ printing para descargar) | Generación en el cliente sin servidor | ADR-007 |
| Excel / CSV | Paquetes **excel** y **csv**; **file_picker** para importar | Importación de horario y exportación de reportes | ADR-007 |
| Pruebas de reglas de seguridad | **Firebase Emulator Suite** | Probar permisos sin tocar producción (RNF-007) | ADR-005 |

> Las versiones exactas de los paquetes se fijan en la Etapa 10 (archivo `pubspec.lock` versionado).

## 9. Estructura del proyecto (prevista)

```
asistencia_docente/
├── docs/
└── app/
    ├── lib/
    │   ├── main_movil.dart          # Entrada Android (encargado)
    │   ├── main_web.dart            # Entrada web (Coordinación / docentes)
    │   ├── app/                     # Router, tema, configuración
    │   ├── core/                    # Errores, utilidades, reloj
    │   ├── dominio/                 # Entidades, reglas, interfaces (Dart puro)
    │   ├── datos/                   # Repositorios Firestore, mapeadores
    │   └── modulos/
    │       ├── autenticacion/
    │       ├── usuarios/
    │       ├── horario/
    │       ├── recorrido/
    │       ├── bitacora/
    │       └── reportes/
    ├── test/
    │   ├── dominio/                 # Pruebas unitarias de reglas
    │   └── reglas_firestore/        # Pruebas de reglas en el emulador
    ├── firestore.rules
    ├── firestore.indexes.json
    └── firebase.json
```

## 10. Capacidad en el plan gratuito

Límites diarios del plan gratuito de Firestore usados como referencia (V): ~50 000 lecturas, ~20 000 escrituras, 1 GiB almacenado.

| Concepto | Estimación | Límite | Uso |
|---|---|---|---|
| Escrituras/día | 560 registros + ~100 llegadas/correcciones + bitácora ≈ **800** | 20 000 | ~4 % |
| Lecturas/día | Horario en caché (~300 una vez) + recorridos (~600) + 2 reportes diarios (~1 200) + 1 semanal (~2 800) ≈ **5 000** | 50 000 | ~10 % |
| Almacenamiento/periodo | 560 × ~1 KB × ~100 días ≈ **56 MB** | 1 GiB | ~6 % |
| Hosting web | Pocos usuarios internos | Cuota gratuita | Bajo |

**Conclusión:** el MVP cabe con amplio margen en el plan gratuito (RNF-015, RNF-016).

## 11. Verificación de la arquitectura contra los requisitos clave

| Requisito | Cómo lo cumple la arquitectura |
|---|---|
| RNF-001/002 Sin conexión | Caché persistente de Firestore en Android; escrituras en cola que se envían al recuperar señal |
| RF-005 Sesión sin conexión | Firebase Auth conserva la sesión en el dispositivo |
| RN-003 "aún no llega" → falta al minuto 30 | Se **calcula al leer** en `CalculadoraSituacion`; no requiere procesos programados en servidor |
| RN-006 Un registro por aula/fecha/bloque | Identificador de documento determinista `aula_fecha_hora`; las reglas solo permiten crearlo si no existe |
| RNF-007 Permisos en servidor | Reglas de Firestore leen el rol del usuario desde su perfil |
| RNF-008 Hora verificable | Cada registro guarda hora del dispositivo y `serverTimestamp` |
| RNF-009 Bitácora inmutable | Reglas: la colección de bitácora solo admite creación; toda corrección debe escribir su entrada de bitácora en el mismo lote |
| RNF-017 Pruebas | Dominio en Dart puro; reglas probadas en el emulador |
| RF-028/029 Reportes | Generados en el navegador a partir de los registros consultados |

## 12. Riesgos nuevos de la etapa

| ID | Riesgo | P | I | Nivel | Mitigación |
|---|---|:-:|:-:|:-:|---|
| R-16 | Dependencia del proveedor (Firebase) | 2 | 2 | 4 | Capa de datos detrás de interfaces; respaldo CSV (RF-033) |
| R-17 | El almacenamiento de archivos de Firebase puede exigir plan de pago con tarjeta registrada (V) | 3 | 2 | 6 | Afecta solo a adjuntos (v1.1); decisión diferida en ADR-008 |
| R-18 | Errores en reglas de seguridad exponen datos | 2 | 3 | 6 | Pruebas automatizadas de reglas en el emulador; revisión en Etapa 15 |
| R-19 | Región de datos fuera de México | 2 | 2 | 4 | Elegir la región disponible más cercana (V); confirmar con el área de transparencia (A6) |
| R-20 | Firestore web tiene caché menos robusta que Android | 1 | 1 | 1 | La web (Coordinación) opera con conexión; el modo offline solo es obligatorio en Android |

## 13. Criterios de salida de la Etapa 5

- [x] Enfoque arquitectónico definido y justificado
- [x] Componentes y responsabilidades por capa
- [x] Interfaces principales definidas
- [x] Tecnologías elegidas por características, costo y mantenimiento
- [x] Decisiones registradas en ADR
- [x] Capacidad verificada contra el plan gratuito
- [x] Requisitos críticos trazados a la arquitectura
- [x] Aprobación del desarrollador responsable · 2026-11-18
