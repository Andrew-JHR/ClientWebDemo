const https = require('https');
const fs = require('fs');

const data = {
  name: 'Node Client',
  age: 14,
  email: 'Ryan.Dahl@deno.com',
  address: {
    street: '123 Main St',
    city: 'San Diego',
    state: 'California',
    zip: '2009'
  }
};
const body = JSON.stringify(data);
const contentLength = Buffer.byteLength(body, 'utf-8');

const options = {
  hostname: '10.1.1.1',
  port: 3000,
  path: '/api/data',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': contentLength
  },
  ca: fs.readFileSync('d:/ssl2/ca-cert.pem')
  //rejectUnauthorized: false // Disable SSL verification
 
};

const req = https.request(options, (res) => {
  console.log(`statusCode: ${res.statusCode}`);

  res.on('data', (d) => {
    process.stdout.write(d);
  });
});

req.on('error', (error) => {
  console.error(error);
});

req.write(JSON.stringify(data));
req.end();