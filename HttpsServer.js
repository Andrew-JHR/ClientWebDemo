const https = require('https');
const fs = require('fs');
const express = require('express');

const app = express();

// load the SSL/TLS certificate and key files
const options = {
  key: fs.readFileSync('d:/ssl2/server-key.pem'),
  cert: fs.readFileSync('d:/ssl2/server-cert.pem'),
  ca: fs.readFileSync('d:/ssl2/ca-cert.pem')
};

// define a route to handle POST requests
app.post('/api/data', (req, res) => {
  let body = '';
  req.on('data', (chunk) => {
    body += chunk.toString();
  });
  req.on('end', () => {
    // console.log('Received data:', body);
    // Parse the JSON data
    const data = JSON.parse(body);
    console.log(data);
    res.send('You are receiving the response sent from a HTTPS Server');
  });
});

// start the HTTPS server
https.createServer(options, app).listen(3000, () => {
  console.log('Server listening on port 3000 (HTTPS)');
});