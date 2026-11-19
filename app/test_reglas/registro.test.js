import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

// Incrementos I2–I5: horario, registros y bitácora (08_SEGURIDAD_CONTINUIDAD §5.1).

const COO = { uid: 'uid-coo', correo: 'coordinacion@demo.edu.mx' };
const ENC = { uid: 'uid-enc', correo: 'encargado@demo.edu.mx' };
const HORA = 9;
let entorno;

function contexto(persona) {
  return entorno
    .authenticatedContext(persona.uid, { email: persona.correo, email_verified: true })
    .firestore();
}

async function sembrar(fn) {
  await entorno.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

// Día de negocio en México (UTC−6) desplazado `dias` días.
function diaNegocio(dias = 0) {
  const local = new Date(Date.now() - 6 * 3600e3 + dias * 86400e3);
  const fecha = local.toISOString().slice(0, 10);
  const fechaTs = Timestamp.fromMillis(Date.parse(`${fecha}T06:00:00Z`));
  return { fecha, fechaTs, id: `A101_${fecha.replaceAll('-', '')}_09` };
}

function datosRegistro(dia, persona, cambios = {}) {
  return {
    periodoId: 'p1', claseId: 'c1', aulaId: 'A101', fecha: dia.fecha, fechaTs: dia.fechaTs,
    hora: HORA, turno: 'MAT', docenteId: '1001', docenteNombre: 'Laura Pérez Soto',
    materia: 'Cálculo', grupo: '1A', estadoCaptura: 'PRESENTE', suplenteNombre: '',
    observacion: '', horaDispositivo: Timestamp.now(), horaServidor: serverTimestamp(),
    llegadaDispositivo: null, desfaseRelojMs: 0, capturadoSinConexion: false, origen: 'APP',
    registradoPor: persona.uid, version: 1, actualizadoPor: persona.uid,
    actualizadoEn: serverTimestamp(), justificacionEstado: 'NINGUNA', esquemaVersion: 1,
    ...cambios,
  };
}

function datosBitacora(id, version, persona, rol, cambios = {}) {
  return {
    registroId: id, version, accion: version === 1 ? 'CREAR' : 'CORREGIR', antes: {},
    despues: { estadoCaptura: 'PRESENTE' }, motivo: '', usuarioUid: persona.uid,
    usuarioNombre: 'X', usuarioRol: rol, horaServidor: serverTimestamp(), ...cambios,
  };
}

function loteCrear(db, dia, persona = ENC, rol = 'ENC', cambios = {}, conBitacora = true) {
  const lote = writeBatch(db);
  lote.set(doc(db, `registros/${dia.id}`), datosRegistro(dia, persona, cambios));
  if (conBitacora) lote.set(doc(db, `bitacora/${dia.id}_v1`), datosBitacora(dia.id, 1, persona, rol));
  return lote;
}

function loteCorregir(db, dia, persona, rol, version, cambios = {}, bitacora = {}) {
  const lote = writeBatch(db);
  lote.update(doc(db, `registros/${dia.id}`), {
    estadoCaptura: 'SIN_DOCENTE', version, actualizadoPor: persona.uid,
    actualizadoEn: serverTimestamp(), ...cambios,
  });
  lote.set(doc(db, `bitacora/${dia.id}_v${version}`), datosBitacora(dia.id, version, persona, rol, bitacora));
  return lote;
}

async function sembrarRegistro(dia, extra = {}) {
  await sembrar(async (db) => {
    await setDoc(doc(db, `registros/${dia.id}`), {
      ...datosRegistro(dia, ENC), horaServidor: Timestamp.now(), actualizadoEn: Timestamp.now(), ...extra,
    });
    await setDoc(doc(db, `bitacora/${dia.id}_v1`), { ...datosBitacora(dia.id, 1, ENC, 'ENC'), horaServidor: Timestamp.now() });
  });
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
    const ahora = new Date();
    await setDoc(doc(db, `usuarios/${COO.uid}`), { correo: COO.correo, nombre: 'Ana', rol: 'COO', activo: true, creadoEn: ahora, esquemaVersion: 1 });
    await setDoc(doc(db, `usuarios/${ENC.uid}`), { correo: ENC.correo, nombre: 'Carlos', rol: 'ENC', activo: true, creadoEn: ahora, esquemaVersion: 1 });
  });
});

afterAll(async () => {
  await entorno.cleanup();
});

describe('Horario (I2)', () => {
  const clase = (cambios = {}) => ({
    importacionId: 'imp1', periodoId: 'p1', aulaId: 'A101', docenteId: '1001',
    docenteNombre: 'Laura Pérez Soto', materia: 'Cálculo', grupo: '1A',
    diaSemana: 1, horaInicio: 7, horaFin: 9, ...cambios,
  });

  test('PR-05 solo Coordinación escribe catálogos y configuración', async () => {
    await assertSucceeds(setDoc(doc(contexto(COO), 'aulas/A101'), { numero: 'A101', edificio: 'Principal', activa: true }));
    await assertFails(setDoc(doc(contexto(ENC), 'aulas/A102'), { numero: 'A102', edificio: 'Principal', activa: true }));
    await assertFails(setDoc(doc(contexto(ENC), 'config/sistema'), {
      periodoActivoId: 'p1', importacionActivaId: 'x', actualizadoEn: serverTimestamp(), actualizadoPor: ENC.uid,
    }));
  });

  test('PR-05 las clases solo se agregan a una importación en carga', async () => {
    const db = contexto(COO);
    await assertSucceeds(setDoc(doc(db, 'importaciones/imp1'), {
      periodoId: 'p1', archivoNombre: 'horario.xlsx', totalClases: 1, estado: 'CARGANDO',
      creadoPor: COO.uid, creadoEn: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(db, 'clases/c1'), clase()));
    await assertFails(setDoc(doc(contexto(ENC), 'clases/c2'), clase()));
    await assertFails(setDoc(doc(db, 'clases/c3'), clase({ horaInicio: 6 })));
    await assertSucceeds(updateDoc(doc(db, 'importaciones/imp1'), { estado: 'COMPLETA' }));
    await assertFails(setDoc(doc(db, 'clases/c4'), clase()));
    await assertFails(deleteDoc(doc(db, 'clases/c1')));
  });

  test('PR-05 un lote grande de clases cabe en los límites de las reglas', async () => {
    const db = contexto(COO);
    await setDoc(doc(db, 'importaciones/imp1'), {
      periodoId: 'p1', archivoNombre: 'h.csv', totalClases: 400, estado: 'CARGANDO',
      creadoPor: COO.uid, creadoEn: serverTimestamp(),
    });
    const lote = writeBatch(db);
    for (let i = 0; i < 400; i++) lote.set(doc(db, `clases/c${i}`), clase({ aulaId: `A${i}` }));
    await assertSucceeds(lote.commit());
  });

  test('el encargado lee el horario; nadie sin sesión', async () => {
    await sembrar((db) => setDoc(doc(db, 'clases/c1'), clase()));
    await assertSucceeds(getDoc(doc(contexto(ENC), 'clases/c1')));
    await assertFails(getDoc(doc(entorno.unauthenticatedContext().firestore(), 'clases/c1')));
  });
});

describe('Registros y bitácora (I3–I5)', () => {
  test('PR-07 el encargado registra con su entrada de bitácora', async () => {
    await assertSucceeds(loteCrear(contexto(ENC), diaNegocio()).commit());
  });

  test('PR-07 un registro sin bitácora es rechazado', async () => {
    await assertFails(loteCrear(contexto(ENC), diaNegocio(), ENC, 'ENC', {}, false).commit());
  });

  test('RN-006 el ID debe coincidir con aula, fecha y hora', async () => {
    const dia = { ...diaNegocio(), id: 'A999_20200101_09' };
    await assertFails(loteCrear(contexto(ENC), dia).commit());
  });

  test('PR-10 no se crean registros de más de 2 días atrás', async () => {
    await assertFails(loteCrear(contexto(ENC), diaNegocio(-3)).commit());
  });

  test('PR-11 suplente sin nombre es rechazado', async () => {
    const db = contexto(ENC);
    await assertFails(loteCrear(db, diaNegocio(), ENC, 'ENC', { estadoCaptura: 'SUPLENTE', suplenteNombre: '' }).commit());
    await assertSucceeds(loteCrear(db, diaNegocio(), ENC, 'ENC', { estadoCaptura: 'SUPLENTE', suplenteNombre: 'Pedro Gómez' }).commit());
  });

  test('Coordinación no puede registrar como si fuera la app', async () => {
    await assertFails(loteCrear(contexto(COO), diaNegocio(), COO, 'COO').commit());
  });

  test('PR-08 una corrección debe aumentar la versión exactamente en 1', async () => {
    const dia = diaNegocio();
    await sembrarRegistro(dia);
    const db = contexto(ENC);
    await assertFails(loteCorregir(db, dia, ENC, 'ENC', 3).commit());
    await assertSucceeds(loteCorregir(db, dia, ENC, 'ENC', 2).commit());
  });

  test('PR-08 una corrección no puede cambiar aula, fecha ni docente', async () => {
    const dia = diaNegocio();
    await sembrarRegistro(dia);
    await assertFails(loteCorregir(contexto(ENC), dia, ENC, 'ENC', 2, { docenteId: '9999' }).commit());
  });

  test('PR-12 el encargado no corrige registros de días anteriores', async () => {
    const dia = diaNegocio(-1);
    await sembrarRegistro(dia);
    await assertFails(loteCorregir(contexto(ENC), dia, ENC, 'ENC', 2).commit());
  });

  test('PR-13 Coordinación corrige solo con motivo', async () => {
    const dia = diaNegocio(-1);
    await sembrarRegistro(dia);
    const db = contexto(COO);
    await assertFails(loteCorregir(db, dia, COO, 'COO', 2, {}, { motivo: '' }).commit());
    await assertSucceeds(loteCorregir(db, dia, COO, 'COO', 2, {}, { motivo: 'El docente presentó constancia' }).commit());
  });

  test('PR-06 nadie borra registros', async () => {
    const dia = diaNegocio();
    await sembrarRegistro(dia);
    await assertFails(deleteDoc(doc(contexto(ENC), `registros/${dia.id}`)));
    await assertFails(deleteDoc(doc(contexto(COO), `registros/${dia.id}`)));
  });

  test('PR-09 la bitácora no se modifica ni se borra', async () => {
    const dia = diaNegocio();
    await sembrarRegistro(dia);
    const db = contexto(COO);
    await assertFails(updateDoc(doc(db, `bitacora/${dia.id}_v1`), { motivo: 'cambiado' }));
    await assertFails(deleteDoc(doc(db, `bitacora/${dia.id}_v1`)));
  });

  test('la bitácora registra al usuario real y su rol', async () => {
    const dia = diaNegocio();
    const db = contexto(ENC);
    const lote = writeBatch(db);
    lote.set(doc(db, `registros/${dia.id}`), datosRegistro(dia, ENC));
    lote.set(doc(db, `bitacora/${dia.id}_v1`), datosBitacora(dia.id, 1, ENC, 'COO'));
    await assertFails(lote.commit());
  });

  test('PR-14 el encargado lee los registros de hoy, no los de hace 3 días', async () => {
    const hoy = diaNegocio();
    const viejo = diaNegocio(-3);
    await sembrarRegistro(hoy);
    await sembrarRegistro(viejo);
    const db = contexto(ENC);
    await assertSucceeds(getDocs(query(collection(db, 'registros'), where('fechaTs', '==', hoy.fechaTs))));
    await assertFails(getDoc(doc(db, `registros/${viejo.id}`)));
    await assertFails(getDocs(query(collection(db, 'registros'), where('fechaTs', '==', viejo.fechaTs))));
  });

  test('solo Coordinación lee la bitácora', async () => {
    const dia = diaNegocio();
    await sembrarRegistro(dia);
    await assertSucceeds(getDoc(doc(contexto(COO), `bitacora/${dia.id}_v1`)));
    await assertFails(getDoc(doc(contexto(ENC), `bitacora/${dia.id}_v1`)));
  });
});
