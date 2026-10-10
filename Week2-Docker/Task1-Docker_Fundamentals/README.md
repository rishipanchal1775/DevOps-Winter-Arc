# Week 2 — Task 1: Docker Fundamentals

## Objective

Understand Docker fundamentals, including Docker Engine, CLI, images, containers, registries, and port mapping. Run an Nginx container and build a custom Docker image to serve a personal web page.

## Lab Environment

- OS: Windows with WSL2 Ubuntu
- Container platform: Docker Desktop with WSL2 integration
- Web server: Nginx Alpine
- Registry: Docker Hub

## Project Structure

```text
Task1-Docker_Fundamentals/
├── Dockerfile
├── app/
│   └── index.html
└── evidence/
    └── screenshots
```

## Practical 1: Verify Docker Installation

```bash
docker --version
docker info
docker version
```

**Explanation:**

- `docker --version`: Displays the Docker CLI version.
- `docker info`: Displays Docker Engine details, including images and containers.
- `docker version`: Displays both client and server version information.

**Expected result:** Docker CLI and Engine are accessible.

## Practical 2: Pull and Run Nginx

### Step 1: Download the image

```bash
docker pull nginx:alpine
```

Downloads the Nginx image from Docker Hub.

### Step 2: List images

```bash
docker images
```

Displays locally available Docker images.

### Step 3: Run Nginx

```bash
docker run -d --name week2-nginx -p 8080:80 nginx:alpine
```

**Command breakdown:**

| Option | Meaning |
|---|---|
| `docker run` | Creates and starts a container |
| `-d` | Runs in the background |
| `--name week2-nginx` | Assigns a container name |
| `-p 8080:80` | Maps host port 8080 to container port 80 |
| `nginx:alpine` | Specifies the image and tag |

### Step 4: Verify

```bash
docker ps
curl -I http://localhost:8080
```

Open `http://localhost:8080` in your browser. The default Nginx welcome page should appear.

## Practical 3: Images and Containers

```bash
docker image ls
docker ps
docker ps -a
docker inspect week2-nginx
docker logs week2-nginx
```

- `docker image ls`: Lists downloaded images.
- `docker ps`: Lists running containers.
- `docker ps -a`: Lists all containers, including stopped ones.
- `docker inspect`: Shows detailed container configuration and state.
- `docker logs`: Displays the container's output logs.

### Stop and restart a container

```bash
docker stop week2-nginx
docker ps -a
docker start week2-nginx
docker ps
```

Stopping a container does not delete it. It can be started again.

## Practical 4: Create a Custom Web Page

Create the application directory and file:

```bash
mkdir -p app evidence
nano app/index.html
```

Add the following HTML:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Week 2 Docker Lab</title>
</head>
<body>
    <h1>My First Custom Docker Web Server!</h1>
    <p>Week 2 - Docker Fundamentals</p>
    <p>Served by Nginx inside a Docker container.</p>
</body>
</html>
```

Verify the file:

```bash
cat app/index.html
```

## Practical 5: Build a Custom Docker Image

Create a file named `Dockerfile` in the project root:

```dockerfile
FROM nginx:alpine

COPY app/index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

### Dockerfile explanation

- `FROM nginx:alpine`: Uses Nginx Alpine as the base image.
- `COPY app/index.html /usr/share/nginx/html/index.html`: Copies the custom HTML file into Nginx's default document directory.
- `EXPOSE 80`: Documents the port on which the containerized service listens. It does not publish the port on the host.

### Build the image

```bash
docker build -t week2-web:v1 .
```

- `-t week2-web:v1`: Assigns the image a name and tag.
- `.`: Uses the current directory as the build context.

Verify:

```bash
docker images
docker image inspect week2-web:v1
docker history week2-web:v1
```

## Practical 6: Run Your Custom Web Server

Stop and remove the original Nginx container to free host port 8080:

```bash
docker stop week2-nginx
docker rm week2-nginx
```

Run the custom image:

```bash
docker run -d --name week2-web -p 8080:80 week2-web:v1
```

Verify:

```bash
docker ps
curl http://localhost:8080
```

Open `http://localhost:8080` in your browser.

**Expected result:** Your custom HTML page appears instead of the default Nginx page.

## Practical 7: Troubleshooting Port Conflicts

Try to run another container on the same host port:

```bash
docker run -d --name conflict-test -p 8080:80 nginx:alpine
```

If `week2-web` already uses port 8080, Docker reports that the port is already allocated.

A failed run may leave a stopped or failed container with the requested name. Check:

```bash
docker ps -a
```

Remove the failed container before reusing its name:

```bash
docker rm conflict-test
```

Now use another host port:

```bash
docker run -d --name conflict-test -p 8081:80 nginx:alpine
curl -I http://localhost:8081
```

**Important:** Changing the port does not require changing the name. The name conflict happens because a container with that name already exists.

Clean up the test container:

```bash
docker stop conflict-test
docker rm conflict-test
```

## Practical 8: Build a Second Version

Change the heading in `app/index.html` and build a new image:

```bash
docker build -t week2-web:v2 .
```

Run the second version on a different port:

```bash
docker run -d --name week2-web-v2 -p 8082:80 week2-web:v2
```

Verify:

```bash
curl http://localhost:8082
docker images
docker ps
```

This demonstrates how different image versions can run in separate containers.

## Practical 9: Docker Registry

A Docker registry stores and distributes Docker images. Docker Hub is a popular public registry.

### Tag the image for Docker Hub

Replace `YOUR_DOCKERHUB_USERNAME` with your Docker Hub username:

```bash
docker login
docker tag week2-web:v1 YOUR_DOCKERHUB_USERNAME/week2-web:v1
docker push YOUR_DOCKERHUB_USERNAME/week2-web:v1
```

The destination repository must exist or be creatable under your account, and you need permission to push to it. Choose a private repository if the image should not be public.

## Interview Questions and Answers

### 1. What is Docker?

Docker is a platform for building, packaging, distributing, and running applications in containers. Containers package an application with its required files and dependencies so it can run consistently across compatible environments.

### 2. What is the difference between a Docker image and a container?

- **Image:** A template containing the application, files, and configuration needed to create a container.
- **Container:** A running or stopped instance created from an image.

One image can be used to create multiple containers.

### 3. What is Docker Engine?

Docker Engine is the container runtime system that manages images, containers, networks, and volumes. The Docker CLI communicates with the Engine through its API.

### 4. What is Docker CLI?

Docker CLI is the command-line interface used to interact with Docker.

Examples:

```bash
docker pull nginx:alpine
docker build -t my-web:v1 .
docker run -d -p 8080:80 nginx:alpine
docker ps
```

### 5. What is a Docker registry?

A Docker registry stores and distributes Docker images.

Examples include Docker Hub and private container registries. A registry is where images can be uploaded and downloaded; it is not where a running container executes.

### 6. What is the difference between `docker pull` and `docker run`?

- `docker pull` downloads an image from a registry.
- `docker run` creates and starts a container from an image. If the image is not available locally, Docker will generally attempt to pull it first.

### 7. What is the difference between `docker ps` and `docker ps -a`?

- `docker ps`: Shows running containers.
- `docker ps -a`: Shows all containers, including stopped and failed ones.

### 8. What does `-p 8080:80` mean?

It maps port 8080 on the host to port 80 inside the container.

```text
Browser
   |
   v
localhost:8080
   |
   v
Docker port mapping
   |
   v
Container port 80
   |
   v
Nginx
```

The first port is the host port; the second is the container port.

### 9. What is the difference between `docker stop` and `docker rm`?

- `docker stop`: Stops a running container but keeps it.
- `docker rm`: Removes a stopped container.

A container generally must be stopped before it can be removed, unless force removal is used.

### 10. What is a Dockerfile?

A Dockerfile is a text file containing instructions used to build a Docker image.

Common instructions include:

- `FROM`: Selects the base image.
- `COPY`: Copies files into the image.
- `RUN`: Executes commands during the build.
- `EXPOSE`: Documents a container port.
- `CMD`: Defines the default command when a container starts.

### 11. Why do we use `-d` in `docker run`?

`-d` runs the container in detached mode, allowing the terminal to return while the container continues running in the background.

### 12. Does `EXPOSE 80` publish port 80 to the host?

No. `EXPOSE` documents the port the application uses inside the container. To publish it, use a port mapping such as:

```bash
docker run -d -p 8080:80 nginx:alpine
```

### 13. Why can a Docker container fail to start?

Common reasons include:

- Host port already allocated.
- Container name already in use.
- Invalid image or configuration.
- Application process exits.
- Insufficient resources or permission problems.

Useful troubleshooting commands:

```bash
docker ps -a
docker logs CONTAINER_NAME
docker inspect CONTAINER_NAME
```

### 14. Can multiple containers use the same container port?

Yes. Multiple containers can listen on port 80 internally. However, they cannot normally publish the same host IP and host port combination at the same time.

For example:

```bash
docker run -d --name web1 -p 8081:80 nginx:alpine
docker run -d --name web2 -p 8082:80 nginx:alpine
```

Both containers use port 80 internally but are accessed through different host ports.

### 15. What happens when a container is deleted?

The container itself and its writable container layer are removed. Data stored only in that writable layer is lost. Images and separately managed volumes are not automatically removed by a normal container removal.

## Evidence Checklist

Save screenshots in the `evidence/` folder:

- [ ] Docker version and Engine information.
- [ ] Default Nginx page.
- [ ] `docker images`, `docker ps`, and `docker ps -a`.
- [ ] Custom HTML and Dockerfile.
- [ ] Successful image build.
- [ ] Custom web page served by the container.
- [ ] Port-conflict error and successful fix.
- [ ] Second image version running on port 8082.

## Cleanup

Stop and remove only the containers created for this lab:

```bash
docker stop week2-web week2-web-v2
docker rm week2-web week2-web-v2
```

The built images remain on your system. Remove them only if you no longer need them.

## Final Learning Summary

After this practical, you should be able to explain the Docker workflow:

1. Pull an image from a registry.
2. Create and run a container from the image.
3. Publish a container port to access its service.
4. Write a Dockerfile to customize an image.
5. Build, tag, inspect, and run your own image.
6. Troubleshoot port conflicts and container naming errors.
7. Explain Docker fundamentals in an interview.
