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
