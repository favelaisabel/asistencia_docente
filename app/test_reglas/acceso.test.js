import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

// Incremento I1: acceso y roles (RF-001, RF-004; ADR-005; C-04 a C-06, C-21).

const COO = { uid: 'uid-coo', correo: 'coordinacion@demo.edu.mx' };
const ENC = { uid: 'uid-enc', correo: 'encargado@demo.edu.mx' };
const NUEVO = { uid: 'uid-nuevo', correo: 'nuevo@demo.edu.mx' };

let entorno;

function contexto(persona, verificado = true) {
  return entorno
    .authenticatedContext(persona.uid, { email: persona.correo, email_verified: verificado })
    .firestore();
}

async function sembrar(fn) {
  await entorno.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

function perfil(persona, rol, activo = true) {
  return { correo: persona.correo, nombre: `Nombre ${rol}`, rol, activo, creadoEn: new Date(), esquemaVersion: 1 };
}

function preregistro(correo, rol, usado = false) {
  return { correo, nombre: 'Persona Nueva', rol, usado, creadoPor: COO.uid, creadoEn: new Date(), esquemaVersion: 1 };
}

function nuevoPreregistro(correo, rol = 'ENC') {
  return { correo, nombre: 'Persona Nueva', rol, usado: false, creadoPor: COO.uid, creadoEn: serverTimestamp(), esquemaVersion: 1 };
}

function loteCrearPerfil(db, persona, cambios = {}, marcarUsado = true) {
  const lote = writeBatch(db);
  lote.set(doc(db, `usuarios/${persona.uid}`), {
    correo: persona.correo,
    nombre: 'Persona Nueva',
    rol: 'ENC',
    activo: true,
    creadoEn: serverTimestamp(),
    esquemaVersion: 1,
    ...cambios,
  });
  if (marcarUsado) lote.update(doc(db, `preregistros/${persona.correo}`), { usado: true });
  return lote;
}

beforeAll(async () => {
  entorno = await initializeTestEnvironment({
    projectId: 'demo-asistencia-docente',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await entorno.clearFirestore();
  await sembrar(async (db) => {
    await setDoc(doc(db, `usuarios/${COO.uid}`), perfil(COO, 'COO'));
    await setDoc(doc(db, `usuarios/${ENC.uid}`), perfil(ENC, 'ENC'));
  });
});

afterAll(async () => {
  await entorno.cleanup();
});

describe('Pre-registro (RF-004)', () => {
  test('PR-04 Coordinación pre-registra un correo válido', async () => {
    const db = contexto(COO);
    await assertSucceeds(setDoc(doc(db, `preregistros/${NUEVO.correo}`), nuevoPreregistro(NUEVO.correo)));
  });

  test('PR-04 el encargado no puede pre-registrar', async () => {
    const db = contexto(ENC);
    await assertFails(setDoc(doc(db, `preregistros/${NUEVO.correo}`), nuevoPreregistro(NUEVO.correo)));
  });

  test('PR-04 el ID debe ser el correo en minúsculas y con formato válido', async () => {
    const db = contexto(COO);
    await assertFails(setDoc(doc(db, 'preregistros/Nuevo@Demo.edu.mx'), nuevoPreregistro('Nuevo@Demo.edu.mx')));
    await assertFails(setDoc(doc(db, 'preregistros/sin-arroba'), nuevoPreregistro('sin-arroba')));
  });

  test('PR-22 en el MVP no se pre-registran docentes (v1.1)', async () => {
    const db = contexto(COO);
    await assertFails(setDoc(doc(db, `preregistros/${NUEVO.correo}`), nuevoPreregistro(NUEVO.correo, 'DOC')));
  });

  test('PR-04 un pre-registro existente no se sobrescribe', async () => {
    await sembrar((db) => setDoc(doc(db, `preregistros/${NUEVO.correo}`), preregistro(NUEVO.correo, 'ENC')));
    const db = contexto(COO);
    await assertFails(setDoc(doc(db, `preregistros/${NUEVO.correo}`), nuevoPreregistro(NUEVO.correo, 'COO')));
  });

  test('PR-04 Coordinación cancela un pre-registro pendiente, pero no uno usado', async () => {
    await sembrar(async (db) => {
      await setDoc(doc(db, `preregistros/${NUEVO.correo}`), preregistro(NUEVO.correo, 'ENC'));
      await setDoc(doc(db, 'preregistros/usado@demo.edu.mx'), preregistro('usado@demo.edu.mx', 'ENC', true));
    });
    const db = contexto(COO);
    await assertSucceeds(deleteDoc(doc(db, `preregistros/${NUEVO.correo}`)));
    await assertFails(deleteDoc(doc(db, 'preregistros/usado@demo.edu.mx')));
  });
});

describe('Primer acceso: perfil desde el pre-registro (ADR-005, C-21)', () => {
  beforeEach(async () => {
    await sembrar((db) => setDoc(doc(db, `preregistros/${NUEVO.correo}`), preregistro(NUEVO.correo, 'ENC')));
  });

  test('PR-03 con correo confirmado crea su perfil con el rol pre-registrado', async () => {
    const db = contexto(NUEVO);
    await assertSucceeds(loteCrearPerfil(db, NUEVO).commit());
  });

  test('PR-03 no puede asignarse un rol distinto al pre-registrado', async () => {
    const db = contexto(NUEVO);
    await assertFails(loteCrearPerfil(db, NUEVO, { rol: 'COO' }).commit());
  });

  test('PR-03 sin correo confirmado no puede crear su perfil', async () => {
    const db = contexto(NUEVO, false);
    await assertFails(loteCrearPerfil(db, NUEVO).commit());
  });

  test('PR-03 sin pre-registro no puede crear perfil', async () => {
    const intruso = { uid: 'uid-intruso', correo: 'intruso@demo.edu.mx' };
    const db = contexto(intruso);
    await assertFails(loteCrearPerfil(db, intruso, {}, false).commit());
  });

  test('PR-03 debe marcar el pre-registro como usado en el mismo lote', async () => {
    const db = contexto(NUEVO);
    await assertFails(loteCrearPerfil(db, NUEVO, {}, false).commit());
  });

  test('PR-03 no puede crear un perfil a nombre de otro uid', async () => {
    const db = contexto(NUEVO);
    await assertFails(setDoc(doc(db, 'usuarios/otro-uid'), {
      correo: NUEVO.correo, nombre: 'Persona Nueva', rol: 'ENC', activo: true, creadoEn: serverTimestamp(), esquemaVersion: 1,
    }));
  });

  test('PR-03 un pre-registro ya usado no sirve otra vez', async () => {
    await sembrar((db) => updateDoc(doc(db, `preregistros/${NUEVO.correo}`), { usado: true }));
    const db = contexto(NUEVO);
    await assertFails(loteCrearPerfil(db, NUEVO).commit());
  });
});

describe('Lectura de perfiles (RN-010, C-06)', () => {
  test('PR-21 cada usuario lee su propio perfil, no el de otros', async () => {
    const db = contexto(ENC);
    await assertSucceeds(getDoc(doc(db, `usuarios/${ENC.uid}`)));
    await assertFails(getDoc(doc(db, `usuarios/${COO.uid}`)));
    await assertFails(getDocs(collection(db, 'usuarios')));
  });

  test('PR-21 Coordinación lista todos los usuarios', async () => {
    const db = contexto(COO);
    await assertSucceeds(getDocs(collection(db, 'usuarios')));
  });
});

describe('Activación y desactivación (RF-004, C-04)', () => {
  test('PR-18 Coordinación desactiva a otro usuario', async () => {
    const db = contexto(COO);
    await assertSucceeds(updateDoc(doc(db, `usuarios/${ENC.uid}`), { activo: false }));
  });

  test('PR-18 Coordinación no puede desactivarse a sí misma', async () => {
    const db = contexto(COO);
    await assertFails(updateDoc(doc(db, `usuarios/${COO.uid}`), { activo: false }));
  });

  test('PR-18 el encargado no puede desactivar usuarios', async () => {
    const db = contexto(ENC);
    await assertFails(updateDoc(doc(db, `usuarios/${COO.uid}`), { activo: false }));
  });

  test('PR-19 nadie cambia su propio rol, ni Coordinación el de otros', async () => {
    await assertFails(updateDoc(doc(contexto(ENC), `usuarios/${ENC.uid}`), { rol: 'COO' }));
    await assertFails(updateDoc(doc(contexto(COO), `usuarios/${ENC.uid}`), { rol: 'COO' }));
  });

  test('PR-20 nadie borra usuarios', async () => {
    await assertFails(deleteDoc(doc(contexto(COO), `usuarios/${ENC.uid}`)));
    await assertFails(deleteDoc(doc(contexto(ENC), `usuarios/${ENC.uid}`)));
  });

  test('PR-02 Coordinación desactivada pierde sus permisos', async () => {
    await sembrar((db) => updateDoc(doc(db, `usuarios/${COO.uid}`), { activo: false }));
    const db = contexto(COO);
    await assertFails(getDocs(collection(db, 'usuarios')));
    await assertFails(setDoc(doc(db, `preregistros/${NUEVO.correo}`), nuevoPreregistro(NUEVO.correo)));
    // Puede leer su propio perfil para que la app le muestre "cuenta desactivada".
    await assertSucceeds(getDoc(doc(db, `usuarios/${COO.uid}`)));
  });
});
