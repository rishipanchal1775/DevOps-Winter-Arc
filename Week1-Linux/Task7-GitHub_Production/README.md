# Task 7 — Git/GitHub + Production Challenge

## 🎯 Objective

Learn Git and GitHub workflows by pushing a project, creating branches, committing changes, and opening Pull Requests. Then simulate and troubleshoot a broken Linux/Nginx setup.

## 📁 Project Structure

```text
Task7-GitHub_Production/
├── README.md
├── .gitignore
├── app/
│   └── index.html
├── nginx/
│   └── devops-lab.conf
├── scripts/
│   └── health-check.sh
└── logs/
    └── incident-report.md
```

## 🧰 Prerequisites

- Ubuntu on WSL2
- Git installed
- GitHub account and an existing repository
- Nginx, curl, and sudo access
- Basic knowledge of Linux commands and permissions

Install the required packages:

```bash
sudo apt update
sudo apt install git nginx curl
```

## Task 1 — Check Git

```bash
git --version
git status
git branch
git remote -v
```

**Learn:** Git version, working tree status, current branch, and remote repository.

## Task 2 — Create the Application

Create the project directories:

```bash
mkdir -p app nginx scripts logs
```

Create `app/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>DevOps Production Lab</title>
</head>
<body>
    <h1>DevOps Production Challenge</h1>
    <p>Git, Linux, and Nginx troubleshooting practice.</p>
</body>
</html>
```

Create `scripts/health-check.sh`:

```bash
#!/bin/bash

echo "=== Nginx Status ==="
systemctl is-active nginx

echo
echo "=== HTTP Response ==="
curl -I --max-time 5 http://127.0.0.1/

echo
echo "=== Port 80 ==="
sudo ss -lntp | grep ':80'
```

Make the script executable:

```bash
chmod +x scripts/health-check.sh
./scripts/health-check.sh
```

Note: If systemd is unavailable in WSL, use Nginx commands and logs instead of `systemctl`.

## Task 3 — Configure `.gitignore`

Create `.gitignore`:

```gitignore
# Logs
*.log
logs/*.txt

# Secrets and environment files
.env
.env.*
!.env.example

# Python cache
__pycache__/
*.pyc

# Temporary files
*.tmp
*.swp
```

Test it:

```bash
touch test.log
git status --short
```

**Learn:** `.gitignore` prevents matching untracked files from being added accidentally. It does not automatically untrack files already committed.

Never commit passwords, private keys, access tokens, or real secrets.

## Task 4 — Commit and Push

Check the files:

```bash
git status
git add .
git status
git commit -m "Add Task 7 production lab"
git log --oneline -5
```

Check the configured remote:

```bash
git remote -v
```

If a remote is not configured, add your own GitHub repository URL:

```bash
git remote add origin https://github.com/YOUR_USERNAME/DevOps-Winter-Arc.git
```

Push your current branch. For example:

```bash
git push -u origin main
```

Replace `main` with your actual branch name if necessary.

## Task 5 — Create a Feature Branch

```bash
git switch -c feature/add-lab-notes
```

Make a small change to `README.md` or `app/index.html`, then commit and push it:

```bash
git add .
git commit -m "Add production lab notes"
git push -u origin feature/add-lab-notes
```

**Learn:** Branches allow changes to be developed independently from the main branch.

## Task 6 — Open a Pull Request

1. Open your repository on GitHub.
2. Select **Compare & pull request**.
3. Set the base branch to `main` or your default branch.
4. Add a title and description.
5. Review the **Files changed** tab.
6. Create and merge the PR after reviewing.

Update your local branch:

```bash
git switch main
git pull --ff-only origin main
git log --oneline --graph --all -10
```

Use your repository's actual default branch name if it is not `main`.

## Task 7 — Configure a Test Nginx Site

Create `nginx/devops-lab.conf`:

```nginx
server {
    listen 8085;
    server_name localhost;

    root /home/rishi/DevOps-Winter-Arc/Week1-Linux/Task7-GitHub_Production/app;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Replace the example root path with the actual absolute path to your `app` directory.

Check it:

```bash
realpath app/index.html
```

Install the test configuration:

```bash
sudo cp nginx/devops-lab.conf /etc/nginx/sites-available/devops-lab
sudo ln -s /etc/nginx/sites-available/devops-lab /etc/nginx/sites-enabled/devops-lab
```

If the symbolic link already exists, inspect it rather than creating another one.

Validate and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

If systemd is unavailable, use `sudo nginx -s reload` after validating the configuration.

Test the page:

```bash
curl -i http://127.0.0.1:8085/
```

Expected result: HTTP `200 OK` with the HTML content.

## Task 8 — Simulate a Port Configuration Issue

Change the test configuration from:

```nginx
listen 8085;
```

to:

```nginx
listen 8086;
```

Copy the changed file into the test configuration:

```bash
sudo cp nginx/devops-lab.conf /etc/nginx/sites-available/devops-lab
sudo nginx -t
```

If the configuration test succeeds, reload Nginx:

```bash
sudo systemctl reload nginx
```

Test both ports:

```bash
curl -I --max-time 3 http://127.0.0.1:8085/
curl -I --max-time 3 http://127.0.0.1:8086/
sudo ss -lntp | grep -E ':8085|:8086'
```

**Learn:** A service can be running while a particular URL or port is unavailable because the configuration may be incorrect.

Restore port `8085`, copy the configuration back, validate it, and reload Nginx.

## Task 9 — Simulate and Fix a Permission Issue

Remove read permissions from the test HTML file:

```bash
chmod 000 app/index.html
```

Test the website and inspect the logs:

```bash
curl -i http://127.0.0.1:8085/
sudo tail -n 30 /var/log/nginx/error.log
```

Restore read permissions:

```bash
chmod 644 app/index.html
```

Verify:

```bash
curl -i http://127.0.0.1:8085/
```

Expected result: HTTP `200 OK`.

**Learn:** Nginx must have permission to read the file and traverse its parent directories.

## Task 10 — Troubleshoot Nginx

Run the relevant checks:

```bash
sudo nginx -t
sudo systemctl status nginx
sudo journalctl -u nginx -n 50 --no-pager
sudo tail -n 50 /var/log/nginx/error.log
sudo ss -lntp
curl -v --max-time 5 http://127.0.0.1:8085/
```

If systemd is unavailable, skip the `systemctl` and `journalctl` commands.

Investigate in this order:

1. Configuration syntax
2. Service status
3. Listening port
4. File and directory permissions
5. Error logs

Do not assume the root cause before collecting evidence.

## Task 11 — Write an Incident Report

Create `logs/incident-report.md`:

```markdown
# Production Incident Report

## Problem
What failed?

## Impact
Which service or URL was unavailable?

## Evidence
Include relevant curl, ss, nginx -t, or log output.

## Root Cause
What caused the failure?

## Fix
What did you change?

## Verification
Which command proved the fix worked?

## Prevention
How could the problem be caught before deployment?
```

Fill it with the evidence from one of your simulated failures.

## Task 12 — Commit and Merge the Fix

Create a new branch:

```bash
git switch -c fix/nginx-incident-report
```

Commit and push the incident report:

```bash
git add .
git commit -m "Document Nginx troubleshooting incident"
git push -u origin fix/nginx-incident-report
```

Open a second PR on GitHub, review the changes, and merge it.

Update your local default branch afterward.

## 📚 Key Commands

| Command | Purpose |
|---|---|
| `git status` | Check working tree changes |
| `git add` | Stage changes |
| `git commit` | Save a local snapshot |
| `git push` | Upload commits to a remote |
| `git pull` | Fetch and integrate remote changes |
| `git switch -c` | Create and switch to a branch |
| `git log --oneline` | View commit history |
| `git diff` | Inspect unstaged changes |
| `git diff --staged` | Inspect staged changes |
| `nginx -t` | Validate Nginx configuration |
| `ss -lntp` | Inspect listening TCP ports |
| `curl -i` | Test an HTTP response |
| `journalctl -u nginx` | Inspect service logs when systemd is available |
| `tail` | Inspect recent log entries |

## ✅ Completion Checklist

- [ ] Created and pushed the Task 7 project.
- [ ] Created a `.gitignore`.
- [ ] Committed changes with meaningful messages.
- [ ] Created a feature branch.
- [ ] Opened and merged a pull request.
- [ ] Served the test HTML page through Nginx.
- [ ] Diagnosed and fixed a port configuration issue.
- [ ] Diagnosed and fixed a permission issue.
- [ ] Collected logs and verified the fixes.
- [ ] Wrote and committed an incident report through a second PR.

## 🎓 Interview Questions

1. What is the difference between Git and GitHub?
2. What is the difference between `git commit` and `git push`?
3. Why do teams use branches and pull requests?
4. Why should secrets be excluded from Git?
5. Why can Nginx be running while a website is unavailable?
6. How do you troubleshoot a `403 Forbidden` response?
7. How do you troubleshoot an Nginx configuration error?
8. Why should every production fix be verified?

## 🏁 Final Goal

Complete the GitHub workflow, successfully serve the test application through Nginx, troubleshoot simulated failures, and document the evidence, root cause, fix, and verification in an incident report.
