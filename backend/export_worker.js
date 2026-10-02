const { parentPort, workerData } = require('node:worker_threads');

const fields = ['ID_GASTO', 'CATEGORY_ID', 'AMOUNT', 'DESCRIPTION', 'EXPENSE_DATE', 'LATITUDE', 'LONGITUDE'];
function cell(value) {
  let text = value instanceof Date ? value.toISOString() : value == null ? '' : String(value);
  if (typeof value === 'string' && /^[\s\u0000-\u001f]*[=+@-]/.test(text)) text = `'${text}`;
  return `"${text.replace(/"/g, '""')}"`;
}

const content = [fields.join(','), ...workerData.map(row => fields.map(field => cell(row[field])).join(','))].join('\r\n');
parentPort.postMessage(content);