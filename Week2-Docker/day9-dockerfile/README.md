# Day 9 — Dockerfile Deep Dive

## 🎯 Objective

Build a reusable Docker image for a Node.js HTTP API, configure it at runtime, understand Docker layer caching, experiment with `CMD` and `ENTRYPOINT`, and inspect image metadata.

## 📁 Project Structure

```text
day2-dockerfile/
├── Dockerfile
├── Dockerfile.greeter
├── .dockerignore
├── package.json
├── server.js
├── README.md
└── evidence/
    ├── health-check.png
    ├── env-override.png
    ├── cache-hit.png
    └── entrypoint-test.png
```

## 🧰 Prerequisites

- Docker Desktop with WSL2 integration, or a working Docker Engine
- Ubuntu terminal
- Basic knowledge of Linux commands and JavaScript
- Git and a GitHub repository

Verify Docker:

```bash
docker --version
docker info
```

## Task 1 — Create the Node.js Application

Create `server.js`:

```javascript
const http = require("http");

const PORT = process.env.PORT || 3000;
const GREETING = process.env.GREETING || "Hello from Docker";

http.createServer((req, res) => {
    if (req.url === "/health") {
        res.writeHead(200);
        return res.end("ok");
    }

    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end(`${GREETING} | env=${process.env.APP_ENV || "dev"}\n`);

}).listen(PORT, "0.0.0.0", () => {
    console.log(`listening on ${PORT}`);
});
```

### Explanation

- `require("http")` imports Node.js's built-in HTTP module.
- `process.env.PORT` reads the port from an environment variable; otherwise, port `3000` is used.
- `process.env.GREETING` reads the greeting; otherwise, `Hello from Docker` is used.
- `http.createServer()` creates an HTTP server.
- `req.url` identifies the requested path.
- `/health` returns HTTP `200` and the text `ok`.
- Other paths return the greeting and the `APP_ENV` value.
- `listen(PORT, "0.0.0.0")` listens on the chosen port on all container network interfaces.
- `console.log()` writes the startup message to the container logs.

Create `package.json`:

```json
{
  "name": "demo-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  }
}
```

### Explanation

- `name` identifies the application package.
- `version` records the application version.
- `main` identifies the main JavaScript file.
- `scripts.start` defines the command used by `npm start`.

The application uses only built-in Node.js functionality and has no third-party dependencies.

## Task 2 — Create `.dockerignore`

```text
.git
.env
node_modules
*.log
.venv
__pycache__
```

### Explanation

- `.git` excludes Git repository metadata.
- `.env` excludes a local environment file.
- `node_modules` excludes local Node.js dependencies.
- `*.log` excludes matching log files.
- `.venv` and `__pycache__` exclude common Python environment and cache files.

`.dockerignore` reduces the build context and helps prevent unnecessary files from being copied into the image. Never store credentials in a Dockerfile or commit real secrets.

## Task 3 — Write the Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

ARG APP_VERSION=1.0

ENV PORT=3000 APP_ENV=dev APP_VERSION=$APP_VERSION

COPY package*.json ./

RUN npm install --omit=dev

COPY . .

EXPOSE 3000

USER node

CMD ["node", "server.js"]
```

### Explanation of every instruction

| Instruction | Purpose |
|---|---|
| `FROM` | Selects the base image, Node.js 20 on Alpine Linux. |
| `WORKDIR` | Sets `/app` as the working directory. |
| `ARG` | Defines a build-time argument. |
| `ENV` | Sets environment variables available at runtime. |
| `COPY package*.json ./` | Copies dependency manifests first. |
| `RUN npm install --omit=dev` | Installs production dependencies during the build. |
| `COPY . .` | Copies the remaining build-context files into `/app`. |
| `EXPOSE 3000` | Documents the intended application port; it does not publish it. |
| `USER node` | Runs the application as a non-root user. |
| `CMD` | Defines the default container command. |

### Important concepts

- **`ARG` vs `ENV`:** `ARG` is for build-time configuration; `ENV` provides image environment defaults at runtime. Neither should contain secrets.
- **`COPY` vs `ADD`:** Use `COPY` for normal file copying. `ADD` has additional features, such as automatic extraction of certain archives.
- **`EXPOSE` vs `-p`:** `EXPOSE` documents the port; `docker run -p` publishes it.
- **Non-root execution:** `USER node` reduces the privileges available to the application.

## Task 4 — Build and Run the Image

Build the image:

```bash
docker build --progress=plain -t demo-api:v1 \
  --build-arg APP_VERSION=1.0 .
```

### Explanation

- `docker build` builds an image from the Dockerfile.
- `--progress=plain` shows detailed build output.
- `-t demo-api:v1` assigns the image name and tag.
- `--build-arg` supplies the build-time `APP_VERSION`.
- `.` specifies the current directory as the build context.

Run the container:

```bash
docker run -d --name api -p 3000:3000 demo-api:v1
```

- `-d` runs the container in the background.
- `--name api` assigns a container name.
- `-p 3000:3000` maps host port `3000` to container port `3000`.
- `demo-api:v1` selects the image.

Test the endpoints:

```bash
curl -i http://localhost:3000/
curl -i http://localhost:3000/health
```

Expected response bodies:

```text
Hello from Docker | env=dev
ok
```

Both endpoints should return HTTP `200 OK`.

Inspect the container:

```bash
docker ps
docker logs api
docker inspect api
```

- `docker ps` lists running containers.
- `docker logs` shows application output.
- `docker inspect` shows detailed container configuration and state.

## Task 5 — Configure the Application at Runtime

Remove the existing container:

```bash
docker rm -f api
```

Start it with different environment variables:

```bash
docker run -d --name api -p 3000:3000 \
  -e GREETING="Hi Winter Arc" \
  -e APP_ENV=prod \
  demo-api:v1
```

### Explanation

- `-e GREETING=...` overrides the default greeting.
- `-e APP_ENV=prod` changes the environment label.
- The image remains the same; the settings change when the container starts.

Verify:

```bash
curl http://localhost:3000/
curl http://localhost:3000/health
```

Expected:

```text
Hi Winter Arc | env=prod
ok
```

### Optional: Use an environment file

Create `.env`:

```text
GREETING=Hello from env file
APP_ENV=testing
```

Start the container:

```bash
docker rm -f api

docker run -d --name api -p 3000:3000 \
  --env-file .env \
  demo-api:v1
```

Test:

```bash
curl http://localhost:3000/
```

Expected:

```text
Hello from env file | env=testing
```

The `--env-file` option supplies variables when the container starts. Keep sensitive values out of GitHub.

## Task 6 — Demonstrate Docker Layer Caching

Build the image:

```bash
docker build --progress=plain -t demo-api:v1 .
```

Change only the default greeting in `server.js`, for example:

```javascript
const GREETING = process.env.GREETING || "Hello from Docker v2";
```

Build again:

```bash
docker build --progress=plain -t demo-api:v2 .
```

Inspect the image:

```bash
docker history demo-api:v2
docker image inspect demo-api:v2
```

### Expected result

The dependency-install step should remain cached because the package manifest files and the earlier dependency-install instruction have not changed.

Now update the version in `package.json` from `1.0.0` to `1.0.1` and rebuild:

```bash
docker build --progress=plain -t demo-api:v3 .
```

The changed package manifest normally invalidates the cache for the dependency-install step and subsequent layers.

### Why the Dockerfile order matters

Copying dependency manifests and installing dependencies before copying frequently changing source code allows Docker to reuse the dependency layer when only application source changes.

Record which steps were cached in each build.

## Task 7 — Experiment with `ENTRYPOINT`

Create `Dockerfile.greeter`:

```dockerfile
FROM alpine:3.20

ENTRYPOINT ["echo", "Hello"]

CMD ["World"]
```

### Explanation

- `FROM alpine:3.20` selects a lightweight base image.
- `ENTRYPOINT` defines the main executable and fixed argument.
- `CMD` supplies the default argument to the entrypoint.

Build the image:

```bash
docker build -f Dockerfile.greeter -t greeter:local .
```

Run the default command:

```bash
docker run --rm greeter:local
```

Expected:

```text
Hello World
```

Override the default argument:

```bash
docker run --rm greeter:local DevOps
```

Expected:

```text
Hello DevOps
```

`--rm` removes the temporary container after it exits.

### CMD vs ENTRYPOINT

- `CMD` provides default commands or arguments that can be overridden at runtime.
- `ENTRYPOINT` defines the primary executable.
- When both use exec form, `CMD` commonly supplies default arguments to `ENTRYPOINT`.

## Task 8 — Production Troubleshooting

| Problem | Commands to investigate |
|---|---|
| Container exits immediately | `docker ps -a`, `docker logs api` |
| Application is unreachable | `docker ps`, `docker port api`, `curl -v http://localhost:3000/` |
| Host port is occupied | `docker ps`, then select another host port if needed |
| Build is unexpectedly slow | `cat .dockerignore`, inspect `docker build --progress=plain` |
| Environment value is unexpected | `docker inspect api`, `docker exec api printenv` |
| Permission denied | Inspect container logs, file permissions, and the `USER` instruction |

`docker exec api printenv` requires the container to be running. Review its output before sharing it publicly.

## Task 9 — Evidence and GitHub Submission

Save screenshots in `evidence/`:

- `health-check.png` — root endpoint and `/health` response.
- `env-override.png` — runtime greeting and environment override.
- `cache-hit.png` — dependency-install step showing a cache hit.
- `entrypoint-test.png` — outputs `Hello World` and `Hello DevOps`.

Before submission, confirm that the README explains every Dockerfile instruction and documents the cache and `CMD`/`ENTRYPOINT` experiments.

From the root of your existing Git repository, run:

```bash
git status
git add day2-dockerfile/
git commit -m "Add Dockerfile deep dive assignment"
git push
```

If the project is not inside your Git repository, move it into the repository first. If the branch has no upstream, configure it as appropriate for your existing GitHub setup.

## 📚 Key Commands

| Command | Purpose |
|---|---|
| `docker build` | Build an image |
| `docker run` | Create and start a container |
| `docker ps` | List running containers |
| `docker ps -a` | List all containers |
| `docker logs` | View container logs |
| `docker inspect` | Inspect container or image metadata |
| `docker history` | Review image layers and build instructions |
| `docker image ls` | List local images |
| `docker rm -f` | Force-remove a container |
| `curl -i` | Test an HTTP endpoint and display response headers |

## ✅ Completion Checklist

- [ ] Created `server.js` and `package.json`.
- [ ] Created `.dockerignore`.
- [ ] Built the Docker image and started the API container.
- [ ] Verified `/` and `/health`.
- [ ] Changed `GREETING` and `APP_ENV` at runtime.
- [ ] Demonstrated a dependency-layer cache hit.
- [ ] Rebuilt after changing `package.json`.
- [ ] Tested `CMD` override and the `ENTRYPOINT` experiment.
- [ ] Captured screenshots of the required evidence.
- [ ] Committed and pushed the project to GitHub.

## 🎓 Interview Questions

1. What is the difference between `CMD` and `ENTRYPOINT`?
2. What is the difference between `COPY` and `ADD`?
3. What is the difference between `ARG` and `ENV`?
4. Does `EXPOSE` publish a container port?
5. How does Docker layer caching work?
6. Why should dependency manifests be copied before application source?
7. Why use `.dockerignore`?
8. Why should an application container avoid running as root?

## 🏁 Final Goal

Build and test a reusable Node.js Docker image, prove that runtime configuration works, demonstrate efficient layer caching, explain `CMD` and `ENTRYPOINT`, and submit reproducible evidence through GitHub.
