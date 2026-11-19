// Carga datos de demostración en el EMULADOR (nunca en producción).
// Crea el primer usuario de Coordinación (ADR-005) y un pre-registro de
// encargado para probar el "Primer acceso".
//
// Uso (con el emulador encendido en otra terminal: npm run emuladores):
//   npm run sembrar

const PROYECTO = 'demo-asistencia-docente';
const AUTH = 'http://127.0.0.1:9099';
const FIRESTORE = 'http://127.0.0.1:8080';
const ADMIN = { Authorization: 'Bearer owner', 'Content-Type': 'application/json' };

const COORDINACION = {
  correo: 'coordinacion@demo.edu.mx',
  contrasena: 'Coordinacion2026',
  nombre: 'Ana Ruiz Campos',
};
const ENCARGADO = {
  correo: 'encargado@demo.edu.mx',
  contrasena: 'Encargado2026',
  nombre: 'Carlos Medina Ríos',
};
const PENDIENTE = { correo: 'nuevo.encargado@demo.edu.mx', nombre: 'Rosa Jiménez Paz' };
const CON_HORARIO = process.argv.includes('--con-horario');

if (!PROYECTO.startsWith('demo-')) {
  throw new Error('Este script solo se ejecuta contra proyectos demo del emulador.');
}

async function peticion(url, opciones) {
  const respuesta = await fetch(url, opciones);
  const cuerpo = await respuesta.json().catch(() => ({}));
  if (!respuesta.ok) {
    throw new Error(`${respuesta.status} ${url}: ${JSON.stringify(cuerpo)}`);
  }
  return cuerpo;
}

async function crearCuentaVerificada({ correo, contrasena }) {
  const base = `${AUTH}/identitytoolkit.googleapis.com/v1`;
  let uid;
  try {
    ({ localId: uid } = await peticion(`${base}/accounts:signUp?key=demo`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: correo, password: contrasena, returnSecureToken: true }),
    }));
  } catch (error) {
    if (!String(error).includes('EMAIL_EXISTS')) throw error;
    ({ localId: uid } = await peticion(`${base}/accounts:signInWithPassword?key=demo`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: correo, password: contrasena, returnSecureToken: true }),
    }));
  }
  await peticion(`${base}/projects/${PROYECTO}/accounts:update`, {
    method: 'POST',
    headers: ADMIN,
    body: JSON.stringify({ localId: uid, emailVerified: true }),
  });
  return uid;
}

function campos(objeto) {
  const fields = {};
  for (const [clave, valor] of Object.entries(objeto)) {
    if (typeof valor === 'boolean') fields[clave] = { booleanValue: valor };
    else if (Number.isInteger(valor)) fields[clave] = { integerValue: String(valor) };
    else if (valor instanceof Date) fields[clave] = { timestampValue: valor.toISOString() };
    else fields[clave] = { stringValue: String(valor) };
  }
  return { fields };
}

async function escribir(ruta, datos) {
  await peticion(
    `${FIRESTORE}/v1/projects/${PROYECTO}/databases/(default)/documents/${ruta}`,
    { method: 'PATCH', headers: ADMIN, body: JSON.stringify(campos(datos)) },
  );
}

const ahora = new Date();
const uidCoordinacion = await crearCuentaVerificada(COORDINACION);

await escribir(`preregistros/${COORDINACION.correo}`, {
  correo: COORDINACION.correo,
  nombre: COORDINACION.nombre,
  rol: 'COO',
  usado: true,
  creadoPor: 'sembrado',
  creadoEn: ahora,
  esquemaVersion: 1,
});
await escribir(`usuarios/${uidCoordinacion}`, {
  correo: COORDINACION.correo,
  nombre: COORDINACION.nombre,
  rol: 'COO',
  activo: true,
  creadoEn: ahora,
  esquemaVersion: 1,
});
const uidEncargado = await crearCuentaVerificada(ENCARGADO);
await escribir(`preregistros/${ENCARGADO.correo}`, {
  correo: ENCARGADO.correo,
  nombre: ENCARGADO.nombre,
  rol: 'ENC',
  usado: true,
  creadoPor: uidCoordinacion,
  creadoEn: ahora,
  esquemaVersion: 1,
});
await escribir(`usuarios/${uidEncargado}`, {
  correo: ENCARGADO.correo,
  nombre: ENCARGADO.nombre,
  rol: 'ENC',
  activo: true,
  creadoEn: ahora,
  esquemaVersion: 1,
});
await escribir(`preregistros/${PENDIENTE.correo}`, {
  correo: PENDIENTE.correo,
  nombre: PENDIENTE.nombre,
  rol: 'ENC',
  usado: false,
  creadoPor: uidCoordinacion,
  creadoEn: ahora,
  esquemaVersion: 1,
});

if (CON_HORARIO) await cargarHorario(uidCoordinacion);

console.log('Datos de demostración cargados en el emulador:');
console.log(`  Coordinación: ${COORDINACION.correo} / ${COORDINACION.contrasena}`);
console.log(`  Encargado:    ${ENCARGADO.correo} / ${ENCARGADO.contrasena}`);
console.log(`  Pre-registro pendiente (usar "Primer acceso"): ${PENDIENTE.correo}`);
if (CON_HORARIO) console.log('  Horario 2026-2 activo: 480 clases, 10 aulas (A101–A110), lunes a sábado.');

// Carga docs/demo/horario_demo.csv como importación activa (06 §7.2).
async function cargarHorario(uid) {
  const { readFileSync } = await import('node:fs');
  const texto = readFileSync(new URL('../../docs/demo/horario_demo.csv', import.meta.url), 'utf8')
    .replace(/^﻿/, '');
  const [encabezado, ...lineas] = texto.trim().split(/\r?\n/);
  const columnas = encabezado.split(',');
  const dias = { lunes: 1, martes: 2, 'miércoles': 3, jueves: 4, viernes: 5, 'sábado': 6 };
  const clases = lineas.map((l) => Object.fromEntries(l.split(',').map((v, i) => [columnas[i], v])));
  const base = `projects/${PROYECTO}/databases/(default)/documents`;
  const escrituras = [];
  const agregar = (ruta, datos) => escrituras.push({ update: { name: `${base}/${ruta}`, ...campos(datos) } });

  agregar('periodos/2026-2', { nombre: '2026-2', fechaInicio: '2026-08-10', fechaFin: '2026-12-11', esquemaVersion: 1 });
  agregar('importaciones/demo', {
    periodoId: '2026-2', archivoNombre: 'horario_demo.csv', totalClases: clases.length,
    estado: 'COMPLETA', creadoPor: uid, creadoEn: new Date(),
  });
  for (const aula of new Set(clases.map((c) => c.aula))) {
    agregar(`aulas/${aula}`, { numero: aula, edificio: 'Principal', activa: true });
  }
  for (const c of clases) {
    agregar(`docentes/${c.num_empleado}`, { numEmpleado: c.num_empleado, nombreCompleto: c.docente, activo: true });
  }
  clases.forEach((c, i) => agregar(`clases/demo-${i}`, {
    importacionId: 'demo', periodoId: '2026-2', aulaId: c.aula, docenteId: c.num_empleado,
    docenteNombre: c.docente, materia: c.materia, grupo: c.grupo, diaSemana: dias[c.dia],
    horaInicio: Number(c.hora_inicio), horaFin: Number(c.hora_fin),
  }));
  agregar('config/sistema', {
    periodoActivoId: '2026-2', importacionActivaId: 'demo', actualizadoEn: new Date(), actualizadoPor: uid,
  });

  for (let i = 0; i < escrituras.length; i += 400) {
    await peticion(`${FIRESTORE}/v1/${base}:commit`, {
      method: 'POST', headers: ADMIN, body: JSON.stringify({ writes: escrituras.slice(i, i + 400) }),
    });
  }
}
