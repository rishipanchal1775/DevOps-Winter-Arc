# Task 5 — DNS, HTTP/HTTPS & Nginx Reverse Proxy

## Objective

Deploy a web application on port `3000`, configure Nginx on port `80`, map a local hostname, and troubleshoot `502 Bad Gateway` errors.

## File Structure

```text
Task5-DNS_HTTP_Nginx/
├── README.md
├── app/
│   └── app.py
├── nginx/
│   └── devops-lab.conf
├── scripts/
│   └── health-check.sh
└── logs/
    └── troubleshooting.md
```

## Task 1 — DNS and Hostname Resolution

**Task:** Check DNS records and map a local hostname.

```bash
dig google.com
dig google.com +short
dig google.com A

sudo nano /etc/hosts
```

Add:

```text
127.0.0.1 devops-lab.local
```

Verify:

```bash
getent hosts devops-lab.local
```

**Learn:** `dig` queries DNS; `getent hosts` checks system hostname resolution; `/etc/hosts` provides local hostname-to-IP mappings.

## Task 2 — Create an Application on Port 3000

Create `app/app.py`:

```python
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
```

Run:

```bash
python3 app/app.py
```

Test from another terminal:

```bash
curl -i http://127.0.0.1:3000/
curl -i http://127.0.0.1:3000/health
curl -i -X POST http://127.0.0.1:3000/
ss -lntp | grep ':3000'
```

**Learn:** The application listens on port `3000`. GET returns `200 OK`; POST returns `201 Created`.

## Task 3 — Configure Nginx Reverse Proxy

Create `/etc/nginx/sites-available/devops-lab`:

```nginx
server {
    listen 80;
    server_name devops-lab.local;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the configuration:

```bash
sudo ln -s /etc/nginx/sites-available/devops-lab \
  /etc/nginx/sites-enabled/devops-lab
```

Validate and start Nginx:

```bash
sudo nginx -t
sudo systemctl start nginx
sudo systemctl reload nginx
sudo systemctl status nginx
```

Test:

```bash
curl -i http://devops-lab.local/
curl -i http://devops-lab.local/health
```

**Learn:** Nginx listens on port `80` and forwards requests to the backend on port `3000`.

## Task 4 — HTTP Methods and Status Codes

```bash
curl -i http://devops-lab.local/
curl -i -X POST http://devops-lab.local/
curl -i http://devops-lab.local/missing
```

| Status | Meaning |
|---|---|
| `200` | Request succeeded |
| `201` | Resource created |
| `301/302` | Redirect |
| `400` | Bad request |
| `401` | Authentication required |
| `403` | Forbidden |
| `404` | Not found |
| `500` | Internal server error |
| `502` | Bad gateway |
| `504` | Gateway timeout |

Note: This sample application returns `200` for every GET path, including `/missing`.

## Task 5 — Troubleshoot 502 Bad Gateway

**Task:** Stop the backend and investigate the failure.

Stop the Python application with `Ctrl+C`, then run:

```bash
curl -i --max-time 5 http://devops-lab.local/

ss -lntp | grep ':3000'

sudo tail -n 50 /var/log/nginx/error.log
sudo tail -n 30 /var/log/nginx/access.log
```

**Root cause:** Nginx is running, but the backend is not listening on port `3000`.

Fix:

```bash
python3 app/app.py
```

In another terminal, verify:

```bash
curl -i http://127.0.0.1:3000/
curl -i http://devops-lab.local/
```

**Learn:** A `502` often means Nginx cannot obtain a valid response from its upstream application.

## Task 6 — Troubleshoot an Incorrect Upstream Port

Change `proxy_pass` to an incorrect port:

```nginx
proxy_pass http://127.0.0.1:3999;
```

Validate and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -i http://devops-lab.local/
sudo tail -n 30 /var/log/nginx/error.log
```

**Fix:** Restore port `3000`, validate the configuration, reload Nginx, and test again.

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -i http://devops-lab.local/
```

## Task 7 — Create a Health-Check Script

Create `scripts/health-check.sh`:

```bash
#!/bin/bash

HOST="devops-lab.local"
URL="http://${HOST}/"

echo "=== DNS Check ==="
if getent hosts "$HOST"; then
    echo "Hostname resolved"
else
    echo "Hostname resolution failed"
    exit 1
fi

echo
echo "=== Nginx Check ==="
if systemctl is-active --quiet nginx; then
    echo "Nginx is running"
else
    echo "Nginx is not running"
    exit 1
fi

echo
echo "=== HTTP Check ==="
if curl --connect-timeout 3 -fsS "$URL"; then
    echo
    echo "Application is reachable"
else
    echo
    echo "Application check failed; inspect logs"
    exit 1
fi
```

Run:

```bash
chmod +x scripts/health-check.sh
./scripts/health-check.sh
```

## Task 8 — HTTPS and TLS Basics

- HTTP commonly uses port `80`.
- HTTPS commonly uses port `443`.
- TLS provides encryption, integrity, and server authentication.
- A certificate helps verify the server's identity for a hostname.
- Nginx can terminate HTTPS and proxy requests to a backend over HTTP on localhost.

**Note:** HTTPS is a concept to study in this lab; the deployment above uses HTTP only.

## Task 9 — Troubleshooting Report

Record findings in `logs/troubleshooting.md`:

```markdown
# Nginx Troubleshooting Report

## Problem
The application returned 502 Bad Gateway.

## Evidence
- curl output
- ss -lntp output
- Nginx error log

## Root Cause
Backend stopped or incorrect upstream port.

## Fix
Restarted the application or corrected proxy_pass.

## Verification
The application returned HTTP 200 through Nginx.
```

## Commands Practiced

```text
dig
getent
curl
ss
nginx -t
systemctl
journalctl
docker (optional for containerized deployment)
```

## Key DevOps Concepts

- DNS resolves hostnames to IP addresses.
- `/etc/hosts` provides local hostname mappings.
- HTTP methods define request actions.
- HTTP status codes describe response outcomes.
- Nginx acts as a web server and reverse proxy.
- `proxy_pass` specifies the upstream application.
- `502` often indicates an upstream problem.
- `504` indicates an upstream timeout.
- TLS secures HTTPS communication.

## Troubleshooting Flow

```text
Hostname resolution
        ↓
Nginx status and port 80
        ↓
Backend listener and port 3000
        ↓
HTTP response and status code
        ↓
Nginx and application logs
        ↓
Fix and verify
```

**Golden Rule:** Check each layer using evidence instead of guessing the root cause.
