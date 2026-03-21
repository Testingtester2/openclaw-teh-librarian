###############################################################################
# The Librarian - One-Click Setup (Windows PowerShell)
#
# What this does:
#   1. Checks for Docker Desktop (links to install if missing)
#   2. Starts Ollama + OpenClaw Gateway via Docker Compose
#   3. Pulls the Qwen3 8B model (Q4_K_M, ~5GB)
#   4. Builds the sandbox image for isolated agent execution
#   5. Deploys The Librarian's personality (SOUL.md) and skills
#   6. Opens the OpenClaw dashboard in your browser
#
# Usage (run in PowerShell):
#   .\setup.ps1            # GPU mode (NVIDIA)
#   .\setup.ps1 -Cpu       # CPU-only mode
###############################################################################

param(
    [switch]$Cpu,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# -- Banner -------------------------------------------------------------------
Write-Host ""
Write-Host "  +========================================================+" -ForegroundColor Cyan
Write-Host "  |                                                        |" -ForegroundColor Cyan
Write-Host "  |   The Librarian                                        |" -ForegroundColor Cyan
Write-Host "  |   Keeper of the Ancient Code                           |" -ForegroundColor Cyan
Write-Host "  |                                                        |" -ForegroundColor Cyan
Write-Host "  |   A Shiba dev-sage from Shibatopia                     |" -ForegroundColor Cyan
Write-Host "  |   Powered by OpenClaw + Ollama + Qwen3                 |" -ForegroundColor Cyan
Write-Host "  |                                                        |" -ForegroundColor Cyan
Write-Host "  +========================================================+" -ForegroundColor Cyan
Write-Host ""

if ($Help) {
    Write-Host "Usage: .\setup.ps1 [-Cpu]"
    Write-Host "  -Cpu    Run without GPU (CPU-only inference)"
    exit 0
}

function Write-Info($msg)    { Write-Host "[INFO]  $msg" -ForegroundColor Blue }
function Write-Ok($msg)      { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err($msg)     { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# -- Check Docker -------------------------------------------------------------
Write-Info "Checking for Docker..."

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Err "Docker is not installed."
    Write-Host ""
    Write-Host "  Install Docker Desktop from:"
    Write-Host "    https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  After installing, restart this script."
    exit 1
}

try {
    docker info 2>$null | Out-Null
} catch {
    Write-Err "Docker is not running. Please start Docker Desktop and try again."
    exit 1
}
Write-Ok "Docker is running."

# -- Check Docker Compose -----------------------------------------------------
try {
    docker compose version 2>$null | Out-Null
} catch {
    Write-Err "Docker Compose V2 not found. Please update Docker Desktop."
    exit 1
}
Write-Ok "Docker Compose available."

# -- GPU Check ----------------------------------------------------------------
$composeFiles = @("-f", "docker-compose.yml")

if ($Cpu) {
    Write-Warn "CPU-only mode selected. Inference will be slower."
    $composeFiles += @("-f", "docker-compose.cpu.yml")
} else {
    $hasGpu = $false
    try {
        $nvsmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvsmi) {
            nvidia-smi 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $hasGpu = $true }
        }
    } catch {}

    if ($hasGpu) {
        Write-Ok "NVIDIA GPU detected."
    } else {
        Write-Warn "No NVIDIA GPU detected. Using CPU-only mode."
        $composeFiles += @("-f", "docker-compose.cpu.yml")
    }
}

# -- Start Services -----------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Info "Pulling Docker images (first run may take a few minutes)..."
& docker compose @composeFiles pull
if ($LASTEXITCODE -ne 0) { Write-Err "Failed to pull images."; exit 1 }

Write-Info "Starting Ollama + OpenClaw Gateway..."
& docker compose @composeFiles up -d ollama openclaw-gateway
if ($LASTEXITCODE -ne 0) { Write-Err "Failed to start services."; exit 1 }

# Wait for Ollama
Write-Info "Waiting for Ollama to initialize..."
$retries = 0
$maxRetries = 30
do {
    Start-Sleep -Seconds 2
    $retries++
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) { break }
    } catch {}
    if ($retries -ge $maxRetries) {
        Write-Err "Ollama failed to start after 60 seconds."
        Write-Host "  Check logs: docker compose logs ollama"
        exit 1
    }
} while ($true)
Write-Ok "Ollama is ready."

# Pull model
Write-Info "Pulling Qwen3 8B model (~5GB download, one-time operation)..."
Write-Host "  This model uses Q4_K_M quantization - fits in 8GB+ VRAM."
Write-Host ""
& docker exec librarian-ollama ollama pull qwen3:8b
if ($LASTEXITCODE -ne 0) { Write-Err "Failed to pull model."; exit 1 }
Write-Ok "Model downloaded and ready."

# -- Build Sandbox Image ------------------------------------------------------
Write-Info "Building sandbox image for agent isolation..."
$sandboxExists = docker image inspect openclaw-sandbox:bookworm-slim 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Ok "Sandbox image already exists."
} else {
    $dockerfile = @"
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl jq git ca-certificates && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash sandbox
USER sandbox
WORKDIR /home/sandbox
"@
    $dockerfile | docker build -t openclaw-sandbox:bookworm-slim -f - .
    if ($LASTEXITCODE -ne 0) { Write-Err "Failed to build sandbox image."; exit 1 }
    Write-Ok "Sandbox image built."
}

# Wait for OpenClaw Gateway
Write-Info "Waiting for OpenClaw Gateway to start..."
$retries = 0
do {
    Start-Sleep -Seconds 2
    $retries++
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:18789/healthz" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) { break }
    } catch {}
    if ($retries -ge $maxRetries) {
        Write-Err "OpenClaw Gateway failed to start after 60 seconds."
        Write-Host "  Check logs: docker compose logs openclaw-gateway"
        exit 1
    }
} while ($true)
Write-Ok "OpenClaw Gateway is running."

# -- Done! --------------------------------------------------------------------
Write-Host ""
Write-Host "  ========================================================" -ForegroundColor Green
Write-Host "    The Librarian is ready!" -ForegroundColor Green
Write-Host "  ========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Open in your browser:"
Write-Host "    http://localhost:18789" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Useful commands:"
Write-Host "    docker compose logs -f openclaw-gateway   # Watch OpenClaw logs"
Write-Host "    docker compose logs -f ollama             # Watch Ollama logs"
Write-Host "    docker compose down                       # Stop everything"
Write-Host "    docker compose up -d                      # Restart"
Write-Host ""
Write-Host "  Sandboxing:" -ForegroundColor Yellow
Write-Host "    Agent tool execution runs inside isolated Docker containers."
Write-Host "    Sandbox containers have no network access by default."
Write-Host "    Edit openclaw/config.json5 to adjust sandbox settings."
Write-Host ""
Write-Host "  The Librarian guards the Ancient Lore. May your code be" -ForegroundColor Yellow
Write-Host "  free of Shadowcats." -ForegroundColor Yellow
Write-Host ""

# Open browser
Start-Process "http://localhost:18789"
