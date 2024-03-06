import json
import ssl
from http.server import BaseHTTPRequestHandler, HTTPServer

class RequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if 'Content-Length' not in self.headers:
            self.send_response(400)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Bad Request: Content-Length header is missing')
            return
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length).decode('utf-8')
        #Parse the JSON data
        data = json.dumps(json.loads(body), indent=2)
        print(data)
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(b'You are receiving the response sent from an HTTPS Server')

def run():
    server_address = ('10.1.1.1', 3000)
    httpd = HTTPServer(server_address, RequestHandler)
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain('d:/ssl2/server-cert.pem', keyfile='d:/ssl2/server-key.pem')
    ssl_context.load_verify_locations('d:/ssl2/ca-cert.pem')
    httpd.socket = ssl_context.wrap_socket(httpd.socket, server_side=True)
    print('Server listening on port 3000 (HTTPS)')
    httpd.serve_forever()

if __name__ == '__main__':
  run()