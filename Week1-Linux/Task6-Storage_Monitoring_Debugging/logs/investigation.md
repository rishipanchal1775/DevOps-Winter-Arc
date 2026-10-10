# Storage Incident Report

## Problem
The practice filesystem was almost full.

## Evidence
- `df -h` showed filesystem capacity and usage.
- `du -ah` identified large files.
- `df -i` checked inode usage.

## Root Cause
Large test files consumed most of the practice disk space.

## Fix
Removed the selected test file.

## Verification
`df -h` showed more available space.

## Persistent Mount
Configured `/etc/fstab`, tested with `mount -a`,
and checked the mount after restarting WSL.
