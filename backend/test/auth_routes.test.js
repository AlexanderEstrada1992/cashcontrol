const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const jwt = require('jsonwebtoken');
const { randomBytes } = require('node:crypto');
const { createAuth, tokenOptions } = require('../auth_routes');
const { AuthStore } = require('../auth_store');

function memoryStore() {
  const users = new Map();
  const sessions = new Map();
  return {
    async createUser(user) {
      if ([...users.values()].some(existing => existing.username === user.username || existing.email === user.email)) {
        throw Object.assign(new Error('duplicate'), { errorNum: 1 });
      }
      users.set(user.id, { ...user });
    },
    async findUser(username) { return [...users.values()].find(user => user.username === username); },
    async findUserById(id) { return users.get(id); },
    async saveSession(session) { sessions.set(session.hash, session); },
    async rotateSession(oldHash, session) {
      const old = sessions.get(oldHash);
      if (!old || old.userId !== session.userId || old.expiresAt <= new Date()) return false;
      sessions.delete(oldHash);
      sessions.set(session.hash, session);
      return true;
    },
    async listUsers() { return [...users.values()].map(user => ({ id: user.id, username: user.username, role: user.role })); },
    async promote(id) { users.get(id).role = 'admin'; },
    async remove(id) { users.delete(id); }
  };
}

async function exerciseAuth(t, realOracle) {
  const store = realOracle ? new AuthStore() : memoryStore();
  const secret = randomBytes(48).toString('hex');
  const application = express();
  application.use(express.json());
  application.use('/api', createAuth({ store, secret, accessTtl: '1m', refreshTtl: '1h' }).router);
  const server = application.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}`;
  const call = async (method, endpoint, body, token) => {
    const response = await fetch(`${url}/api${endpoint}`, { method,
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body === undefined ? undefined : JSON.stringify(body) });
    return { status: response.status, body: await response.json() };
  };
  const credentials = { username: `auth-test-${randomBytes(8).toString('hex')}`,
    email: `auth-${randomBytes(8).toString('hex')}@example.com`, password: randomBytes(24).toString('hex') };
  let id;
  let pair;
  try {
    await t.test('registro válido, duplicado, campos inválidos y escalamiento de rol', async () => {
      assert.equal((await call('POST', '/auth/register', { ...credentials, role: 'admin' })).status, 422);
      assert.equal((await call('POST', '/auth/register', { ...credentials, email: 'invalid' })).status, 422);
      const response = await call('POST', '/auth/register', credentials);
      assert.equal(response.status, 201);
      id = response.body.data.id;
      assert.equal(response.body.data.role, 'user');
      assert.equal(response.body.data.passwordHash, undefined);
      assert.equal((await call('POST', '/auth/register', credentials)).status, 409);
      const user = await store.findUserById(id);
      assert.ok(user.passwordHash.startsWith('scrypt$'));
      assert.notEqual(user.passwordHash, credentials.password);
    });
    await t.test('login y contrato Flutter; credenciales incorrectas', async () => {
      assert.equal((await call('POST', '/auth/login', {})).status, 422);
      assert.equal((await call('POST', '/auth/login', { ...credentials, password: 'incorrecta' })).status, 401);
      const response = await call('POST', '/auth/login', credentials);
      assert.equal(response.status, 200);
      pair = response.body;
      assert.equal(pair.userId, id);
      const claims = jwt.verify(pair.accessToken, secret);
      assert.equal(claims.role, 'user');
      assert.equal(claims.exp - claims.iat, 60);
      assert.equal(claims.password, undefined);
      assert.equal(claims.email, undefined);
      assert.equal((await call('GET', '/auth/me', undefined, pair.accessToken)).body.data.id, id);
    });
    await t.test('ausente, inválido, vencido, tipo incorrecto y rol insuficiente', async () => {
      for (const token of [undefined, 'invalid', pair.refreshToken,
        jwt.sign({ sub: id, role: 'user', type: 'access' }, secret, { ...tokenOptions, expiresIn: -1 })]) {
        assert.equal((await call('GET', '/auth/me', undefined, token)).status, 401);
      }
      assert.equal((await call('GET', '/admin/users', undefined, pair.accessToken)).status, 403);
    });
    await t.test('refresh rotado, repetición rechazada y petición original autorizada', async () => {
      const response = await call('POST', '/auth/refresh', { refreshToken: pair.refreshToken });
      assert.equal(response.status, 200);
      assert.notEqual(response.body.refreshToken, pair.refreshToken);
      assert.equal((await call('GET', '/auth/me', undefined, response.body.accessToken)).status, 200);
      assert.equal((await call('POST', '/auth/refresh', { refreshToken: pair.refreshToken })).status, 401);
      assert.equal((await call('POST', '/auth/refresh', { refreshToken: pair.accessToken })).status, 401);
      assert.equal((await call('POST', '/auth/refresh', {})).status, 401);
    });
    await t.test('dos renovaciones concurrentes no reutilizan una misma sesión', async () => {
      const login = await call('POST', '/auth/login', credentials);
      const responses = await Promise.all([
        call('POST', '/auth/refresh', { refreshToken: login.body.refreshToken }),
        call('POST', '/auth/refresh', { refreshToken: login.body.refreshToken })
      ]);
      assert.deepEqual(responses.map(response => response.status).sort(), [200, 401]);
    });
    await t.test('rol admin provisionado fuera del registro público', async () => {
      if (realOracle) {
        await store.withConnection(connection => connection.execute(
          "UPDATE CC_USERS SET ROLE = 'admin' WHERE USER_ID = :userId", { userId: id }, { autoCommit: true }
        ));
      } else { await store.promote(id); }
      const login = await call('POST', '/auth/login', credentials);
      assert.equal(login.body.user.role, 'admin');
      const users = await call('GET', '/admin/users', undefined, login.body.accessToken);
      assert.equal(users.status, 200);
      assert.equal(users.body.data.some(user => 'passwordHash' in user), false);
    });
  } finally {
    if (id) {
      if (realOracle) await store.withConnection(connection => connection.execute(
        'DELETE FROM CC_USERS WHERE USER_ID = :userId', { userId: id }, { autoCommit: true }
      ));
      else await store.remove(id);
    }
    await new Promise(resolve => server.close(resolve));
  }
}

test('autenticación HTTP con almacenamiento simulado', async t => exerciseAuth(t, false));
test('autenticación HTTP persistida en Oracle', { skip: process.env.RUN_ORACLE_TESTS !== '1' }, async t => {
  require('dotenv').config({ path: require('node:path').join(__dirname, '..', '.env'), quiet: true });
  await exerciseAuth(t, true);
});