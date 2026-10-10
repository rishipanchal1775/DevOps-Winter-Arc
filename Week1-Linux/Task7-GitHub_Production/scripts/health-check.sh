#!/bin/bash

echo "=== Nginx Status ==="
systemctl is-active nginx

echo
echo "=== HTTP Response ==="
curl -I --max-time 5 http://127.0.0.1/

echo
echo "=== Port 80 ==="
sudo ss -lntp | grep ':80'
