const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomBytes } = require('node:crypto');
const { hashPassword, verifyPassword, tokenHash, validateCredentials } = require('../auth_security');

test('scrypt usa sal aleatoria y compara sin almacenar la contraseña', async () => {
  const password = randomBytes(24).toString('hex');
  const first = await hashPassword(password);
  const second = await hashPassword(password);
  assert.notEqual(first, second);
  assert.equal(first.includes(password), false);
  assert.equal(await verifyPassword(password, first), true);
  assert.equal(await verifyPassword('incorrecta', first), false);
  assert.equal(await verifyPassword(password, 'malformado'), false);
});

test('validación de credenciales y rechazo de escalamiento de rol', () => {
  assert.ok(validateCredentials({}).username);
  assert.ok(validateCredentials({}).password);
  assert.deepEqual(validateCredentials({ username: 'demo-user', password: 'valor' }), {});
  const user = { username: 'valid-user', password: randomBytes(24).toString('hex'), email: 'test@example.com' };
  assert.deepEqual(validateCredentials(user, true), {});
  assert.ok(validateCredentials({ ...user, email: 'inválido' }, true).email);
  assert.ok(validateCredentials({ ...user, role: 'admin' }, true).role);
});

test('los refresh tokens se identifican mediante hash, no texto plano', () => {
  const token = randomBytes(32).toString('hex');
  assert.match(tokenHash(token), /^[a-f0-9]{64}$/);
  assert.notEqual(tokenHash(token), token);
});