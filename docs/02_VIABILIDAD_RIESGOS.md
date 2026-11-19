# 02_VIABILIDAD_RIESGOS — Control de asistencia docente

**Metodología:** MIDE-IA 2.0 · Ciclo I · Etapa 2
**Versión:** 1 · **Fecha:** 2026-11-09 · **Estado:** Cerrada (ver §8)
**Entrada:** [01_CONTEXTO.md](01_CONTEXTO.md) v3

Convenciones: **(C)** dato confirmado · **(S)** supuesto · **(P)** pendiente.

---

## 1. Objetivo de la etapa

Determinar si es técnica, económica, operativa y legalmente factible construir una solución al problema descrito en 01_CONTEXTO, e identificar los riesgos que deben controlarse.

## 2. Datos de entrada

| Dato | Valor |
|---|---|
| Equipo de desarrollo | 1 desarrollador + asistencia de IA (C) |
| Plazo primera versión funcional | 2–3 meses (C) |
| Presupuesto | $0 — solo servicios gratuitos (C) |
| Dispositivo del encargado | Celular Android (C) |
| Acceso al horario oficial | Sistema escolar; forma de obtenerlo **desconocida** (C) |
| Conectividad en el edificio | Irregular (C) |
| Uso de los datos | Evidencia para actas administrativas (C) |
| Usuarios | 1 encargado, ~N docentes (P), Coordinación académica |
| Herramientas disponibles | Flutter 3.38.9, Dart 3.10.8, Git 2.53 (C, verificado) |
| País / marco legal | México (S) |

## 3. Viabilidad técnica

| Aspecto | Evaluación | Resultado |
|---|---|---|
| Registro en el aula sin conexión | Requiere que el registro se guarde en el dispositivo y se sincronice cuando haya señal. Es un patrón conocido y soportado por herramientas gratuitas. | ✅ Viable — **requisito obligatorio** |
| Volumen de datos | ~560 registros/día (S) ≈ 12 000/mes. Bajo; cabe en planes gratuitos de servicios en la nube. | ✅ Viable |
| Generación de reportes PDF y Excel | Existen bibliotecas gratuitas para generar ambos formatos. | ✅ Viable |
| Acceso de docentes (consultar y justificar) | Los docentes pueden tener Android o iPhone. Publicar en iPhone requiere cuenta de Apple Developer (costo anual) y Mac. Alternativa: acceso por navegador web para docentes y Coordinación. | ⚠️ Viable con ajuste — **docentes y Coordinación por web** |
| Obtener el horario oficial | No se sabe si el sistema escolar permite exportar o integrarse. Alternativa: importar una plantilla Excel/CSV o capturarlo dentro de la app (40 aulas × 2 turnos es manejable). | ⚠️ Viable con ajuste — **importación por plantilla como plan base** |
| Habilidades del equipo | Flutter instalado; desarrollo apoyado por IA. Curva de aprendizaje en sincronización y seguridad. | ⚠️ Viable — mantener la arquitectura simple |

**Conclusión técnica:** viable con ajustes.

## 4. Viabilidad económica

| Concepto | Costo | Observación |
|---|---|---|
| Desarrollo | $0 (tiempo propio) | 2–3 meses de dedicación |
| Backend / base de datos / autenticación | $0 | Plan gratuito de un servicio en la nube; límites suficientes para el volumen estimado. Se elige en Etapa 5. |
| Dispositivo del encargado | $0 | Android existente (personal o institucional) |
| Distribución Android | $0 | Instalación directa (APK). Publicar en Google Play costaría un pago único; **no necesario** para el MVP. |
| Distribución iPhone | Evitado | Se sustituye por acceso web |
| Hosting web para docentes/Coordinación | $0 | Hosting estático gratuito |

**Riesgo económico principal:** que el plan gratuito cambie de condiciones, se suspenda por inactividad o se exceda un límite. Se mitiga con exportaciones periódicas de respaldo y eligiendo en la Etapa 5 un servicio sin suspensión por inactividad.

**Conclusión económica:** viable con $0, con dependencia de servicios gratuitos de terceros.

## 5. Viabilidad operativa

| Aspecto | Evaluación | Resultado |
|---|---|---|
| Adopción por el encargado | La herramienta reduce su trabajo (de escribir a tocar). Probable buena aceptación si es más rápida que la libreta. | ✅ |
| Adopción por docentes | Puede percibirse como mayor vigilancia. Lo compensa que gana un canal para consultar y justificar. | ⚠️ Comunicar beneficios |
| Adopción por Coordinación | Recibe reportes al instante y gestiona justificaciones. | ✅ |
| Continuidad si falla el celular o la app | Debe existir un procedimiento alterno (libreta de contingencia y captura posterior). | ⚠️ Definir procedimiento |
| Actualización del horario por periodo | Alguien debe cargar el horario al inicio de cada periodo. Responsable por definir. | ⚠️ (P) |
| Capacitación | Usuarios pocos y tareas simples; capacitación breve. | ✅ |

**Conclusión operativa:** viable con ajustes.

## 6. Viabilidad legal y de protección de datos

| Aspecto | Evaluación |
|---|---|
| Datos personales | Se tratan nombre del docente, horarios, asistencia y justificaciones (pueden contener motivos médicos o personales → posibles **datos sensibles**). |
| Marco aplicable (S) | México. Si la universidad es **pública**: ley general de protección de datos personales para sujetos obligados. Si es **privada**: ley federal de protección de datos personales en posesión de particulares. **Debe confirmarse con el área jurídica o de transparencia.** |
| Aviso de privacidad | Necesario para docentes antes de operar. |
| Autorización institucional | El uso de los registros como evidencia en actas exige que la institución autorice formalmente el sistema como medio de registro. |
| Integridad de la evidencia | Los registros no deben poder alterarse sin dejar rastro (auditoría). |
| Ubicación de los datos | Servicios gratuitos en la nube pueden almacenar datos fuera de México; verificar si la institución lo permite. |

**Conclusión legal:** viable **condicionado** a la autorización institucional y al aviso de privacidad antes de usarlo en producción. No bloquea el desarrollo del MVP con datos ficticios.

## 7. Matriz de riesgos

Escala: Probabilidad (P) e Impacto (I) en Baja=1, Media=2, Alta=3. Nivel = P × I (1–2 bajo, 3–4 medio, 6–9 alto).

| ID | Riesgo | P | I | Nivel | Responsable | Mitigación |
|---|---|---|---|---|---|---|
| R-01 | No se obtiene el horario del sistema escolar | 2 | 3 | **6 Alto** | Desarrollador | Plantilla Excel/CSV de importación + captura manual en la app como plan base; gestionar exportación con TI como mejora |
| R-02 | Sin señal al registrar en el aula | 3 | 3 | **9 Alto** | Desarrollador | Registro local en el dispositivo y sincronización automática al recuperar conexión |
| R-03 | Pérdida o robo del celular con registros no sincronizados | 1 | 3 | 3 Medio | Encargado | Sincronizar en cuanto haya señal; bloqueo del dispositivo; sesión protegida |
| R-04 | Registros alterados que invaliden actas | 2 | 3 | **6 Alto** | Desarrollador | Fecha/hora automáticas, registros no editables por el encargado tras cierto tiempo, bitácora de cambios |
| R-05 | Incumplimiento de protección de datos | 2 | 3 | **6 Alto** | Desarrollador / Jurídico | Aviso de privacidad, control de acceso por rol, mínimo de datos, confirmar marco legal |
| R-06 | La institución no autoriza el sistema | 2 | 3 | **6 Alto** | Desarrollador / Coordinación | Presentar el proyecto a Coordinación antes de la Etapa 3; desarrollar MVP con datos ficticios |
| R-07 | Plazo de 2–3 meses insuficiente para un solo desarrollador | 2 | 2 | 4 Medio | Desarrollador | MVP reducido (Etapa 4), incrementos pequeños, apoyo de IA, arquitectura simple |
| R-08 | Cambio de condiciones o suspensión del plan gratuito | 2 | 2 | 4 Medio | Desarrollador | Elegir servicio sin pausa por inactividad; respaldos exportables periódicos |
| R-09 | Docentes con iPhone no pueden instalar la app | 3 | 2 | **6 Alto** | Desarrollador | Acceso web para docentes y Coordinación |
| R-10 | Resistencia de docentes | 2 | 2 | 4 Medio | Coordinación | Comunicar beneficios (consulta y justificación), transparencia del proceso |
| R-11 | Hora del celular manipulada | 2 | 3 | **6 Alto** | Desarrollador | Registrar también la hora del servidor al sincronizar y señalar discrepancias |
| R-12 | Falla de la app durante un recorrido | 2 | 2 | 4 Medio | Encargado | Procedimiento de contingencia: libreta y captura posterior marcada como "manual" |
| R-13 | Inexperiencia en sincronización y seguridad | 2 | 2 | 4 Medio | Desarrollador | Usar servicios que resuelven sincronización y autenticación; pruebas por incremento |

## 8. Decisión

### Resultado: **VIABLE CON AJUSTES**

Ajustes obligatorios que pasan a las siguientes etapas:

| # | Ajuste | Afecta a |
|---|---|---|
| A1 | El registro debe funcionar **sin conexión** y sincronizarse después | Requisitos (RNF), Arquitectura |
| A2 | Encargado usa **app Android**; docentes y Coordinación usan **acceso web** | Requisitos, Arquitectura |
| A3 | Horario oficial por **importación de plantilla Excel/CSV** (plan base); integración con sistema escolar queda como mejora futura | Requisitos, Alcance |
| A4 | Solo **servicios gratuitos**; respaldos exportables periódicos | Arquitectura, Operación |
| A5 | **Integridad de evidencia**: hora automática, bitácora de cambios, restricción de edición | Requisitos, Seguridad |
| A6 | **Aviso de privacidad y autorización institucional** antes de producción | Seguridad, Despliegue |
| A7 | Procedimiento de **contingencia** ante falla de la app | Operación |
| A8 | **MVP reducido** acorde a 2–3 meses y un desarrollador | Alcance |

### Condiciones para producción (no bloquean el desarrollo)

- Autorización formal de la institución.
- Confirmación del marco legal aplicable (pública/privada).
- Aviso de privacidad aprobado.

### Pendientes

| # | Pendiente | Cuándo |
|---|---|---|
| 1 | Número de docentes | Etapa 3 |
| 2 | Responsable de cargar el horario cada periodo | Etapa 3 |
| 3 | ¿La universidad es pública o privada? | Antes de Etapa 8 |
| 4 | Consultar a TI si el sistema escolar exporta el horario | En paralelo |

## 9. Criterios de salida de la Etapa 2

- [x] Viabilidad técnica evaluada
- [x] Viabilidad económica evaluada
- [x] Viabilidad operativa evaluada
- [x] Aspectos legales y de protección de datos identificados
- [x] Riesgos con probabilidad, impacto, responsable y mitigación
- [x] Decisión explícita: viable con ajustes
- [x] Ajustes trasladados a las etapas siguientes

**Aprobó:** desarrollador responsable · 2026-11-09
