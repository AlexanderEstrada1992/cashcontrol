const { test } = require('node:test');
const assert = require('node:assert/strict');
const { ExportQueue, renderCsv } = require('../export_queue');

test('worker genera CSV, escapa comillas y neutraliza fórmulas', async () => {
  const csv = await renderCsv([{ ID_GASTO: 1, DESCRIPTION: '=SUM(A1)', AMOUNT: 2.5,
    CATEGORY_ID: 'a"b', EXPENSE_DATE: new Date('2026-10-02T12:00:00Z'), LATITUDE: -0.18 }]);
  assert.match(csv, /"'=SUM\(A1\)"/);
  assert.match(csv, /"a""b"/);
  assert.match(csv, /"-0.18"/);
});

test('cola limita capacidad y concurrencia, aísla propietarios y expira resultados', async () => {
  let now = 0;
  const queue = new ExportQueue({ capacity: 2, concurrency: 1, ttlMs: 50, now: () => now, render: async () => 'csv' });
  let release;
  const first = queue.submit('user1', () => new Promise(resolve => { release = resolve; }));
  const second = queue.submit('user2', async () => []);
  assert.equal(queue.submit('user3', async () => []), null);
  await Promise.resolve();
  await Promise.resolve();
  assert.equal(queue.get(first, 'user2'), null);
  assert.equal(queue.get(first, 'user1').status, 'running');
  assert.equal(queue.get(second, 'user2').status, 'queued');
  release([]);
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(queue.get(first, 'user1').status, 'completed');
  assert.equal(queue.get(second, 'user2').csv, 'csv');
  now = 51;
  assert.equal(queue.get(first, 'user1'), null);
});

test('errores de exportación se traducen sin filtrar detalles internos', async () => {
  const queue = new ExportQueue({ render: async () => { throw new Error('dato interno'); } });
  const id = queue.submit('user', async () => []);
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(queue.get(id, 'user').status, 'failed');
  assert.equal(queue.get(id, 'user').message.includes('dato interno'), false);
});