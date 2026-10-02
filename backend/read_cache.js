class ReadCache {
  constructor({ ttlMs = 5000, maxEntries = 128, maxBytes = 16 * 1024 * 1024, now = Date.now } = {}) {
    this.ttlMs = ttlMs;
    this.maxEntries = maxEntries;
    this.maxBytes = maxBytes;
    this.now = now;
    this.entries = new Map();
    this.bytes = 0;
  }

  remove(key) {
    const entry = this.entries.get(key);
    if (entry) this.bytes -= entry.bytes;
    this.entries.delete(key);
  }

  invalidate(scope) {
    for (const [key, entry] of this.entries) if (entry.scope === scope) this.remove(key);
  }

  async get(key, scope, load) {
    for (const [expiredKey, entry] of this.entries) {
      if (!entry.pending && entry.expiresAt <= this.now()) this.remove(expiredKey);
    }
    const existing = this.entries.get(key);
    if (existing) {
      this.entries.delete(key);
      this.entries.set(key, existing);
      return existing.pending ?? existing.value;
    }
    while (this.entries.size >= this.maxEntries) this.remove(this.entries.keys().next().value);
    const entry = { scope, bytes: 0, expiresAt: 0 };
    this.entries.set(key, entry);
    entry.pending = Promise.resolve().then(load).then(value => {
      if (this.entries.get(key) === entry) {
        const bytes = Buffer.byteLength(JSON.stringify(value));
        if (bytes > Math.min(this.maxBytes, 2 * 1024 * 1024)) {
          this.remove(key);
        } else {
          entry.value = value;
          entry.pending = null;
          entry.bytes = bytes;
          this.bytes += bytes;
          entry.expiresAt = this.now() + this.ttlMs;
          while (this.bytes > this.maxBytes) this.remove(this.entries.keys().next().value);
        }
      }
      return value;
    }).catch(error => {
      if (this.entries.get(key) === entry) this.remove(key);
      throw error;
    });
    return entry.pending;
  }
}

module.exports = { ReadCache };