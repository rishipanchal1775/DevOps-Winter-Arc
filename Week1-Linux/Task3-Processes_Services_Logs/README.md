# Task 3 — Processes, Services & Logs

## Objective

Build and troubleshoot a Linux `systemd` service.

Practice:

* Processes and PIDs
* `ps`
* `top`
* `systemctl`
* `journalctl`
* Signals and `kill`
* `/var/log`
* Service failures and troubleshooting
* Bash application
* `systemd` service configuration

---

# File Structure

```text
Task3-Processes_Services_Logs/
├── README.md
├── app/
│   └── devops-app.sh
├── systemd/
│   └── devops-app.service
└── logs/
    └── investigation.md
```

---

# Task 1 — Create the Application

Create directories:

```bash
mkdir -p app systemd logs
```

Create the application:

```bash
nano app/devops-app.sh
```

Add:

```bash
#!/bin/bash

while true
do
    echo "$(date) - DevOps app is running"
    sleep 10
done
```

Make it executable:

```bash
chmod +x app/devops-app.sh
```

Test:

```bash
./app/devops-app.sh
```

Stop with:

```text
Ctrl+C
```

---

# Task 2 — Create a systemd Service

Create the service:

```bash
sudo nano /etc/systemd/system/devops-app.service
```

Add:

```ini
[Unit]
Description=DevOps Practice Application
After=network.target

[Service]
Type=simple
ExecStart=/home/rishi/DevOps-Winter-Arc/Week1-Linux/Task3-Processes_Services_Logs/app/devops-app.sh
Restart=on-failure
User=rishi

[Install]
WantedBy=multi-user.target
```

> Update the `ExecStart` path if your repository is located somewhere else.

### systemd Configuration

```text
[Unit]
    ↓
Service description and startup order

[Service]
    ↓
How the application should run

[Install]
    ↓
How the service integrates with system startup
```

### Important Options

```text
ExecStart
    → Program to execute

User
    → User that runs the application

Restart=on-failure
    → Restart if the application fails

After=network.target
    → Start after network.target

WantedBy=multi-user.target
    → Used when enabling the service at boot
```

---

# Task 3 — Start and Manage the Service

Reload systemd after creating or modifying the service:

```bash
sudo systemctl daemon-reload
```

Start:

```bash
sudo systemctl start devops-app
```

Check status:

```bash
sudo systemctl status devops-app
```

Expected:

```text
Active: active (running)
```

Stop:

```bash
sudo systemctl stop devops-app
```

Restart:

```bash
sudo systemctl restart devops-app
```

Enable at boot:

```bash
sudo systemctl enable devops-app
```

Check:

```bash
systemctl is-enabled devops-app
```

---

# Task 4 — Find the Process and PID

Find the application process:

```bash
ps aux | grep devops-app
```

Better:

```bash
pgrep -af devops-app
```

Example:

```text
rishi    1234 ... devops-app.sh
```

Here:

```text
1234 = PID
```

Inspect the process:

```bash
ps -p 1234 -f
```

Replace `1234` with your actual PID.

### What `ps` is used for

`ps` gives a **snapshot** of running processes.

Useful information:

```text
PID
USER
CPU
MEMORY
COMMAND
```

---

# Task 5 — Monitor CPU and Memory with `top`

Run:

```bash
top
```

Find `devops-app`.

Important columns:

```text
PID
USER
%CPU
%MEM
COMMAND
```

### Why use `top`?

`top` continuously monitors processes and system resources.

Example:

```text
Server is slow
      ↓
     top
      ↓
High CPU process found
      ↓
      PID
      ↓
      ps
      ↓
Identify application
      ↓
journalctl / logs
```

### `ps` vs `top`

```text
ps
→ Snapshot of processes

top
→ Real-time process/resource monitoring
```

---

# Task 6 — Read Service Logs with journalctl

View all logs for the service:

```bash
sudo journalctl -u devops-app
```

View recent logs:

```bash
sudo journalctl -u devops-app -n 20
```

Follow logs live:

```bash
sudo journalctl -u devops-app -f
```

Press:

```text
Ctrl+C
```

to stop following.

View today's logs:

```bash
sudo journalctl -u devops-app --since today
```

View errors:

```bash
sudo journalctl -u devops-app -p err
```

### Why `journalctl`?

`systemd` services can send their output to the **systemd journal**.

So when a service fails:

```bash
sudo systemctl status devops-app
```

first shows the service state.

Then:

```bash
sudo journalctl -u devops-app
```

helps determine **why it failed**.

---

# Task 7 — Understand `/var/log`

Explore system logs:

```bash
ls -lah /var/log
```

Look for available logs:

```bash
sudo find /var/log -type f
```

Read the last lines of a log:

```bash
sudo tail -n 50 /var/log/syslog
```

If `syslog` is not available:

```bash
sudo journalctl -n 50
```

Find system errors:

```bash
sudo journalctl -p err -n 20
```

### When to use `/var/log` vs `journalctl`

```text
systemd service
      ↓
systemctl status
      ↓
journalctl -u service
```

Application with its own log file:

```text
Application
      ↓
/var/log/application.log
```

System-wide investigation:

```text
journalctl
/var/log
```

Don't randomly search `/var/log`.

Start with the component you are troubleshooting and follow the evidence.

---

# Task 8 — Break the Service

Stop the service:

```bash
sudo systemctl stop devops-app
```

Edit the service:

```bash
sudo nano /etc/systemd/system/devops-app.service
```

Change:

```ini
ExecStart=/home/rishi/DevOps-Winter-Arc/Week1-Linux/Task3-Processes_Services_Logs/app/devops-app.sh
```

to:

```ini
ExecStart=/home/rishi/DevOps-Winter-Arc/Week1-Linux/Task3-Processes_Services_Logs/app/wrong.sh
```

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Try to start:

```bash
sudo systemctl start devops-app
```

Check:

```bash
sudo systemctl status devops-app
```

The service should fail.

---

# Task 9 — Troubleshoot the Failure

First:

```bash
sudo systemctl status devops-app
```

Then:

```bash
sudo journalctl -u devops-app -n 20
```

Look for the actual error.

Possible output:

```text
Failed to execute .../wrong.sh
Failed at step EXEC
```

### Troubleshooting approach

```text
Service failed
      ↓
systemctl status
      ↓
Find service state/error
      ↓
journalctl -u devops-app
      ↓
Find root cause
      ↓
Fix configuration
      ↓
daemon-reload
      ↓
restart service
      ↓
verify
```

---

# Task 10 — Fix the Service

Restore the correct path:

```bash
sudo nano /etc/systemd/system/devops-app.service
```

```ini
ExecStart=/home/rishi/DevOps-Winter-Arc/Week1-Linux/Task3-Processes_Services_Logs/app/devops-app.sh
```

Reload:

```bash
sudo systemctl daemon-reload
```

Restart:

```bash
sudo systemctl restart devops-app
```

Verify:

```bash
sudo systemctl status devops-app
```

Expected:

```text
Active: active (running)
```

---

# Task 11 — Practice Linux Signals

Find the PID:

```bash
pgrep -af devops-app
```

Send `SIGTERM`:

```bash
kill PID
```

Example:

```bash
kill 1234
```

Check:

```bash
sudo systemctl status devops-app
```

### SIGTERM vs SIGKILL

Normal termination:

```bash
kill PID
```

sends:

```text
SIGTERM (15)
```

It politely asks the process to terminate.

Force termination:

```bash
kill -9 PID
```

sends:

```text
SIGKILL (9)
```

The process cannot catch or ignore `SIGKILL`.

### General rule

```text
SIGTERM
→ Try this first

SIGKILL
→ Last resort
```

---

# Task 12 — Create Investigation Report

Create:

```bash
nano logs/investigation.md
```

Example:

```markdown
# Service Investigation

## Service

devops-app

## Problem

Service failed to start.

## Commands Used

systemctl status devops-app
journalctl -u devops-app
ps aux | grep devops-app
top

## Root Cause

Incorrect ExecStart path in the systemd service file.

## Fix

Corrected the ExecStart path.

Reloaded systemd and restarted the service.

## Verification

systemctl status devops-app

Result:

Active (running)
```

---

# Final Troubleshooting Challenge

Imagine someone reports:

> "The DevOps application is down."

Troubleshoot it without looking at the previous steps.

Use:

```bash
systemctl status devops-app
journalctl -u devops-app
ps
top
kill
```

Follow this approach:

```text
              Application Down
                     │
                     ↓
            systemctl status
                     │
             ┌───────┴───────┐
             ↓               ↓
          Running?          Failed?
             │               │
             ↓               ↓
             ps          journalctl
             │               │
             ↓               ↓
            PID          Find error
             │               │
             └───────┬───────┘
                     ↓
                 Fix issue
                     ↓
              restart service
                     ↓
                  verify
```

---

# Commands Learned

| Command             | Purpose                          |
| ------------------- | -------------------------------- |
| `ps`                | View running processes           |
| `top`               | Monitor processes and CPU/memory |
| `pgrep`             | Find process/PID                 |
| `kill`              | Send a signal to a process       |
| `systemctl start`   | Start service                    |
| `systemctl stop`    | Stop service                     |
| `systemctl restart` | Restart service                  |
| `systemctl status`  | Check service status             |
| `systemctl enable`  | Enable service at boot           |
| `journalctl`        | Read systemd journal             |
| `tail`              | View end of log file             |
| `find`              | Search files                     |
| `daemon-reload`     | Reload systemd configuration     |

---

# DevOps Troubleshooting Mental Model

```text
systemctl
    ↓
Is the service running?
    ↓
journalctl
    ↓
Why did it fail?
    ↓
ps / pgrep
    ↓
Which process and PID?
    ↓
top
    ↓
Is it consuming CPU/RAM?
    ↓
/var/log
    ↓
Are there application/system logs?
    ↓
Fix
    ↓
Restart
    ↓
Verify
```

## Key Takeaways

* `systemctl` → **manage services**
* `journalctl` → **investigate service/system logs**
* `ps` → **inspect processes**
* `top` → **monitor processes and resource usage**
* `kill` → **send signals to processes**
* `/var/log` → **application/system log files**
* `systemd` → **service and system manager**
* `PID` → **unique identifier of a running process**
* `SIGTERM` → **graceful termination**
* `SIGKILL` → **forceful termination**

This task simulates a common DevOps incident:

> **Service is down → investigate → identify root cause → fix → restart → verify.**

