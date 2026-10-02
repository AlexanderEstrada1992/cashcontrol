const express = require('express');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('node:crypto');
const { hashPassword, verifyPassword, tokenHash, validateCredentials } = require('./auth_security');

const tokenOptions = { algorithm: 'HS256', issuer: 'cashcontrol-api', audience: 'cashcontrol-mobile' };
const verification = { algorithms: ['HS256'], issuer: tokenOptions.issuer, audience: tokenOptions.audience };

function createAuth({ store, secret, accessTtl = '15m', refreshTtl = '7d' }) {
  const router = express.Router();
  const attempts = new Map();
  const throttle = (req, res, next) => {
    const now = Date.now();
    for (const [key, entry] of attempts) if (entry.until <= now) attempts.delete(key);
    const key = req.ip;
    const entry = attempts.get(key) ?? { count: 0, until: now + 60000 };
    entry.count++;
    if (attempts.size >= 10000 && !attempts.has(key)) {
      return res.status(429).json({ success: false, message: 'Demasiadas solicitudes. Intente más tarde.' });
    }
    attempts.set(key, entry);
    if (entry.count > 20) {
      res.set('Retry-After', String(Math.ceil((entry.until - now) / 1000)));
      return res.status(429).json({ success: false, message: 'Demasiados intentos. Intente más tarde.' });
    }
    next();
  };

  function requireAuth(req, res, next) {
    const header = req.get('Authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    try {
      const claims = jwt.verify(token, secret, verification);
      if (claims.type !== 'access' || typeof claims.sub !== 'string' || !claims.sub || !claims.exp) throw new Error();
      req.userId = claims.sub;
      req.role = claims.role;
      return next();
    } catch (_) {
      return res.status(401).json({ success: false, message: 'Sesión no autorizada o expirada' });
    }
  }

  const requireRole = (...roles) => (req, res, next) => {
    if (!roles.includes(req.role)) return res.status(403).json({ success: false, message: 'No tiene permisos para esta operación' });
    next();
  };

  const publicUser = user => ({ id: user.id, username: user.username, email: user.email ?? null, role: user.role });
  function tokens(user) {
    const claims = { sub: user.id, role: user.role };
    const accessToken = jwt.sign({ ...claims, type: 'access' }, secret, { ...tokenOptions, expiresIn: accessTtl });
    const refreshToken = jwt.sign({ ...claims, type: 'refresh', jti: randomUUID() }, secret,
      { ...tokenOptions, expiresIn: refreshTtl });
    return { accessToken, refreshToken };
  }
  const session = (user, pair) => ({ hash: tokenHash(pair.refreshToken), userId: user.id,
    expiresAt: new Date(jwt.decode(pair.refreshToken).exp * 1000) });

  router.post('/auth/register', throttle, async (req, res) => {
    const errors = validateCredentials(req.body, true);
    if (Object.keys(errors).length) return res.status(422).json({ success: false, message: 'Error de validación', errors });
    const user = { id: randomUUID(), username: req.body.username.toLowerCase(), email: req.body.email.toLowerCase(),
      role: 'user', active: true };
    try {
      user.passwordHash = await hashPassword(req.body.password);
      await store.createUser(user);
      return res.status(201).json({ success: true, data: publicUser(user), message: 'Usuario registrado' });
    } catch (error) {
      if (error.errorNum === 1) return res.status(409).json({ success: false, message: 'Usuario o correo ya registrado' });
      return res.status(500).json({ success: false, message: 'No fue posible registrar el usuario' });
    }
  });

  router.post('/auth/login', throttle, async (req, res) => {
    const errors = validateCredentials(req.body);
    if (Object.keys(errors).length) return res.status(422).json({ success: false, message: 'Error de validación', errors });
    try {
      const user = await store.findUser(req.body.username.toLowerCase());
      const valid = await verifyPassword(req.body.password, user?.passwordHash ?? await hashPassword(randomUUID()));
      if (!user || !user.active || !valid) return res.status(401).json({ success: false, message: 'Credenciales inválidas' });
      const pair = tokens(user);
      await store.saveSession(session(user, pair));
      return res.json({ success: true, userId: user.id, user: publicUser(user), ...pair });
    } catch (_) {
      return res.status(500).json({ success: false, message: 'No fue posible iniciar sesión' });
    }
  });

  router.post('/auth/refresh', throttle, async (req, res) => {
    const refreshToken = req.body?.refreshToken;
    let claims;
    try {
      if (typeof refreshToken !== 'string' || refreshToken.length > 4096) throw new Error();
      claims = jwt.verify(refreshToken, secret, verification);
      if (claims.type !== 'refresh' || typeof claims.sub !== 'string' || !claims.jti || !claims.exp) throw new Error();
    } catch (_) {
      return res.status(401).json({ success: false, message: 'Refresh token inválido o expirado' });
    }
    try {
      const user = await store.findUserById(claims.sub);
      if (!user || !user.active) return res.status(401).json({ success: false, message: 'Sesión expirada' });
      const pair = tokens(user);
      const rotated = await store.rotateSession(tokenHash(refreshToken), session(user, pair));
      if (!rotated) return res.status(401).json({ success: false, message: 'Refresh token usado o revocado' });
      return res.json({ success: true, userId: user.id, user: publicUser(user), ...pair });
    } catch (_) {
      return res.status(500).json({ success: false, message: 'No fue posible renovar la sesión' });
    }
  });

  router.get('/auth/me', requireAuth, requireRole('user', 'admin'), async (req, res) => {
    try {
      const user = await store.findUserById(req.userId);
      if (!user || !user.active) return res.status(401).json({ success: false, message: 'Sesión expirada' });
      res.json({ success: true, data: publicUser(user) });
    } catch (_) { res.status(500).json({ success: false, message: 'No fue posible consultar la sesión' }); }
  });

  router.get('/admin/users', requireAuth, requireRole('admin'), async (req, res) => {
    try { res.json({ success: true, data: await store.listUsers() }); }
    catch (_) { res.status(500).json({ success: false, message: 'No fue posible listar los usuarios' }); }
  });

  return { router, requireAuth, requireRole };
}

module.exports = { createAuth, verification, tokenOptions };