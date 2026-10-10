from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = {
            "message": "Hello from the DevOps application",
            "path": self.path
        }

        body = json.dumps(response).encode()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        self.send_response(201)
        self.end_headers()
        self.wfile.write(b"Resource created")

HTTPServer(("127.0.0.1", 3000), Handler).serve_forever()
