# Dockerized Go App

Simple Go HTTP app that returns a greeting. This repository contains the Go source, a Dockerfile, and instructions to build, run, and push the image to Docker Hub.

## What is included

- `main.go` — minimal HTTP server listening on port 8080
- `go.mod` — module file
- `Dockerfile` — multi-stage build (build in `golang:1.20-alpine`, produce minimal final image)

## Quick local build & run (PowerShell)

1. Build the Go binary (optional — Docker will also build it):

```powershell
cd "C:\Users\Msi\Desktop\task 2"
go build -o dockerized-app .
# or simply: go run main.go
```

2. Build the Docker image (replace `yourusername`):

```powershell
docker build -t yourusername/dockerized-go-app:latest .
```

3. Run the container locally:

```powershell
docker run --rm -p 8080:8080 yourusername/dockerized-go-app:latest
```

4. Test from another PowerShell window or browser:

```powershell
curl http://localhost:8080/
# expected output: Hello from Dockerized Go app!
```

## Publish to Docker Hub

1. Create a repository on Docker Hub named `dockerized-go-app` under your Docker Hub username (https://hub.docker.com/).

2. Tag and push the image:

```powershell
# login
docker login

# tag if needed (image already tagged in build step above works)
docker tag yourusername/dockerized-go-app:latest yourusername/dockerized-go-app:latest

docker push yourusername/dockerized-go-app:latest
```

3. After push, the public URL will be: `https://hub.docker.com/r/yourusername/dockerized-go-app`

Replace `yourusername` with your Docker Hub username and update the link below.

Docker Hub image link (replace with your actual image link):

https://hub.docker.com/r/yourusername/dockerized-go-app

## Push project to GitHub

1. Initialize git and push to GitHub (create repo on GitHub first):

```powershell
cd "C:\Users\Msi\Desktop\task 2"
git init
git add .
git commit -m "Add Dockerized Go app"
# create repo on GitHub via website or gh CLI, then add remote and push
# example using gh CLI:
# gh repo create yourusername/dockerized-go-app --public --source=. --push

# or using remote url:
# git remote add origin https://github.com/yourusername/dockerized-go-app.git
# git branch -M main
git push -u origin main
```

## Submission

- Push the code to GitHub and ensure your `README.md` contains the Docker Hub link.
- Submit the GitHub repository URL for the assignment.

## Notes

- If you want to use a smaller base image than `scratch` for easier debugging, change final image to `alpine` and copy necessary files.
- If your app needs environment variables, set them with `docker run -e NAME=value ...`.
