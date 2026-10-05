# Task 2 — Users, Groups & Permissions

## File Structure

```text
Task2-User_Group_Permission/
├── README.md
├── config/
│   └── app.config
└── scripts/
    └── setup-app.sh
```

## Objective

Create a shared application configuration where:

* `devops` group members can **read and modify** the file.
* Other users can **read only**.
* Configure everything manually first.
* Automate the setup using a Bash script.

---

## Task 1 — Create `devops` Group

### Solution

```bash
sudo groupadd devops
getent group devops
```

---

## Task 2 — Create Developer User

### Solution

```bash
sudo useradd -m dev1
sudo passwd dev1
```

Add user to the `devops` group:

```bash
sudo usermod -aG devops dev1
```

Verify:

```bash
groups dev1
```

Expected:

```text
dev1 devops
```

---

## Task 3 — Create Application Config

### Solution

```bash
mkdir -p config
touch config/app.config
```

Add sample configuration:

```bash
echo "APP_NAME=DevOpsApp" > config/app.config
echo "ENVIRONMENT=development" >> config/app.config
echo "PORT=8080" >> config/app.config
```

---

## Task 4 — Set Group Ownership

Change the file group to `devops`:

```bash
sudo chown $USER:devops config/app.config
```

Verify:

```bash
ls -l config/app.config
```

---

## Task 5 — Set Permissions

Give owner and `devops` group read/write access, others read-only:

```bash
chmod 664 config/app.config
```

Expected:

```text
-rw-rw-r--
```

Meaning:

```text
Owner   → read + write
Group   → read + write
Others  → read only
```

---

## Task 6 — Test Developer Access

Switch to the developer:

```bash
su - dev1
```

Check group:

```bash
groups
```

Read the file:

```bash
cat /home/rishi/DevOps-Winter-Arc/Week1-Linux/Task2-User_Group_Permission/config/app.config
```

Test writing:

```bash
echo "# Developer change" >> /home/rishi/DevOps-Winter-Arc/Week1-Linux/Task2-User_Group_Permission/config/app.config
```

The developer should be able to modify the file.

---

## Task 7 — Test Other User

Create another user:

```bash
sudo useradd -m tester
sudo passwd tester
```

Switch user:

```bash
su - tester
```

Read:

```bash
cat /home/rishi/DevOps-Winter-Arc/Week1-Linux/Task2-User_Group_Permission/config/app.config
```

Read should work.

Try modifying:

```bash
echo "# Unauthorized change" >> /home/rishi/DevOps-Winter-Arc/Week1-Linux/Task2-User_Group_Permission/config/app.config
```

Expected:

```text
Permission denied
```

---
* Permission troubleshooting
* `su`
