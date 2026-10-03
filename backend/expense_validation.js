function validateExpense(body, { create = true, userId } = {}) {
  const errors = {};
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { body: 'Se requiere un objeto JSON' };
  }
  const text = (field, max) => {
    if (typeof body[field] !== 'string' || !body[field].trim() || body[field].length > max) {
      errors[field] = `Debe ser texto obligatorio de hasta ${max} caracteres`;
    }
  };
  if (create) {
    text('client_operation_id', 100);
    text('user_id', 100);
  }
  if ((create || body.user_id !== undefined) && body.user_id !== userId) {
    errors.user_id = 'El usuario debe coincidir con la sesión autenticada';
  }
  text('category_id', 100);
  text('description', 255);
  if (typeof body.amount !== 'number' || !Number.isFinite(body.amount) ||
      body.amount <= 0 || body.amount > 9999999999.99 ||
      Math.abs(body.amount * 100 - Math.round(body.amount * 100)) > 0.0001) {
    errors.amount = 'El monto debe ser positivo, con hasta dos decimales y dentro del rango permitido';
  }
  for (const field of ['date']) {
    const value = body[field];
    const parsed = typeof value === 'string' ? new Date(value) : new Date(NaN);
    if (Number.isNaN(parsed.getTime()) || parsed.toISOString() !== value) {
      errors[field] = 'Se requiere una fecha ISO UTC válida (YYYY-MM-DDTHH:mm:ss.sssZ)';
    }
  }
  if (body.updated_at !== undefined) {
    const parsed = typeof body.updated_at === 'string' ? new Date(body.updated_at) : new Date(NaN);
    if (Number.isNaN(parsed.getTime()) || parsed.toISOString() !== body.updated_at) {
      errors.updated_at = 'Se requiere una fecha ISO UTC válida (YYYY-MM-DDTHH:mm:ss.sssZ)';
    }
  }
  const hasLatitude = body.latitude !== undefined && body.latitude !== null;
  const hasLongitude = body.longitude !== undefined && body.longitude !== null;
  if (hasLatitude !== hasLongitude) errors.location = 'Latitud y longitud deben enviarse juntas';
  for (const [field, limit] of [['latitude', 90], ['longitude', 180]]) {
    if (body[field] !== undefined && body[field] !== null &&
        (typeof body[field] !== 'number' || !Number.isFinite(body[field]) || Math.abs(body[field]) > limit)) {
      errors[field] = `Debe estar entre -${limit} y ${limit}`;
    }
  }
  return errors;
}

function parsePagination(query) {
  if (query.page === undefined && query.limit === undefined) return null;
  const page = Number(query.page ?? 1);
  const limit = Number(query.limit ?? 20);
  if (!Number.isSafeInteger(page) || page < 1 || !Number.isInteger(limit) || limit < 1 || limit > 100 ||
      !Number.isSafeInteger((page - 1) * limit)) return false;
  return { page, limit, offset: (page - 1) * limit };
}

function validExpenseId(value) {
  return /^\d+$/.test(value) && Number.isSafeInteger(Number(value)) && Number(value) > 0;
}

module.exports = { validateExpense, parsePagination, validExpenseId };