#!/bin/bash

echo "=== Disk Usage ==="
df -h

echo
echo "=== Inode Usage ==="
df -i

echo
echo "=== Memory Usage ==="
free -h

echo
echo "=== Block Devices ==="
lsblk

echo
echo "=== Largest Items in Practice Disk ==="
sudo du -ah /mnt/devops-lab | sort -h | tail -n 10
