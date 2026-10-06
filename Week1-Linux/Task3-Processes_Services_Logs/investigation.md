# Service Investigation

## Service
devops-app

## Problem
Service failed to start.

## Investigation

Commands used:

systemctl status devops-app
journalctl -u devops-app
ps aux | grep devops-app

## Root Cause

Incorrect ExecStart path in the systemd service file.

## Fix

Corrected the ExecStart path and reloaded systemd.

## Verification

systemctl status devops-app

Result:
Active (running)
