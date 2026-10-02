const fs = require('node:fs');
const path = require('node:path');
const { performance } = require('node:perf_hooks');
const { randomBytes } = require('node:crypto');
const oracledb = require('oracledb');
const jwt = require('jsonwebtoken');
const app = require('../server');
const { tokenOptions } = require('../auth_routes');

async function benchmark() {
  const label = process.argv[2] || 'measurement';
  const rows = [];
  const userId = `benchmark-${randomBytes(8).toString('hex')}`;
  const originalConnection = oracledb.getConnection;
  let queries = 0;
  let connections = 0;
  oracledb.getConnection = async (...args) => {
    connections++;
    const connection = await originalConnection(...args);
    return new Proxy(connection, { get(target, name) {
      if (name === 'execute') return (...parameters) => { queries++; return target.execute(...parameters); };
      const value = Reflect.get(target, name, target);
      return typeof value === 'function' ? value.bind(target) : value;
    } });
  };
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const token = jwt.sign({ sub: userId, role: 'user', type: 'access' }, process.env.JWT_SECRET,
    { ...tokenOptions, expiresIn: '15m' });
  const request = async (method, route, body) => {
    const response = await fetch(baseUrl + route, { method,
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body) });
    const text = await response.text();
    if (!response.ok) throw new Error(`HTTP ${response.status} al medir ${route}`);
    return { text, bytes: Buffer.byteLength(text), data: JSON.parse(text) };
  };
  try {
    const stamp = new Date().toISOString();
    for (let index = 0; index < 30; index++) {
      const result = await request('POST', '/api/gastos', {
        client_operation_id: `${userId}-${index}`, user_id: userId, category_id: 'general',
        amount: index + 1, description: `Gasto temporal ${index}`, date: stamp, updated_at: stamp
      });
      rows.push(result.data.data.server_id);
    }
    const measure = async route => {
      const durations = [];
      const initialQueries = queries;
      const initialConnections = connections;
      let bytes;
      for (let index = 0; index < 20; index++) {
        const start = performance.now();
        const result = await request('GET', route);
        durations.push(performance.now() - start);
        bytes = result.bytes;
      }
      const sorted = [...durations].sort((left, right) => left - right);
      return { requests: durations.length, rows: 30, meanMs: Number((durations.reduce((sum, value) => sum + value, 0) / durations.length).toFixed(2)),
        p95Ms: Number(sorted[Math.ceil(sorted.length * 0.95) - 1].toFixed(2)), firstMs: Number(durations[0].toFixed(2)),
        executeCalls: queries - initialQueries, connections: connections - initialConnections, responseBytes: bytes };
    };
    const result = { label, measuredAt: new Date().toISOString(), database: 'Oracle real',
      completeList: await measure('/api/gastos'), paginatedList: await measure('/api/gastos?page=1&limit=10') };
    if (process.argv[3]) fs.writeFileSync(path.resolve(process.argv[3]), JSON.stringify(result, null, 2) + '\n');
    console.log(JSON.stringify(result, null, 2));
  } finally {
    for (const id of rows) await request('DELETE', `/api/gastos/${id}`);
    await new Promise(resolve => server.close(resolve));
    oracledb.getConnection = originalConnection;
  }
}

benchmark().catch(error => { console.error(error.message); process.exitCode = 1; });