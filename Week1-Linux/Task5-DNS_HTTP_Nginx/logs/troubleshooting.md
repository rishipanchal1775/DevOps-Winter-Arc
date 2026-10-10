# Nginx Troubleshooting Report

## Problem
The application returned 502 Bad Gateway.

## Evidence
- `curl -i http://devops-lab.local/`
- `ss -lntp`
- `/var/log/nginx/error.log`

## Root Cause
The backend was stopped / the upstream port was incorrect.

## Fix
Restarted the backend / corrected `proxy_pass`.

## Verification
The application returned HTTP 200 through Nginx.
