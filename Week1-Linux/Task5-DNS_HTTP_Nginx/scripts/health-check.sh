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
    echo "Application is reachable through Nginx"
else
    echo
    echo "Application check failed; inspect Nginx and backend logs"
    exit 1
fi
