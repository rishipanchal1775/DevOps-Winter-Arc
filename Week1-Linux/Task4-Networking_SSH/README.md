# Task 4 — Networking & SSH

## Objective

Practice Linux networking, ports, hostname resolution, SSH key authentication, and basic network troubleshooting.

---

## File Structure

```text
Task4-Networking_SSH/
├── README.md
├── config/
│   └── hosts-notes.md
├── scripts/
│   └── network-check.sh
└── logs/
    └── troubleshooting.md
```

---

## Task 1 — Check IP & Network

### Task

Find your IP address, routing table, DNS configuration, and test connectivity.

### Solution

```bash
ip addr
ip -br addr
ip route
cat /etc/resolv.conf

ping -c 4 1.1.1.1
ping -c 4 google.com
```

### Learn

* `ip addr` → network interfaces and IP addresses
* `ip route` → routing table
* `resolv.conf` → DNS resolver configuration
* IP works but hostname fails → possible DNS problem

---

## Task 2 — Find Listening Ports

### Task

Find TCP and UDP listening ports and the processes using them.

### Solution

```bash
ss -lnt
ss -lun
ss -lntp
```

### Learn

```text
-l → listening
-n → numeric addresses/ports
-t → TCP
-u → UDP
-p → process
```

Common ports:

```text
22   → SSH
53   → DNS
80   → HTTP
443  → HTTPS
8080 → common application port
```

---

## Task 3 — Start a Test HTTP Server

### Task

Run a simple HTTP server and verify that the port is listening.

### Solution

```bash
python3 -m http.server 8080 --bind 127.0.0.1
```

In another terminal:

```bash
ss -lntp | grep 8080
curl -v http://127.0.0.1:8080/
```

Stop the server:

```text
Ctrl + C
```

### Learn

* `LISTEN` → service is waiting for connections
* `curl` → test HTTP connectivity
* `connection refused` → usually nothing is listening on that port

---

## Task 4 — Configure `/etc/hosts`

### Task

Create a local hostname for the test application.

### Solution

```bash
sudo nano /etc/hosts
```

Add:

```text
127.0.0.1 devops-lab.local
```

Test:

```bash
getent hosts devops-lab.local
```

Start the HTTP server again:

```bash
python3 -m http.server 8080 --bind 127.0.0.1
```

Test:

```bash
curl -v http://devops-lab.local:8080/
```

### Learn

`/etc/hosts` provides a local static:

```text
hostname → IP address
```

It is not a public DNS system.

---

## Task 5 — SSH Key-Based Authentication

### Task

Generate an SSH key and configure passwordless SSH to localhost.

### Solution

Install SSH:

```bash
sudo apt update
sudo apt install openssh-server openssh-client
```

Start SSH:

```bash
sudo systemctl start ssh
sudo systemctl status ssh
```

Check port 22:

```bash
sudo ss -lntp | grep ':22'
```

Generate a key:

```bash
ssh-keygen -t ed25519 -C "devops-lab"
```

Check keys:

```bash
ls -l ~/.ssh/
```

Configure authorized keys:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
```

Test:

```bash
ssh localhost
```

Exit:

```bash
exit
```

### Learn

```text
Private key → stays on your machine
Public key  → goes to the server
```

**Never share your private key.**

---

## Task 6 — Troubleshoot a Stopped SSH Service

### Task

Stop SSH and investigate why the connection fails.

### Solution

```bash
sudo systemctl stop ssh
```

Check port:

```bash
sudo ss -lntp | grep ':22'
```

Test:

```bash
ssh localhost
```

Check service:

```bash
sudo systemctl status ssh
```

Check logs:

```bash
sudo journalctl -u ssh -n 30 --no-pager
```

Start SSH again:

```bash
sudo systemctl start ssh
```

Verify:

```bash
sudo systemctl status ssh
ssh localhost
```

---

## Task 7 — Understand Connection Failures

| Problem               | Possible Cause                    | Check                 |
| --------------------- | --------------------------------- | --------------------- |
| Connection refused    | No service listening              | `ss -lntp`            |
| Connection timeout    | Firewall/network path             | `ip route`, firewall  |
| Hostname fails        | DNS/hosts problem                 | `getent hosts`        |
| SSH permission denied | Authentication problem            | SSH keys/logs         |
| HTTP 502              | Reverse proxy can't reach backend | Service + port + logs |

> A timeout does **not automatically mean firewall**. Always verify the network path and service state.

---

## Task 8 — Bash Network Check

### Task

Create a simple script to check hostname resolution, listening ports, and HTTP connectivity.

### Solution

```bash
#!/bin/bash

HOST="devops-lab.local"
PORT="8080"
URL="http://${HOST}:${PORT}/"

echo "=== Network Check ==="

echo
echo "1. Hostname resolution"
getent hosts "$HOST"

echo
echo "2. Listening TCP ports"
ss -lnt

echo
echo "3. HTTP connectivity"

if curl --connect-timeout 3 -fsS "$URL" -o /dev/null; then
    echo "HTTP service is reachable"
else
    echo "HTTP service is unavailable"
fi

echo
echo "=== Check complete ==="
```

Make executable:

```bash
chmod +x scripts/network-check.sh
```

Run:

```bash
./scripts/network-check.sh
```

---

## Task 9 — Troubleshooting Report

Record your investigation in:

```text
logs/troubleshooting.md
```

Use this format:

```text
Problem:
What was not working?

Evidence:
What commands did you run?

Root Cause:
What caused the problem?

Fix:
What did you change?

Verification:
How did you confirm it was fixed?
```

---

## Bonus Challenge — Nginx Reverse Proxy

Run an application on:

```text
127.0.0.1:3000
```

Configure Nginx to proxy:

```text
Client
   ↓
Nginx :80
   ↓
Application :3000
```

Test:

```bash
curl -v http://day5.local
```

If the application moves to port `4000`, update Nginx:

```nginx
proxy_pass http://127.0.0.1:4000;
```

Validate:

```bash
sudo nginx -t
```

Reload:

```bash
sudo systemctl reload nginx
```

---

## Commands Practiced

```text
ip
ping
ss
curl
getent
ssh
ssh-keygen
systemctl
journalctl
/etc/hosts
```

---

## Key DevOps Concepts

```text
IP       → identifies a network interface/host
Port     → identifies a service
TCP      → reliable connection-oriented protocol
UDP      → connectionless protocol
DNS      → hostname → IP resolution
/etc/hosts → local hostname mapping
SSH      → remote secure access
TLS      → secures network communication
Nginx    → web server/reverse proxy
upstream → backend application
```

---

## DevOps Troubleshooting Flow

```text
Hostname
   ↓
IP address
   ↓
Route
   ↓
Port
   ↓
Listening service
   ↓
Firewall / Network path
   ↓
Application
   ↓
Logs
   ↓
Fix
   ↓
Verify
```

### Golden Rule

**Don't guess the problem. Check each network layer and use evidence to find the root cause.**
