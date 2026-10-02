const fs = require('node:fs');
const path = require('node:path');
const dotenv = require('dotenv');
const { randomBytes } = require('node:crypto');
const { hashPassword } = require('../auth_security');

async function migrate() {
  const file = path.join(__dirname, '..', '.env');
  let text = fs.readFileSync(file, 'utf8');
  const config = dotenv.parse(text);
  for (const prefix of ['AUTH', 'AUTH_ADMIN']) {
    const name = `${prefix}_PASSWORD`;
    if (!config[name]) continue;
    if (!config[`${name}_HASH`]) {
      const hash = await hashPassword(config[name]);
      text = text.trimEnd() + `\n${name}_HASH=${hash}\n`;
    }
    text = text.replace(new RegExp(`^(?:export\\s+)?${name}\\s*=.*(?:\\r?\\n|$)`, 'gm'), '');
  }
  if (!config.JWT_SECRET || Buffer.byteLength(config.JWT_SECRET) < 32 || config.JWT_SECRET.startsWith('change-this-')) {
    const value = randomBytes(48).toString('hex');
    text = text.replace(/^(?:export\s+)?JWT_SECRET\s*=.*(?:\r?\n|$)/gm, '');
    text = text.trimEnd() + `\nJWT_SECRET=${value}\n`;
  }
  fs.writeFileSync(file, text, { mode: 0o600 });
  console.log('Configuración migrada: hashes scrypt y secreto JWT local. No se muestran valores sensibles.');
}

migrate().catch(() => {
  console.error('No fue posible migrar la configuración local. Revise el archivo .env y sus permisos.');
  process.exitCode = 1;
});