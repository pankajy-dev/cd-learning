const http = require('http');
const assert = require('assert');

process.env.PORT = 3001;
const server = require('./server');

function get(path) {
  return new Promise((resolve, reject) => {
    http.get(`http://localhost:3001${path}`, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
    }).on('error', reject);
  });
}

async function run() {
  const health = await get('/health');
  assert.strictEqual(health.status, 200);
  assert.strictEqual(health.body.status, 'ok');

  const root = await get('/');
  assert.strictEqual(root.status, 200);
  assert.ok(root.body.message.startsWith('Hello from version'));

  console.log('all tests passed');
  server.close();
  process.exit(0);
}

run().catch((err) => {
  console.error('test failed:', err);
  process.exit(1);
});
