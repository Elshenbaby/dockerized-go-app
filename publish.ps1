<#
publish.ps1
Automates: go build, docker build, docker run/test, docker push, git commit, create GitHub repo and push.
Requires: Go, Docker, Git. Optional: GitHub CLI (`gh`) for automatic repo creation.
Run: Open PowerShell as Administrator (or normal if you have permissions), cd to project folder and run:
    .\publish.ps1
#>

function Abort([string]$msg){
    Write-Host "ERROR: $msg" -ForegroundColor Red
    exit 1
}

Write-Host "Starting publish automation..." -ForegroundColor Cyan

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $projectDir

# 1) Check required tools
$hasGo = (Get-Command go -ErrorAction SilentlyContinue) -ne $null
$hasDocker = (Get-Command docker -ErrorAction SilentlyContinue) -ne $null
$hasGit = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
$hasGh = (Get-Command gh -ErrorAction SilentlyContinue) -ne $null

Write-Host "Tool check:" -ForegroundColor Yellow
Write-Host "  go:      " -NoNewline; if ($hasGo){ go version } else { Write-Host "missing" -ForegroundColor Red }
Write-Host "  docker:  " -NoNewline; if ($hasDocker){ docker --version } else { Write-Host "missing" -ForegroundColor Red }
Write-Host "  git:     " -NoNewline; if ($hasGit){ git --version } else { Write-Host "missing" -ForegroundColor Red }
Write-Host "  gh:      " -NoNewline; if ($hasGh){ gh --version } else { Write-Host "not installed (optional)" -ForegroundColor DarkYellow }

if (-not $hasGit){ Abort "git is required. Install Git for Windows: https://git-scm.com/download/win" }
if (-not $hasGo){ Write-Host "Warning: go not found. The Docker build will still compile inside the container if Docker is available." -ForegroundColor DarkYellow }
if (-not $hasDocker){ Abort "docker is required to build and push images. Install Docker Desktop: https://www.docker.com/products/docker-desktop" }

# 2) Build Go binary locally (optional)
if ($hasGo){
    Write-Host "Building Go binary locally..." -ForegroundColor Cyan
    & go build -o dockerized-app .
    if ($LASTEXITCODE -ne 0){ Write-Host "go build failed, continuing since Docker will build it inside the container." -ForegroundColor Yellow }
    else { Write-Host "Go build succeeded." -ForegroundColor Green }
}

# 3) Ask Docker Hub username and image name
$dockerUser = Read-Host "Enter your Docker Hub username (will be used to tag the image)"
if ([string]::IsNullOrWhiteSpace($dockerUser)){ Abort "Docker Hub username is required." }

$defaultImage = "$dockerUser/dockerized-go-app:latest"
$imageFull = Read-Host "Image name and tag to build (default: $defaultImage)"
if ([string]::IsNullOrWhiteSpace($imageFull)){ $imageFull = $defaultImage }

# 4) Build Docker image
Write-Host "Building Docker image: $imageFull" -ForegroundColor Cyan
docker build -t $imageFull .
if ($LASTEXITCODE -ne 0){ Abort "Docker build failed." }
Write-Host "Docker build succeeded." -ForegroundColor Green

# 5) Run the image briefly to test
$testRun = Read-Host "Run container locally to test? (y/N)"
if ($testRun -match '^[Yy]'){
    Write-Host "Running container and testing endpoint..." -ForegroundColor Cyan
    $containerName = "dockerized-go-test"
    docker rm -f $containerName | Out-Null 2>&1
    docker run -d --name $containerName -p 8080:8080 $imageFull | Out-Null
    Start-Sleep -Seconds 2
    try {
        $resp = curl -UseBasicParsing http://localhost:8080/ -TimeoutSec 5
        Write-Host "Response from http://localhost:8080/:" -ForegroundColor Green
        Write-Host $resp.Content
    } catch {
        Write-Host "Failed to curl the container: $_" -ForegroundColor Red
    }
    Write-Host "Stopping and removing test container..." -ForegroundColor Cyan
    docker rm -f $containerName | Out-Null
}

# 6) Push to Docker Hub
Write-Host "About to push image to Docker Hub: $imageFull" -ForegroundColor Cyan
Write-Host "You will be prompted to login if not already authenticated."
docker login
if ($LASTEXITCODE -ne 0){ Abort "Docker login failed or was cancelled." }

docker push $imageFull
if ($LASTEXITCODE -ne 0){ Abort "Docker push failed." }
Write-Host "Docker image pushed: https://hub.docker.com/r/$dockerUser/" -ForegroundColor Green

# 7) Create GitHub repo and push code
$repoName = Read-Host "Enter GitHub repo name to create (default: dockerized-go-app)"
if ([string]::IsNullOrWhiteSpace($repoName)){ $repoName = "dockerized-go-app" }

if ($hasGh){
    Write-Host "Creating GitHub repo using gh..." -ForegroundColor Cyan
    gh repo create $dockerUser/$repoName --public --source=. --push --confirm
    if ($LASTEXITCODE -ne 0){ Write-Host "gh repo create failed, will try manual git remote push." -ForegroundColor Yellow }
} 

# Fallback/manual push
if ((Get-Command gh -ErrorAction SilentlyContinue) -eq $null -or $LASTEXITCODE -ne 0){
    Write-Host "Creating local git repo and pushing to https://github.com/$dockerUser/$repoName.git" -ForegroundColor Cyan
    if (-not (Test-Path ".git")){
        git init
        git add .
        git commit -m "Add Dockerized Go app"
    } else {
        git add .
        git commit -m "Update Dockerized Go app" -ErrorAction SilentlyContinue
    }
    $remoteUrl = "https://github.com/$dockerUser/$repoName.git"
    git remote remove origin 2>$null
    git remote add origin $remoteUrl
    git branch -M main
    Write-Host "Pushing to $remoteUrl (you may be prompted for credentials)..." -ForegroundColor Yellow
    git push -u origin main
    if ($LASTEXITCODE -ne 0){ Abort "git push failed. Make sure the repo exists or create it on github.com and try again." }
}

# 8) Update README with Docker Hub link
$readme = Join-Path $projectDir 'README.md'
if (Test-Path $readme){
    (Get-Content $readme) -replace 'https://hub.docker.com/r/yourusername/dockerized-go-app', "https://hub.docker.com/r/$dockerUser/$(($imageFull -split '/')[1] -split ':')[0]" | Set-Content $readme
    git add $readme
    git commit -m "Update README with Docker Hub link" -ErrorAction SilentlyContinue
    git push origin main 2>$null | Out-Null
}

Write-Host "Done. Your Docker image is at: https://hub.docker.com/r/$dockerUser/$(($imageFull -split '/')[1] -split ':')[0]" -ForegroundColor Green
Write-Host "Your GitHub repo is at: https://github.com/$dockerUser/$repoName" -ForegroundColor Green
Write-Host "If anything failed above, paste the error output here and I'll help fix it." -ForegroundColor Cyan
