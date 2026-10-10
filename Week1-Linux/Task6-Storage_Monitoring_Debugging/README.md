# Task 6 — Storage, Monitoring & Debugging

## Objective

Practice Linux disk management, filesystem mounting, `/etc/fstab`, disk-space troubleshooting, inode usage, and resource monitoring.

## File Structure

```text
Task6-Storage_Monitoring_Debugging/
├── README.md
├── scripts/
│   └── disk-check.sh
├── logs/
│   └── investigation.md
└── reports/
    └── disk-usage.txt
```

## Task 1 — Inspect Disk and Memory

**Task:** Check filesystem space, inode usage, memory, and block devices.

### Solution

```bash
df -h
df -i
du -sh ~
free -h
lsblk
findmnt
```

Save the disk report:

```bash
df -h > reports/disk-usage.txt
```

**Learn:**
- `df -h` → filesystem space
- `df -i` → inode usage
- `du -sh` → directory size
- `free -h` → RAM and swap
- `lsblk` → block devices
- `findmnt` → mounted filesystems

## Task 2 — Create and Mount a Practice Disk

**Task:** Create a 128 MiB disk image, format it as ext4, and mount it.

### Solution

```bash
mkdir -p ~/disk-lab
sudo mkdir -p /mnt/devops-lab

sudo dd if=/dev/zero of=~/disk-lab/devops-disk.img \
  bs=1M count=128 status=progress

sudo mkfs.ext4 ~/disk-lab/devops-disk.img

sudo mount -o loop ~/disk-lab/devops-disk.img /mnt/devops-lab
```

Verify:

```bash
findmnt /mnt/devops-lab
df -h /mnt/devops-lab
lsblk
```

**Learn:** `dd` creates the disk image, `mkfs.ext4` creates its filesystem, and `mount -o loop` mounts a filesystem stored in a regular file.

**Warning:** Format only the newly created practice image, never a real disk containing data.

## Task 3 — Configure Persistent Mounting

**Task:** Configure the practice disk in `/etc/fstab`.

### Solution

Get the absolute image path:

```bash
realpath ~/disk-lab/devops-disk.img
```

Back up the configuration:

```bash
sudo cp /etc/fstab /etc/fstab.backup-task6
sudo nano /etc/fstab
```

Add one line using your actual image path:

```text
/home/rishi/disk-lab/devops-disk.img /mnt/devops-lab ext4 loop,nofail 0 0
```

Test the entry:

```bash
sudo umount /mnt/devops-lab
sudo mount -a
findmnt /mnt/devops-lab
df -h /mnt/devops-lab
```

**Learn:** `/etc/fstab` stores filesystem mount configuration. Always test changes before restarting the system.

## Task 4 — Simulate a Disk-Full Incident

**Task:** Create large test files, identify the space hog, and recover space.

### Solution

```bash
sudo fallocate -l 60M /mnt/devops-lab/app-data.bin
sudo fallocate -l 25M /mnt/devops-lab/backup-data.bin
```

Investigate:

```bash
df -h /mnt/devops-lab
sudo du -sh /mnt/devops-lab
sudo du -ah /mnt/devops-lab | sort -h
sudo find /mnt/devops-lab -type f -exec du -h {} + | sort -h
```

Remove the selected test file:

```bash
sudo rm /mnt/devops-lab/app-data.bin
```

Verify:

```bash
df -h /mnt/devops-lab
sudo du -sh /mnt/devops-lab
```

**Learn:** `df` shows filesystem usage, while `du` identifies space consumed by files and directories. Investigate files before deleting them on production systems.

## Task 5 — Check Inode Usage

**Task:** Investigate inode exhaustion.

### Solution

```bash
df -i
df -i /mnt/devops-lab
```

**Learn:**
- Disk-space exhaustion means insufficient free storage capacity.
- Inode exhaustion means the filesystem cannot allocate enough file entries, even if some storage space remains.

## Task 6 — Create a Disk Monitoring Script

**Task:** Automate disk, inode, memory, and filesystem checks.

Create `scripts/disk-check.sh`:

```bash
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
```

Make executable and run:

```bash
chmod +x scripts/disk-check.sh
./scripts/disk-check.sh
```

Save the output:

```bash
./scripts/disk-check.sh > reports/disk-usage.txt 2>&1
```

Review:

```bash
cat reports/disk-usage.txt
```

## Task 7 — Verify Mount After Restarting WSL

**Task:** Confirm that the `/etc/fstab` configuration is loaded after restarting WSL.

Before restarting:

```bash
findmnt /mnt/devops-lab
```

In Windows PowerShell:

```powershell
wsl --shutdown
```

Reopen Ubuntu and verify:

```bash
findmnt /mnt/devops-lab
df -h /mnt/devops-lab
ls -lh /mnt/devops-lab
```

If it did not mount:

```bash
cat /etc/fstab
sudo mount -av
findmnt /mnt/devops-lab
```

**Learn:** WSL startup differs from a traditional Linux server, so verify the actual mount after restarting WSL.

## Task 8 — Write a Troubleshooting Report

Create `logs/investigation.md`:

```markdown
# Storage Incident Report

## Problem
The practice filesystem was almost full.

## Evidence
- `df -h` showed filesystem usage.
- `du -ah` identified large files.
- `df -i` checked inode usage.

## Root Cause
Large test files consumed disk space.

## Fix
Removed the selected test file.

## Verification
`df -h` showed more available space.

## Persistent Mount
Configured `/etc/fstab`, tested with `mount -a`,
and verified the mount after restarting WSL.
```

Update this report with your actual results.

## Key Commands

| Command | Purpose |
|---|---|
| `df -h` | Filesystem space |
| `df -i` | Inode usage |
| `du -sh` | Directory size |
| `free -h` | Memory and swap |
| `lsblk` | Block devices |
| `findmnt` | Mounted filesystems |
| `mount` / `umount` | Mount and unmount |
| `/etc/fstab` | Persistent mount configuration |
| `lsof +L1` | Find deleted files still open by processes |

## DevOps Troubleshooting Flow

```text
Storage Alert
     ↓
Check df -h and df -i
     ↓
Find large files with du
     ↓
Identify the root cause
     ↓
Fix the issue safely
     ↓
Verify available space
     ↓
Check persistent mounts
     ↓
Document the investigation
```

**Golden Rule:** Identify whether the problem is disk capacity, inode exhaustion, memory pressure, or mount configuration before applying a fix.
