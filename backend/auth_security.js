const { randomBytes, scrypt, timingSafeEqual, createHash } = require('node:crypto');
const { promisify } = require('node:util');
const deriveKey = promisify(scrypt);

async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const key = await deriveKey(password, salt, 64);
  return `scrypt$${salt}$${key.toString('hex')}`;
}

async function verifyPassword(password, encoded) {
  const [algorithm, salt, hash] = String(encoded).split('$');
  if (algorithm !== 'scrypt' || !/^[a-f0-9]{32}$/.test(salt) || !/^[a-f0-9]{128}$/.test(hash)) return false;
  const expected = Buffer.from(hash, 'hex');
  const actual = await deriveKey(password, salt, expected.length);
  return timingSafeEqual(actual, expected);
}

function tokenHash(token) {
  return createHash('sha256').update(token).digest('hex');
}

function validateCredentials(body, registration = false) {
  const errors = {};
  if (!body || typeof body !== 'object' || Array.isArray(body)) return { body: 'Se requiere un objeto JSON' };
  if (typeof body.username !== 'string' || !/^[a-zA-Z0-9._-]{3,100}$/.test(body.username)) {
    errors.username = 'El usuario debe tener entre 3 y 100 caracteres: letras, números, punto, guion o guion bajo';
  }
  if (typeof body.password !== 'string' || body.password.length < (registration ? 12 : 1) || body.password.length > 128) {
    errors.password = registration ? 'La contraseña debe tener entre 12 y 128 caracteres' : 'La contraseña es obligatoria (máximo 128 caracteres)';
  }
  if (registration) {
    if (typeof body.email !== 'string' || body.email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) {
      errors.email = 'Se requiere un correo válido de hasta 254 caracteres';
    }
    if (body.role !== undefined && body.role !== 'user') errors.role = 'El registro público solo permite el rol user';
  }
  return errors;
}

module.exports = { hashPassword, verifyPassword, tokenHash, validateCredentials };