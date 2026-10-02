const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomBytes } = require('node:crypto');
const oracledb = require('oracledb');
const jwt = require('jsonwebtoken');
const { tokenOptions } = require('../auth_routes');
const { validateExpense, parsePagination } = require('../expense_validation');

process.env.JWT_SECRET ||= randomBytes(32).toString('hex');
const app = require('../server');

const payload = (operationId) => ({
  client_operation_id: operationId,
  user_id: 'crud-test-user',
  category_id: 'general',
  amount: 12.5,
  description: 'Prueba temporal CRUD',
  date: '2026-10-02T12:00:00.000Z',
  updated_at: '2026-10-02T12:00:00.000Z',
  latitude: -0.18,
  longitude: -78.47
});

test('validación de monto, fechas, longitud, usuario y coordenadas', () => {
  const valid = payload('validation-test');
  assert.deepEqual(validateExpense(valid, { userId: valid.user_id }), {});
  for (const amount of [0, -1, Infinity, NaN, '12', 1.234, 10000000000]) {
    assert.ok(validateExpense({ ...valid, amount }, { userId: valid.user_id }).amount);
  }
  assert.ok(validateExpense({ ...valid, date: '2026-02-30T12:00:00.000Z' }, { userId: valid.user_id }).date);
  assert.ok(validateExpense({ ...valid, description: 'a'.repeat(256) }, { userId: valid.user_id }).description);
  assert.ok(validateExpense(valid, { userId: 'other-user' }).user_id);
  assert.ok(validateExpense({ ...valid, latitude: 91 }, { userId: valid.user_id }).latitude);
  assert.ok(validateExpense({ ...valid, longitude: null }, { userId: valid.user_id }).location);
  assert.ok(validateExpense(null).body);
});

test('paginación opcional mantiene compatibilidad y limita tamaños', () => {
  assert.equal(parsePagination({}), null);
  assert.equal(parsePagination({ limit: '101' }), false);
  assert.equal(parsePagination({ page: '-1' }), false);
  assert.equal(parsePagination({ page: '1.5' }), false);
  assert.deepEqual(parsePagination({ page: '2', limit: '10' }), { page: 2, limit: 10, offset: 10 });
});

function fakeConnection() {
  const rows = new Map();
  let nextId = 1;
  return {
    async execute(sql, binds = {}) {
      if (/CREATE TABLE|ALTER TABLE/.test(sql)) return {};
      if (/FROM DUAL/.test(sql)) return { rows: [['CONNECTED']] };
      if (/MERGE INTO/.test(sql)) {
        const existing = [...rows.values()].find(row => row.CLIENT_OPERATION_ID === binds.operationId);
        const row = {
          ID_GASTO: existing?.ID_GASTO ?? nextId++, CLIENT_OPERATION_ID: binds.operationId,
          USER_ID: binds.userId, CATEGORY_ID: binds.categoryId, AMOUNT: binds.amount,
          DESCRIPTION: binds.description, EXPENSE_DATE: binds.expenseDate,
          CREATED_AT: existing?.CREATED_AT ?? new Date(), UPDATED_AT: binds.updatedAt,
          LATITUDE: binds.latitude, LONGITUDE: binds.longitude
        };
        if (!existing || existing.UPDATED_AT < binds.updatedAt) rows.set(row.ID_GASTO, row);
        return { rowsAffected: 1 };
      }
      if (/^UPDATE/.test(sql.trim())) {
        const row = rows.get(binds.expenseId);
        if (!row || row.USER_ID !== binds.userId) return { rowsAffected: 0 };
        Object.assign(row, { CATEGORY_ID: binds.categoryId, AMOUNT: binds.amount, DESCRIPTION: binds.description,
          EXPENSE_DATE: binds.expenseDate, LATITUDE: binds.latitude, LONGITUDE: binds.longitude, UPDATED_AT: new Date() });
        return { rowsAffected: 1 };
      }
      if (/^DELETE/.test(sql.trim())) {
        const row = rows.get(binds.expenseId);
        if (!row || row.USER_ID !== binds.userId) return { rowsAffected: 0 };
        rows.delete(binds.expenseId);
        return { rowsAffected: 1 };
      }
      assert.match(sql, /WHERE/);
      let found = [...rows.values()].filter(row =>
        (binds.operationId === undefined || row.CLIENT_OPERATION_ID === binds.operationId) &&
        (binds.userId === undefined || row.USER_ID === binds.userId) &&
        (binds.expenseId === undefined || row.ID_GASTO === binds.expenseId));
      if (/COUNT/.test(sql)) return { rows: [{ TOTAL: found.length }] };
      if (binds.offset !== undefined) found = found.slice(binds.offset, binds.offset + binds.limit);
      return { rows: found };
    },
    async commit() {},
    async close() {}
  };
}

async function exerciseCrud(t, realOracle) {
  const originalConnection = oracledb.getConnection;
  if (!realOracle) {
    const connection = fakeConnection();
    oracledb.getConnection = async () => connection;
  }
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const token = jwt.sign({ sub: 'crud-test-user', role: 'user', type: 'access' }, process.env.JWT_SECRET,
    { ...tokenOptions, expiresIn: '5m' });
  const otherToken = jwt.sign({ sub: 'crud-test-other', role: 'user', type: 'access' }, process.env.JWT_SECRET,
    { ...tokenOptions, expiresIn: '5m' });
  const ids = [];
  const call = async (method, path, body, auth = token, raw = false) => {
    const response = await fetch(`${baseUrl}${path}`, {
      method, headers: { 'Content-Type': 'application/json', ...(auth ? { Authorization: `Bearer ${auth}` } : {}) },
      body: body === undefined ? undefined : raw ? body : JSON.stringify(body)
    });
    return { status: response.status, body: await response.json() };
  };
  try {
    await t.test('salud, autorización y JSON malformado', async () => {
      assert.equal((await call('GET', '/api/health', undefined, null)).status, 200);
      for (const method of ['GET', 'POST', 'PUT', 'DELETE']) {
        const path = method === 'POST' ? '/api/gastos' : '/api/gastos/1';
        assert.equal((await call(method, path, undefined, null)).status, 401);
      }
      const malformed = await call('POST', '/api/gastos', '{', token, true);
      assert.equal(malformed.status, 400);
      assert.equal(malformed.body.success, false);
    });
    const body = payload(`crud-test-${Date.now()}-${randomBytes(4).toString('hex')}`);
    await t.test('crear, repetir idempotentemente y conflicto entre usuarios', async () => {
      const created = await call('POST', '/api/gastos', body);
      assert.equal(created.status, 201);
      ids.push(created.body.data.server_id);
      const repeated = await call('POST', '/api/gastos', body);
      assert.equal(repeated.status, 200);
      assert.equal(repeated.body.data.server_id, ids[0]);
      const conflict = await call('POST', '/api/gastos', { ...body, user_id: 'crud-test-other' }, otherToken);
      assert.equal(conflict.status, 409);
      const invalid = await call('POST', '/api/gastos', { ...body, amount: -2 });
      assert.equal(invalid.status, 422);
      assert.ok(invalid.body.errors.amount);
      assert.equal((await call('POST', '/api/gastos')).status, 422);
    });
    await t.test('listado compatible, paginación y detalle', async () => {
      const list = await call('GET', '/api/gastos');
      assert.equal(list.status, 200);
      assert.ok(Array.isArray(list.body.data));
      const page = await call('GET', '/api/gastos?page=1&limit=1');
      assert.equal(page.status, 200);
      assert.equal(page.body.data.length, 1);
      assert.equal(page.body.pagination.total, 1);
      assert.equal((await call('GET', '/api/gastos?limit=101')).status, 422);
      const detail = await call('GET', `/api/gastos/${ids[0]}`);
      assert.equal(detail.body.data.description, body.description);
      assert.equal((await call('GET', `/api/gastos/${ids[0]}`, undefined, otherToken)).status, 404);
      assert.equal((await call('GET', '/api/gastos/abc')).status, 422);
    });
    await t.test('lectura cacheada verifica JWT una sola vez y no abre conexiones', async () => {
      const originalVerify = jwt.verify;
      const originalGetConnection = oracledb.getConnection;
      let verifications = 0;
      let connections = 0;
      jwt.verify = (...args) => { verifications++; return originalVerify(...args); };
      oracledb.getConnection = (...args) => { connections++; return originalGetConnection(...args); };
      try {
        assert.equal((await call('GET', '/api/gastos')).status, 200);
        assert.equal(verifications, 1);
        assert.equal(connections, 0);
      } finally {
        jwt.verify = originalVerify;
        oracledb.getConnection = originalGetConnection;
      }
    });
    await t.test('exportación HTTP se ejecuta en worker y protege estado y archivo por usuario', async () => {
      assert.equal((await call('POST', '/api/gastos/exportaciones', undefined, null)).status, 401);
      const created = await call('POST', '/api/gastos/exportaciones');
      assert.equal(created.status, 202);
      const path = `/api/gastos/exportaciones/${created.body.data.job_id}`;
      assert.equal((await call('GET', path, undefined, otherToken)).status, 404);
      const deadline = Date.now() + 10000;
      let job;
      do {
        job = await call('GET', path);
        if (job.body.data.status === 'completed' || job.body.data.status === 'failed') break;
      } while (Date.now() < deadline);
      assert.equal(job.body.data.status, 'completed');
      const csv = await fetch(`${baseUrl}${path}/archivo`, { headers: { Authorization: `Bearer ${token}` } });
      assert.equal(csv.status, 200);
      assert.match(csv.headers.get('content-type'), /text\/csv/);
      assert.match(await csv.text(), /Prueba temporal CRUD/);
      assert.equal((await call('GET', `${path}/archivo`, undefined, otherToken)).status, 404);
    });
    await t.test('actualizar, rechazar inválidos y aislar usuario', async () => {
      const path = `/api/gastos/${ids[0]}`;
      assert.equal((await call('PUT', path, { ...body, amount: 0 })).status, 422);
      assert.equal((await call('PUT', path, { ...body, user_id: 'crud-test-other' }, otherToken)).status, 404);
      const updated = await call('PUT', path, { ...body, amount: 21, description: 'Gasto actualizado' });
      assert.equal(updated.status, 200);
      assert.equal(updated.body.data.amount, 21);
      assert.equal(updated.body.data.client_operation_id, body.client_operation_id);
      assert.equal((await call('GET', path)).body.data.description, 'Gasto actualizado');
      const list = await call('GET', '/api/gastos');
      assert.equal(list.body.data.find(expense => expense.server_id === ids[0]).description, 'Gasto actualizado');
      const page = await call('GET', '/api/gastos?page=1&limit=1');
      assert.equal(page.body.data[0].amount, 21);
    });
    await t.test('eliminar y devolver 404 sin revelar otros usuarios', async () => {
      const path = `/api/gastos/${ids[0]}`;
      assert.equal((await call('DELETE', path, undefined, otherToken)).status, 404);
      assert.equal((await call('DELETE', path)).status, 200);
      assert.equal((await call('DELETE', path)).status, 404);
      assert.equal((await call('GET', path)).status, 404);
      assert.equal((await call('GET', '/api/gastos')).body.data.length, 0);
      assert.equal((await call('GET', '/api/gastos?page=1&limit=1')).body.pagination.total, 0);
    });
    if (!realOracle) {
      await t.test('fallo de persistencia devuelve JSON 500 sin detalles técnicos', async () => {
        const workingConnection = oracledb.getConnection;
        oracledb.getConnection = async () => { throw new Error('Detalle interno que no debe salir'); };
        try {
          const failure = await call('GET', '/api/gastos/1');
          assert.equal(failure.status, 500);
          assert.equal(failure.body.success, false);
          assert.equal(JSON.stringify(failure.body).includes('Detalle interno'), false);
        } finally {
          oracledb.getConnection = workingConnection;
        }
      });
    }
  } finally {
    for (const id of ids) await call('DELETE', `/api/gastos/${id}`);
    await new Promise(resolve => server.close(resolve));
    oracledb.getConnection = originalConnection;
  }
}

test('contrato HTTP CRUD con persistencia simulada', async t => exerciseCrud(t, false));
test('contrato HTTP CRUD contra Oracle real', { skip: process.env.RUN_ORACLE_TESTS !== '1' }, async t => exerciseCrud(t, true));