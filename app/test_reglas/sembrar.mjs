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
const ENCARGADO = { correo: 'encargado@demo.edu.mx', nombre: 'Carlos Medina Ríos' };

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
await escribir(`preregistros/${ENCARGADO.correo}`, {
  correo: ENCARGADO.correo,
  nombre: ENCARGADO.nombre,
  rol: 'ENC',
  usado: false,
  creadoPor: uidCoordinacion,
  creadoEn: ahora,
  esquemaVersion: 1,
});

console.log('Datos de demostración cargados en el emulador:');
console.log(`  Coordinación: ${COORDINACION.correo} / ${COORDINACION.contrasena}`);
console.log(`  Encargado pre-registrado (usar "Primer acceso"): ${ENCARGADO.correo}`);
