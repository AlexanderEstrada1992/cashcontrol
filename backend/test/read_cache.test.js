const { test } = require('node:test');
const assert = require('node:assert/strict');
const { ReadCache } = require('../read_cache');

test('cache-aside reutiliza lecturas, aísla usuarios y expira por TTL', async () => {
  let now = 0;
  let reads = 0;
  const cache = new ReadCache({ ttlMs: 100, now: () => now });
  const load = () => ++reads;
  assert.equal(await cache.get('user1-page1', 'user1', load), 1);
  assert.equal(await cache.get('user1-page1', 'user1', load), 1);
  assert.equal(await cache.get('user2-page1', 'user2', load), 2);
  now = 101;
  assert.equal(await cache.get('user1-page1', 'user1', load), 3);
});

test('lecturas concurrentes comparten carga e invalidación evita repoblar datos antiguos', async () => {
  const cache = new ReadCache();
  let finish;
  let reads = 0;
  const first = cache.get('key', 'user', () => { reads++; return new Promise(resolve => { finish = resolve; }); });
  const second = cache.get('key', 'user', () => { throw new Error('No debe cargar dos veces'); });
  await Promise.resolve();
  cache.invalidate('user');
  finish('old');
  assert.deepEqual(await Promise.all([first, second]), ['old', 'old']);
  assert.equal(reads, 1);
  assert.equal(await cache.get('key', 'user', () => 'new'), 'new');
});

test('errores no quedan en caché y memoria permanece acotada', async () => {
  const cache = new ReadCache({ maxEntries: 2, maxBytes: 20 });
  await assert.rejects(cache.get('failure', 'user', () => { throw new Error('offline'); }));
  assert.equal(cache.entries.size, 0);
  for (let index = 0; index < 10; index++) await cache.get(String(index), 'user', () => '12345678');
  assert.ok(cache.entries.size <= 2);
  assert.ok(cache.bytes <= 20);
  await cache.get('oversized', 'user', () => 'x'.repeat(100));
  assert.equal(cache.entries.has('oversized'), false);
});