const path = require('node:path');
const { Worker } = require('node:worker_threads');
const { randomUUID } = require('node:crypto');

function renderCsv(rows) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(path.join(__dirname, 'export_worker.js'), { workerData: rows });
    let finished = false;
    const complete = (error, result) => {
      if (finished) return;
      finished = true;
      clearTimeout(timeout);
      if (error) reject(error); else resolve(result);
      worker.terminate().catch(() => {});
    };
    const timeout = setTimeout(() => complete(new Error('Exportación excedió el tiempo permitido')), 30000);
    worker.once('message', result => complete(null, result));
    worker.once('error', error => complete(error));
    worker.once('exit', code => { if (!finished) complete(new Error(`Worker terminado (${code})`)); });
  });
}

class ExportQueue {
  constructor({ concurrency = 2, capacity = 10, ttlMs = 300000, now = Date.now, render = renderCsv } = {}) {
    this.concurrency = concurrency;
    this.capacity = capacity;
    this.ttlMs = ttlMs;
    this.now = now;
    this.render = render;
    this.jobs = new Map();
    this.pending = [];
    this.running = 0;
  }

  cleanup() {
    for (const [id, job] of this.jobs) {
      if (job.expiresAt !== undefined && job.expiresAt <= this.now()) this.jobs.delete(id);
    }
  }

  submit(owner, load) {
    this.cleanup();
    if (this.jobs.size >= this.capacity) return null;
    const job = { id: randomUUID(), owner, status: 'queued', load };
    this.jobs.set(job.id, job);
    this.pending.push(job);
    queueMicrotask(() => this.drain());
    return job.id;
  }

  get(id, owner) {
    this.cleanup();
    const job = this.jobs.get(id);
    return job?.owner === owner ? job : null;
  }

  drain() {
    while (this.running < this.concurrency && this.pending.length) {
      const job = this.pending.shift();
      this.running++;
      job.status = 'running';
      Promise.resolve().then(job.load).then(rows => this.render(rows)).then(csv => {
        if (Buffer.byteLength(csv) > 5 * 1024 * 1024) throw new Error('CSV demasiado grande');
        job.csv = csv;
        job.status = 'completed';
      }).catch(() => {
        job.status = 'failed';
        job.message = 'No fue posible exportar. El máximo es 5000 gastos; revise la conexión e intente nuevamente.';
      }).finally(() => {
        delete job.load;
        job.expiresAt = this.now() + this.ttlMs;
        this.running--;
        this.drain();
      });
    }
  }
}

module.exports = { ExportQueue, renderCsv };