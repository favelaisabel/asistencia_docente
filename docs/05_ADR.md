# 05_ADR — Registro de decisiones de arquitectura

**Metodología:** MIDE-IA 2.0 · Ciclo II · Etapa 5
**Fecha:** 2026-11-18 · Relacionado: [05_ARQUITECTURA.md](05_ARQUITECTURA.md)

Formato de cada decisión: Contexto · Opciones · Decisión · Consecuencias. Estado: Propuesta → Aceptada → Sustituida.

---

## ADR-001 — Una sola base de código Flutter para Android y web (monolito modular)

**Estado:** Aceptada (2026-11-18)

**Contexto:** 1 desarrollador, 2–3 meses (RES-01, RES-02). El encargado usa Android; docentes y Coordinación, web (A2). Flutter ya está instalado.

**Opciones:**
1. Flutter para Android y web en un solo proyecto.
2. Flutter para Android + otra tecnología web (p. ej. React).
3. Solo web (PWA) para todos.

**Decisión:** Opción 1, con dos puntos de entrada (`main_movil.dart`, `main_web.dart`) y módulos por funcionalidad.

**Consecuencias:**
- ➕ Un lenguaje, reglas de negocio compartidas, menos mantenimiento.
- ➕ App Android con capacidades nativas de persistencia local.
- ➖ La web de Flutter carga más lento que una web tradicional; aceptable para pocos usuarios internos.
- ❌ Opción 3 descartada: el modo sin conexión de una PWA es menos confiable para R-02 (nivel 9).

---

## ADR-002 — Firebase como backend gestionado

**Estado:** Aceptada (2026-11-18)

**Contexto:** Se requiere autenticación, base de datos, sincronización sin conexión, hora del servidor y hosting, con $0 (RES-03) y sin servidor que mantener.

**Opciones:**

| Criterio | Firebase (Auth + Firestore + Hosting) | Supabase | Backend propio (API + BD) |
|---|---|---|---|
| Sin conexión en Android | ✅ Integrado en el SDK | ❌ Hay que construirlo (BD local + sincronización) | ❌ Hay que construirlo |
| Costo | $0 en plan gratuito | $0 en plan gratuito | Requiere hosting |
| Pausa por inactividad | No | Sí, en plan gratuito (afecta vacaciones) | Depende |
| Modelo de datos | Documentos (NoSQL) | Relacional (PostgreSQL) | A elección |
| Permisos en servidor | Reglas de seguridad | Políticas RLS | Código propio |
| Esfuerzo para 1 desarrollador | Bajo | Medio | Alto |
| Almacenamiento de archivos gratis | ⚠️ Puede requerir plan con tarjeta (V) | ✅ | Depende |

**Decisión:** Firebase. El criterio decisivo es el modo sin conexión integrado, que ataca el riesgo más alto (R-02) con el menor esfuerzo.

**Consecuencias:**
- ➕ Sincronización, sesión persistente y hora del servidor resueltas por el proveedor.
- ➖ Modelo de documentos: las relaciones y consultas se diseñan con cuidado (Etapa 6).
- ➖ Dependencia del proveedor (R-16), mitigada con capa de datos aislada y respaldo CSV.
- ➖ Adjuntos de v1.1 pendientes (ADR-008).

---

## ADR-003 — Offline-first con la persistencia local de Firestore

**Estado:** Aceptada (2026-11-18)

**Contexto:** RNF-001 exige operar un turno completo sin señal.

**Opciones:** (1) Caché persistente de Firestore; (2) BD local propia (SQLite) + sincronización manual.

**Decisión:** Opción 1. Las escrituras se guardan localmente y se envían en cola al recuperar la conexión. El horario del día se precarga al iniciar sesión con señal.

**Consecuencias:**
- ➕ Sin código de sincronización propio.
- ➖ Las transacciones de Firestore no funcionan sin conexión → no se usan en el flujo del encargado; la unicidad se garantiza con identificadores deterministas (ADR-004).
- ➖ Debe probarse explícitamente: cerrar la app y reiniciar el celular con registros pendientes (E-02).

---

## ADR-004 — Reglas de negocio en el dominio (Dart puro) y situación calculada al leer

**Estado:** Aceptada (2026-11-18)

**Contexto:** RN-003 convierte "aún no llega" en falta al minuto 30. Los procesos programados en servidor de Firebase requieren plan de pago. RNF-017 exige reglas probadas.

**Decisión:**
- Las reglas (RN-002, RN-003, RN-004, RN-011) viven en `dominio/` como funciones puras con pruebas unitarias.
- La **situación efectiva** se calcula al consultar (`CalculadoraSituacion`), no se reescribe en la base de datos.
- Unicidad (RN-006): identificador de documento `{aula}_{AAAAMMDD}_{HH}`.

**Consecuencias:**
- ➕ No se necesitan funciones de servidor; reglas probables sin red.
- ➖ Los reportes y la app deben usar siempre la misma calculadora (no duplicar la regla — principio de la Etapa 12).

---

## ADR-005 — Seguridad con reglas de Firestore y roles en el perfil del usuario

**Estado:** Aceptada (2026-11-18)

**Contexto:** RNF-007 (permisos en servidor), RNF-009 (bitácora inmutable), RN-010. Asignar roles con "custom claims" requiere SDK de administrador o funciones de servidor.

**Decisión:**
- Cada usuario tiene un documento de perfil con su rol (`ENC`, `DOC`, `COO`); las reglas lo consultan.
- Los usuarios se dan de alta por **pre-registro**: Coordinación registra correo y rol; la persona crea su contraseña y su perfil solo puede tomar el rol pre-registrado.
- El primer usuario de Coordinación se crea manualmente en la consola (procedimiento documentado en la Etapa 10).
- Bitácora: solo creación; toda corrección de registro debe escribir su entrada de bitácora en el mismo lote (verificado por las reglas).
- Las reglas se prueban automáticamente en el emulador.

**Consecuencias:**
- ➕ Sin servidor propio; permisos aplicados en el servidor.
- ➖ Cada consulta del rol cuesta una lectura; dentro del margen calculado.
- ➖ Las reglas se vuelven código crítico: requieren pruebas (R-18).

---

## ADR-006 — Riverpod para estado y dependencias; go_router para navegación

**Estado:** Aceptada (2026-11-18)

**Contexto:** Separación de capas (§5) y pruebas.

**Opciones:** setState/Provider, Riverpod, Bloc.

**Decisión:** Riverpod (inyección de repositorios sustituible en pruebas) y go_router (redirección por rol y sesión).

**Consecuencias:** ➕ Repositorios falsos en pruebas; ➖ curva de aprendizaje moderada, mitigada con apoyo de IA y convenciones en la Etapa 11.

---

## ADR-007 — Reportes e importación procesados en el cliente web

**Estado:** Aceptada (2026-11-18)

**Contexto:** RF-010/011 (importación) y RF-028/029 (reportes) sin funciones de servidor.

**Decisión:** El navegador de Coordinación lee/genera los archivos con los paquetes `excel`, `csv`, `pdf` y `file_picker`. Volumen máximo ~2 800 registros por reporte semanal.

**Consecuencias:** ➕ $0 y sin servidor; ➖ reportes de periodos muy largos podrían ser lentos (fuera del MVP; medir en Etapa 16).

---

## ADR-008 — Almacenamiento de adjuntos de justificaciones (v1.1) — DIFERIDA

**Estado:** Diferida hasta antes de iniciar EP7

**Contexto:** RF-025 permite adjuntos de hasta 5 MB. El almacenamiento de archivos de Firebase podría requerir un plan de pago con tarjeta registrada aunque el uso se mantenga en la cuota sin costo (V).

**Opciones a evaluar:**
1. Plan de Firebase con tarjeta + alerta de presupuesto en $0.
2. Servicio de almacenamiento gratuito alterno, solo para adjuntos.
3. Reducir RF-025 a solo texto (requiere solicitud de cambio en la Etapa 3).

**Decisión:** Se decide cuando se planifique EP7. No afecta al MVP.
