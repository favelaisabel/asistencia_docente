# 08_SEGURIDAD_CONTINUIDAD — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo II · Etapa 8
**Versión:** 1 · **Fecha:** 2026-11-18 · **Estado:** Cerrada
**Entradas:** [02_VIABILIDAD_RIESGOS.md](02_VIABILIDAD_RIESGOS.md) · [03_REQUISITOS.md](03_REQUISITOS.md) · [05_ARQUITECTURA.md](05_ARQUITECTURA.md) · [05_ADR.md](05_ADR.md) · [06_MODELO_DATOS.md](06_MODELO_DATOS.md)

Convenciones: **(V)** verificar en la Etapa 10 contra la documentación vigente del proveedor o con el área jurídica/transparencia.

---

## 1. Objetivo de la etapa

Diseñar desde ahora los controles de autenticación, autorización, secretos, validación de entradas, auditoría, privacidad, respaldos, recuperación e incidentes, de modo que cada riesgo conocido tenga un control planificado.

## 2. Activos a proteger

| Activo | Por qué importa | Clasificación |
|---|---|---|
| Registros de asistencia | Evidencia para **actas administrativas** | Confidencial · integridad crítica |
| Bitácora | Prueba de quién cambió qué | Confidencial · integridad crítica |
| Datos personales de docentes (nombre, núm. de empleado, correo, horario) | Datos personales | Confidencial |
| Justificaciones y adjuntos (v1.1) | Pueden contener **datos de salud** | **Sensible** |
| Credenciales y sesiones | Acceso a todo lo anterior | Secreto |
| Horario oficial | Base del recorrido | Interno |

## 3. Modelo de amenazas

| ID | Amenaza | Actor | Activo | Control (ver §4–§8) |
|---|---|---|---|---|
| A-01 | Un docente consulta registros de otros docentes | Docente | Registros | C-05, C-06 |
| A-02 | Alguien altera un registro para perjudicar o favorecer a un docente | Encargado / Coordinación / externo | Registros | C-08, C-09, C-10 |
| A-03 | Se borra evidencia | Cualquiera | Registros, bitácora | C-09 |
| A-04 | Se fabrican registros de días pasados | Encargado | Registros | C-11 |
| A-05 | Se manipula el reloj del celular | Encargado | Registros | C-10 |
| A-06 | Robo o pérdida del celular del encargado | Externo | Sesión, registros sin enviar | C-03, C-04 |
| A-07 | Robo de contraseña | Externo | Cuentas | C-01, C-02 |
| A-08 | Usuario dado de baja sigue entrando | Exempleado | Todo | C-04 |
| A-09 | Peticiones directas a la base saltándose la app | Externo con conocimientos | Todo | C-05, C-12 |
| A-10 | Fórmulas maliciosas en Excel (inyección CSV) | Quien escribe observaciones o el archivo de horario | Equipo de Coordinación | C-14 |
| A-11 | Archivo de horario malformado o malicioso | Coordinación (error) | Horario | C-13 |
| A-12 | Dependencias con vulnerabilidades | Terceros | Aplicación | C-17 |
| A-13 | Credenciales de administración en el repositorio | Desarrollador (error) | Proyecto completo | C-16 |
| A-14 | Pérdida de la cuenta dueña del proyecto | Desarrollador | Proyecto completo | C-20 |
| A-15 | Exposición de datos de salud en adjuntos | Cualquiera | Justificaciones | C-07 (v1.1) |

## 4. Autenticación

| ID | Control | Detalle | Requisito |
|---|---|---|---|
| C-01 | Política de contraseñas | Mínimo 10 caracteres, con letras y números; se configura en Firebase Auth (V) | RNF-005 |
| C-02 | Protección contra enumeración y fuerza bruta | Mensaje genérico "Correo o contraseña incorrectos"; protección de enumeración de correos y limitación de intentos del proveedor activadas (V) | RF-001 |
| C-03 | Celular del encargado protegido | Requisito operativo: bloqueo de pantalla con PIN/huella. La sesión persiste (RF-005) solo en ese dispositivo | R-03 |
| C-04 | Baja inmediata | Al desactivar a un usuario: `usuarios.activo = false` (las reglas lo bloquean al instante) + deshabilitar la cuenta en Firebase Auth y revocar sesiones | RF-004 |
| — | Contraseñas | Las almacena y cifra Firebase Auth; la app nunca las guarda ni las registra | RNF-005 |

## 5. Autorización (reglas de seguridad de Firestore)

| ID | Control | Requisito |
|---|---|---|
| C-05 | **Todo acceso se valida en el servidor** con reglas; por defecto todo está denegado y solo se abre lo listado en 06_MODELO_DATOS §8 | RNF-007 |
| C-06 | Cada regla verifica: sesión iniciada, perfil existente, `activo == true` y rol | RN-010 |
| C-07 | (v1.1) Adjuntos: solo el docente dueño y Coordinación; enlaces no públicos | RNF-019 |

### 5.1 Reglas clave de `registros` y `bitacora`

| Operación | Quién | Condiciones verificadas por las reglas |
|---|---|---|
| Crear registro | ENC | ID = `{aulaId}_{AAAAMMDD}_{HH}` coherente con los campos · `version == 1` · `registradoPor == uid` · `horaServidor == request.time` · enumeraciones válidas · `suplenteNombre` presente si `SUPLENTE` · `observacion` ≤ 250 · fecha no anterior a 2 días (C-11) · existe en el mismo lote `bitacora/{id}_v1` |
| Actualizar registro | ENC | Mismo día del registro (tolerancia para sincronizar sin conexión, ver §5.2) · `version` aumenta en 1 · existe `bitacora/{id}_v{n}` en el mismo lote · no cambia aula, fecha, hora ni `registradoPor` |
| Actualizar registro | COO | `version` aumenta en 1 · existe la entrada de bitácora con `motivo` no vacío |
| Borrar registro | Nadie | Denegado |
| Crear bitácora | ENC, COO | ID = `{registroId}_v{n}` y el registro, después del lote, tiene `version == n` |
| Modificar o borrar bitácora | Nadie | Denegado |
| Leer registros | ENC | Solo de los últimos 2 días |
| Leer registros | DOC (v1.1) | Solo donde `docenteId` = el suyo |
| Leer registros y bitácora | COO | Todos |

### 5.2 Refinamiento de RN-009 (corrección del encargado)

Si las reglas rechazaran una corrección hecha **sin conexión** que se sincroniza después del bloque, se perdería en silencio. Por eso:

- **En la app:** el encargado solo puede corregir mientras dura el bloque (RN-009 tal como se aprobó).
- **En el servidor:** se acepta la actualización del encargado hasta el final del día del registro, para tolerar la sincronización tardía.
- **Riesgo residual:** un encargado con conocimientos técnicos podría corregir más tarde ese mismo día. Queda **visible en la bitácora** con hora del servidor. Riesgo aceptado (bajo).

## 6. Integridad de la evidencia

| ID | Control | Requisito |
|---|---|---|
| C-08 | Toda escritura de un registro va acompañada de su entrada de bitácora en el mismo lote atómico | RN-008, RNF-009 |
| C-09 | Registros y bitácora **no se pueden borrar**; la bitácora no se puede modificar | RN-008, RNF-009 |
| C-10 | Hora del servidor obligatoria + desfase del reloj medido; marca "Hora dudosa" (06_MODELO_DATOS §6) | RNF-008 |
| C-11 | No se pueden crear registros con fecha de más de 2 días atrás ni futura | A-04 |

## 7. Validación de entradas y archivos

| ID | Control | Detalle |
|---|---|---|
| C-12 | Validación doble | En la app (mensajes claros) **y** en las reglas (tipos, enumeraciones, longitudes). La app nunca es la única barrera |
| C-13 | Importación de horario | Solo `.xlsx`/`.csv`, máx. 2 MB; columnas exactas; tipos y rangos validados; aula y docente existentes; sin traslapes (RN-011); nada se guarda si hay un error |
| C-14 | Exportación a Excel/CSV segura | Toda celda de texto que empiece con `=`, `+`, `-`, `@`, tabulador o retorno se antepone con `'` para que Excel no la ejecute como fórmula |
| C-15 | Texto libre | Se muestra siempre como texto (Flutter no interpreta HTML); longitudes limitadas |

## 8. Secretos, dependencias y configuración

| ID | Control | Detalle |
|---|---|---|
| C-16 | Sin secretos en el repositorio | La configuración de Firebase del cliente es pública por diseño; la seguridad está en las reglas. **Nunca** se suben claves de cuenta de servicio (scripts de migración/restauración): van fuera del repositorio y en `.gitignore` |
| — | Claves de API restringidas | Restringir la clave del cliente a la app Android (huella del certificado) y a los dominios del hosting (V) |
| — | Verificación de la app | Evaluar Firebase App Check (Play Integrity / reCAPTCHA) para que solo la app oficial acceda (V; sin costo dentro de cuotas) |
| C-17 | Dependencias | Versiones fijadas (`pubspec.lock` en el repositorio); revisión mensual con `dart pub outdated`; solo paquetes con mantenimiento activo |
| — | Entornos separados | Proyecto Firebase de **desarrollo** (emulador y datos ficticios) y de **producción**; nunca datos reales en desarrollo |
| — | Registros técnicos (logs) | Sin datos personales, contraseñas ni contenido de justificaciones |

## 9. Privacidad y protección de datos personales

**Marco aplicable:** institución **pública** en México → Ley General de Protección de Datos Personales en Posesión de Sujetos Obligados (V: confirmar versión vigente y obligaciones con el área de transparencia de la universidad).

### 9.1 Inventario de datos

| Dato | Titular | Finalidad | ¿Sensible? | Se recaba en |
|---|---|---|---|---|
| Nombre, núm. de empleado | Docente | Identificar al docente en el registro | No | Horario (importación) |
| Correo institucional | Usuarios | Acceso al sistema | No | Pre-registro |
| Asistencia, retardos, faltas | Docente | Control de asistencia y, en su caso, actas | No (pero de alto impacto) | App del encargado |
| Nombre del suplente | Suplente | Identificar quién impartió la clase | No | App del encargado |
| Motivo y adjunto de justificación (v1.1) | Docente | Resolver la justificación | **Puede serlo** (salud) | Portal docente |

### 9.2 Controles de privacidad

| ID | Control |
|---|---|
| P-01 | **Minimización:** no se recaban fotos, ubicación, biometría ni datos que no estén en el inventario (X-04) |
| P-02 | **Aviso de privacidad** (integral y simplificado) aprobado por transparencia **antes de producción** (A6, RES-06) — borrador en el Anexo A |
| P-03 | **Acceso mínimo:** cada rol ve solo lo necesario (§5) |
| P-04 | **Derechos ARCO:** los docentes consultan sus registros en el portal (v1.1); solicitudes de rectificación por el procedimiento de justificación o por Coordinación con bitácora |
| P-05 | **Retención:** plazo por definir con transparencia (RNF-018); al vencer, se exporta y archiva según la institución |
| P-06 | **Proveedor en la nube:** Google actúa como encargado del tratamiento; elegir la región disponible más cercana y confirmar con transparencia que el almacenamiento fuera de la institución es aceptable (R-19) |
| P-07 | **Datos de salud (v1.1):** acceso restringido, sin vista previa en listados, decisión de almacenamiento en ADR-008 |

## 10. Respaldo y continuidad

### 10.1 Objetivos de recuperación

| Objetivo | Valor | Justificación |
|---|---|---|
| **RPO** (pérdida máxima aceptable) | **1 día** de registros · 1 semana de bitácora | Reporte diario en Excel descargado cada día + respaldo completo semanal |
| **RTO** (tiempo máximo para volver a operar) | **1 día hábil** | Durante la falla opera el procedimiento de contingencia (libreta) |

### 10.2 Estrategia de respaldo

| Respaldo | Frecuencia | Contenido | Responsable | Dónde se guarda |
|---|---|---|---|---|
| Reporte diario (Excel) | Diario | Registros del día | Coordinación | Unidad institucional |
| **Respaldo completo (CSV)** | Semanal | Registros, bitácora, horario, catálogos | Coordinación | Unidad institucional, fuera de Firebase |

> **Hallazgo:** el respaldo completo (RF-033) está planeado para la **v1.1**, pero el MVP ya maneja evidencia para actas. Ver **solicitud de cambio CR-001** en §11.

La exportación administrada de Firestore requiere plan de pago (V), por eso el respaldo se hace con exportación CSV desde la app.

### 10.3 Restauración

1. Crear (o limpiar) el proyecto de destino.
2. Ejecutar el script de restauración `app/tool/restaurar.dart` con el CSV más reciente (usa credenciales de administrador guardadas fuera del repositorio).
3. Verificar conteos contra el respaldo y revisar 10 registros al azar.
4. Capturar los registros de contingencia (libreta) como `origen = MANUAL`.
5. **La restauración se prueba en un entorno aislado en la Etapa 16** (requisito de MIDE-IA 2.0).

### 10.4 Procedimiento de contingencia (A7, E-11)

1. Si la app falla, el encargado sigue el recorrido en la **libreta de contingencia** (aula, docente, hora, situación).
2. Avisa a Coordinación.
3. Al restablecerse, Coordinación captura lo anotado como `origen = MANUAL` (queda marcado y en bitácora).

### 10.5 Respuesta a incidentes

| Incidente | Primera acción (≤ 1 h) | Responsable | Después |
|---|---|---|---|
| Celular perdido o robado | Desactivar al encargado (C-04) y asignar el rol a otro dispositivo/usuario | Coordinación | Revisar registros sin enviar y capturar desde contingencia |
| Contraseña comprometida | Desactivar la cuenta y revocar sesiones; restablecer contraseña | Coordinación / desarrollador | Revisar bitácora de esa cuenta |
| Registro alterado indebidamente | Revisar bitácora; corregir con motivo | Coordinación | Si hay acta en curso, informar con la bitácora |
| Exposición de datos personales | Cerrar el acceso (reglas/cuenta) | Desarrollador | Avisar al área de transparencia, que determina las notificaciones que exige la ley |
| Servicio de Firebase caído | Contingencia (libreta) | Encargado | Captura posterior |
| Error que corrompe datos | Detener cambios; restaurar desde respaldo (§10.3) | Desarrollador | Análisis de causa y prueba de regresión |

### 10.6 Continuidad de la administración

| ID | Control |
|---|---|
| C-20 | El proyecto de Firebase tiene **al menos dos propietarios**: el desarrollador y una cuenta institucional (p. ej. de Coordinación o TI), para no depender de una sola persona |
| — | Al menos **dos usuarios con rol COO** en producción |
| — | Procedimientos de este documento disponibles para Coordinación en `docs/` |

## 11. Solicitud de cambio derivada

**CR-001 — Adelantar el respaldo completo (RF-033) al MVP**

| Campo | Valor |
|---|---|
| Origen | Etapa 8, §10.2 |
| Motivo | El MVP ya genera evidencia para actas; sin respaldo completo, la bitácora no tiene copia fuera de Firebase |
| Cambio | Mover RF-033 y RNF-014 de la v1.1 (EP8) al MVP (EP6) |
| Esfuerzo | ~0.5 semana (reutiliza la exportación de reportes) |
| Impacto | MVP ≈ 9 semanas; la holgura de la v1.1 baja a ~3 semanas |
| Afecta | 04_ALCANCE_MVP §3 y §4 |
| Estado | **Aprobada** (2026-11-18) — aplicada en 04_ALCANCE_MVP v2 |

## 12. Matriz de riesgos → controles

| Riesgo (02_VIABILIDAD / 05) | Controles |
|---|---|
| R-02 Sin señal | ADR-003, §5.2, contingencia §10.4 |
| R-03 Pérdida del celular | C-03, C-04, §10.5 |
| R-04 Registros alterados | C-08, C-09, C-10, C-11 |
| R-05 Protección de datos | P-01 a P-07, C-05, C-06 |
| R-06 Autorización institucional | P-02, RES-06 |
| R-08 Plan gratuito | §10.2 (respaldo fuera de Firebase) |
| R-11 Hora manipulada | C-10 |
| R-12 Falla de la app | §10.4 |
| R-16 Dependencia del proveedor | Respaldo CSV, capa de datos aislada |
| R-17 Almacenamiento de adjuntos | ADR-008 (v1.1) |
| R-18 Errores en reglas | Pruebas automáticas de reglas en emulador (Etapa 12), revisión en Etapa 15 |
| R-19 Región de datos | P-06 |

## 13. Verificaciones planificadas (para Etapas 12, 14 y 15)

| Verificación | Cómo |
|---|---|
| Un docente no lee registros de otro | Prueba de reglas en emulador |
| Nadie borra registros ni bitácora | Prueba de reglas en emulador |
| Una corrección sin bitácora es rechazada | Prueba de reglas en emulador |
| Un usuario inactivo no lee ni escribe | Prueba de reglas en emulador |
| Registro con fecha antigua rechazado | Prueba de reglas en emulador |
| Inyección de fórmulas neutralizada | Prueba unitaria de exportación |
| Restauración desde CSV | Prueba en entorno aislado (Etapa 16) |
| Sin secretos en el repositorio | Revisión de historial Git antes de cada versión |

## 14. Criterios de salida de la Etapa 8

- [x] Activos y amenazas identificados
- [x] Autenticación y autorización diseñadas (reglas por colección y operación)
- [x] Gestión de secretos definida
- [x] Validación de entradas y archivos definida
- [x] Auditoría e integridad de evidencia definidas
- [x] Privacidad: inventario de datos, marco legal y controles
- [x] Respaldo, RPO/RTO, restauración y contingencia
- [x] Respuesta a incidentes
- [x] Cada riesgo conocido con control planificado
- [x] Decisión sobre CR-001: aprobada (2026-11-18)
- [x] Aprobación del desarrollador responsable · 2026-11-18

---

## Anexo A — Borrador de aviso de privacidad simplificado

> **Borrador para revisión del área de transparencia. No usar hasta su aprobación.**

**[NOMBRE DE LA UNIVERSIDAD]**, con domicilio en **[DOMICILIO]**, es responsable del tratamiento de los datos personales que se recaban mediante el sistema de control de asistencia docente.

**Datos que se tratan:** nombre, número de empleado, correo institucional, horario asignado y registros de asistencia (asistencia, retardos, faltas, suplencias). En el caso de justificaciones, el motivo y, en su caso, el documento que el docente decida adjuntar, el cual podría contener datos personales sensibles.

**Finalidades:** verificar la impartición de clases conforme al horario oficial; generar reportes para Coordinación académica; atender justificaciones; y, en su caso, sustentar los procedimientos administrativos que correspondan conforme a la normativa institucional.

**Transferencias:** **[DEFINIR CON TRANSPARENCIA]**.

**Derechos ARCO:** puede ejercer sus derechos de acceso, rectificación, cancelación y oposición ante **[UNIDAD DE TRANSPARENCIA, CORREO Y DOMICILIO]**.

**Aviso integral:** disponible en **[ENLACE]**.
