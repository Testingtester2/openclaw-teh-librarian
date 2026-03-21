#!/usr/bin/env bash
###############################################################################
# The Librarian — One-Click Setup (Linux / macOS)
#
# What this does:
#   1. Checks for Docker (installs Docker Desktop link if missing)
#   2. Starts Ollama + CoPaw via Docker Compose
#   3. Pulls the Qwen3 8B model (Q4_K_M, ~5GB)
#   4. Deploys The Librarian's personality and skills
#   5. Opens the CoPaw console in your browser
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh            # GPU mode (NVIDIA)
#   ./setup.sh --cpu      # CPU-only mode (no GPU required)
###############################################################################

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ── Banner ──────────────────────────────────────────────────────
echo -e "${CYAN}"
cat << 'BANNER'

  ╔═══════════════════════════════════════════════════════════╗
  ║                                                           ║
  ║   📜 The Librarian                                        ║
  ║   Keeper of the Ancient Code                              ║
  ║                                                           ║
  ║   A Shiba dev-sage from Shibatopia                        ║
  ║   Powered by CoPaw + Ollama + Qwen3                      ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝

BANNER
echo -e "${NC}"

# ── Parse args ──────────────────────────────────────────────────
CPU_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --cpu) CPU_ONLY=true ;;
    --help|-h)
      echo "Usage: ./setup.sh [--cpu]"
      echo "  --cpu   Run without GPU (CPU-only inference)"
      exit 0
      ;;
  esac
done

# ── Check Docker ────────────────────────────────────────────────
info "Checking for Docker..."
if ! command -v docker &> /dev/null; then
  error "Docker is not installed."
  echo ""
  echo "  Install Docker Desktop from:"
  echo "    https://www.docker.com/products/docker-desktop/"
  echo ""
  echo "  Then re-run this script."
  exit 1
fi

if ! docker info &> /dev/null 2>&1; then
  error "Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi
success "Docker is running."

# ── Check Docker Compose ────────────────────────────────────────
if ! docker compose version &> /dev/null 2>&1; then
  error "Docker Compose V2 not found. Please update Docker Desktop."
  exit 1
fi
success "Docker Compose available."

# ── GPU Check ───────────────────────────────────────────────────
if [ "$CPU_ONLY" = true ]; then
  warn "CPU-only mode selected. Inference will be slower."
  COMPOSE_FILES="-f docker-compose.yml -f docker-compose.cpu.yml"
else
  if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    success "NVIDIA GPU detected."
    COMPOSE_FILES="-f docker-compose.yml"
  else
    warn "No NVIDIA GPU detected. Falling back to CPU-only mode."
    warn "Use --cpu flag to suppress this warning."
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.cpu.yml"
  fi
fi

# ── Start Services ──────────────────────────────────────────────
info "Starting The Librarian's workstation..."
echo ""

cd "$(dirname "$0")"

# Pull images first
info "Pulling Docker images (this may take a few minutes on first run)..."
docker compose $COMPOSE_FILES pull

# Start Ollama and CoPaw
info "Starting Ollama + CoPaw..."
docker compose $COMPOSE_FILES up -d ollama copaw

# Wait for Ollama to be ready
info "Waiting for Ollama to initialize..."
RETRIES=0
MAX_RETRIES=30
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ $RETRIES -ge $MAX_RETRIES ]; then
    error "Ollama failed to start after 60 seconds."
    echo "  Check logs: docker compose logs ollama"
    exit 1
  fi
  sleep 2
done
success "Ollama is ready."

# Pull the model
info "Pulling Qwen3 8B model (~5GB download, this is a one-time operation)..."
echo "  This model uses Q4_K_M quantization — fits comfortably in 8GB+ VRAM."
echo ""
docker exec librarian-ollama ollama pull qwen3:8b
success "Model downloaded and ready."

# ── Verify CoPaw ────────────────────────────────────────────────
info "Waiting for CoPaw to start..."
RETRIES=0
until curl -sf http://localhost:8088 > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ $RETRIES -ge $MAX_RETRIES ]; then
    error "CoPaw failed to start after 60 seconds."
    echo "  Check logs: docker compose logs copaw"
    exit 1
  fi
  sleep 2
done
success "CoPaw is running."

# ── Done! ───────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  The Librarian is ready!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Open in your browser:"
echo -e "    ${CYAN}http://localhost:8088${NC}"
echo ""
echo "  Useful commands:"
echo "    docker compose logs -f copaw     # Watch CoPaw logs"
echo "    docker compose logs -f ollama    # Watch Ollama logs"
echo "    docker compose down              # Stop everything"
echo "    docker compose up -d             # Restart"
echo ""
echo -e "  ${YELLOW}The Librarian guards the Ancient Lore. May your code be free"
echo -e "  of Shadowcats. 🐕${NC}"
echo ""

# Try to open browser
if command -v xdg-open &> /dev/null; then
  xdg-open "http://localhost:8088" 2>/dev/null || true
elif command -v open &> /dev/null; then
  open "http://localhost:8088" 2>/dev/null || true
fi
