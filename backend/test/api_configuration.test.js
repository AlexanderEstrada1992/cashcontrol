const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const { randomBytes } = require('node:crypto');
const spec = require('../openapi.json');

test('documento OpenAPI contiene rutas y referencias resolubles', () => {
  const inspect = value => {
    if (!value || typeof value !== 'object') return;
    if (value.$ref) {
      assert.ok(value.$ref.startsWith('#/'));
      let target = spec;
      for (const part of value.$ref.slice(2).split('/')) target = target?.[part];
      assert.ok(target, value.$ref);
    }
    for (const child of Object.values(value)) inspect(child);
  };
  inspect(spec);
  assert.deepEqual(spec.paths['/api/auth/register'].post.security, []);
  assert.ok(spec.paths['/api/admin/users'].get.responses['403']);
  assert.ok(spec.paths['/api/gastos/{expenseId}'].delete);
});

test('producción impide iniciar servidor HTTP sin certificado TLS', () => {
  const result = spawnSync(process.execPath, [path.join(__dirname, '..', 'server.js')], {
    env: { ...process.env, NODE_ENV: 'production', JWT_SECRET: randomBytes(48).toString('hex'),
      HTTPS_CERT_FILE: '', HTTPS_KEY_FILE: '' }, encoding: 'utf8', timeout: 10000
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Producción requiere HTTPS_CERT_FILE y HTTPS_KEY_FILE/);
});