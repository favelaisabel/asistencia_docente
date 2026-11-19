import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

let entorno;

beforeAll(async () => {
  entorno = await initializeTestEnvironment({
    projectId: 'demo-asistencia-docente',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await entorno.clearFirestore();
});

afterAll(async () => {
  await entorno.cleanup();
});

describe('Reglas base (C-05: todo denegado por defecto)', () => {
  test('PR-01 sin sesión no se puede leer ni escribir', async () => {
    const db = entorno.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'registros/A101_20270115_09')));
    await assertFails(setDoc(doc(db, 'registros/A101_20270115_09'), { x: 1 }));
  });

  test('con sesión pero sin reglas abiertas tampoco', async () => {
    const db = entorno.authenticatedContext('usuario-1').firestore();
    await assertFails(getDoc(doc(db, 'config/sistema')));
    await assertFails(setDoc(doc(db, 'config/sistema'), { x: 1 }));
  });
});
