const http = require('http');

const VERSION = process.env.APP_VERSION || 'dev';
const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', version: VERSION }));
    return;
  }
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ message: `Hello from version v1 ${VERSION}` }));
});

server.listen(PORT, () => console.log(`listening on ${PORT}, version ${VERSION}`));

module.exports = server;
