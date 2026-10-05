# Task 1 - Linux Fundamentals & Shell Practice

## 📁 File Structure

```text
devops-app/
├── app/
│   ├── app.py
│   ├── server.sh
│   └── README.md
├── config/
│   └── app.conf
├── logs/
│   ├── app.log
│   ├── error.log
│   └── access.log
├── backup/
└── reports/
```

---

## Task 1 — Create Workspace

**Task:** Create the application directory structure.

**Solution:**

```bash
mkdir -p devops-app/{app,config,logs,backup,reports}
```

---

## Task 2 — Create Application Files

**Task:** Create `app.py`, `server.sh`, and `README.md`.

**Solution:**

```bash
touch devops-app/app/{app.py,server.sh,README.md}
```

---

## Task 3 — Create Configuration

**Task:** Create `app.conf` with application settings.

**Solution:**

```bash
echo "APP_NAME=devops-app" > devops-app/config/app.conf
echo "PORT=8080" >> devops-app/config/app.conf
echo "ENVIRONMENT=production" >> devops-app/config/app.conf
```

---

## Task 4 — Create Logs

**Task:** Create application, error, and access logs.

**Solution:**

```bash
touch devops-app/logs/{app.log,error.log,access.log}
```

---

## Task 5 — Search Errors

**Task:** Find all `ERROR` messages in the application log.

**Solution:**

```bash
grep "ERROR" devops-app/logs/app.log
```

---

## Task 6 — Find Log Files

**Task:** Find all `.log` files inside the application directory.

**Solution:**

```bash
find devops-app -type f -name "*.log"
```

---

## Task 7 — Count Errors

**Task:** Count the number of error messages.

**Solution:**

```bash
grep "ERROR" devops-app/logs/error.log | wc -l
```

---

## Task 8 — Find HTTP Errors

**Task:** Find HTTP `500` and `401` responses from the access log.

**Solution:**

```bash
grep -E "500|401" devops-app/logs/access.log
```

---

## Task 9 — Generate Error Report

**Task:** Save all application errors into a report file.

**Solution:**

```bash
grep -Rni "ERROR" devops-app/logs > devops-app/reports/errors.txt
```

---

## Task 10 — DevOps Log Investigation

**Task:** Search logs for common production problems such as errors, failures, timeouts, and refused connections.

**Solution:**

```bash
grep -RniE "error|failed|timeout|refused" devops-app/logs
```

---

## Commands Practiced

```text
mkdir    → Create directories
touch    → Create files
cat      → Read files
find     → Find files
grep     → Search text
wc       → Count results
|        → Pipe output
>        → Redirect/overwrite
>>       → Append output
```
