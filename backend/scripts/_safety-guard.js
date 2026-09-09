// Safety guard for destructive maintenance scripts.
//
// require('./scripts/_safety-guard') at the very top of any script that deletes
// or mutates data. It refuses to run against a production or non-local database
// unless you explicitly opt in with CONFIRM_DESTRUCTIVE=yes.
//
//   node delete_orders.js                      -> blocked unless DB is local
//   CONFIRM_DESTRUCTIVE=yes node delete_orders.js  -> runs anywhere (your call)

const url = process.env.DATABASE_URL || '';
const isProd = process.env.NODE_ENV === 'production';
const isLocal =
  url.includes('@localhost') ||
  url.includes('localhost:') ||
  url.includes('@127.0.0.1') ||
  url.includes('127.0.0.1:') ||
  url.includes('@::1');
const confirmed = process.env.CONFIRM_DESTRUCTIVE === 'yes';

if ((isProd || !isLocal) && !confirmed) {
  console.error(
    '\n[safety-guard] Refusing to run a destructive script against a ' +
      'non-local / production database.\n' +
      `  NODE_ENV=${process.env.NODE_ENV || '(unset)'}\n` +
      `  DATABASE_URL host appears ${isLocal ? 'LOCAL' : 'NON-LOCAL'}\n` +
      '  To override intentionally: re-run with CONFIRM_DESTRUCTIVE=yes\n',
  );
  process.exit(1);
}

module.exports = {};
