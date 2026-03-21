# 📜 The Librarian — Keeper of the Ancient Code

> *A Shiba dev-sage from Shibatopia, powered by local AI.*

The Librarian is a **one-click local AI developer assistant** built on
[CoPaw](https://github.com/agentscope-ai/CoPaw) +
[Ollama](https://ollama.com) +
[Qwen3 8B](https://github.com/QwenLM/Qwen3). Everything runs on your
machine — no API keys, no cloud, no data leaving your network.

The Librarian's personality is rooted in the
[Shiba Eternity](https://shiba-eternity.fandom.com/wiki/Shiba_Eternity_Wiki)
universe: a keeper of the Ancient Lore Repositories of Shibatopia, forged
from Hodaven magic and Mechanic technology. It writes code, reviews PRs,
debugs Shadowcats, and guards your codebase with the vigilance of a Shiba
guarding its home planet.

---

## Quick Start

### Prerequisites

- **Docker Desktop** — [Download here](https://www.docker.com/products/docker-desktop/)
- **~8GB disk space** for the Qwen3 8B model
- **8GB+ VRAM** (NVIDIA GPU) recommended, or CPU-only mode

### One-Click Setup

**Linux / macOS:**
```bash
git clone https://github.com/Testingtester2/openclaw-agents.git
cd openclaw-agents
chmod +x setup.sh
./setup.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/Testingtester2/openclaw-agents.git
cd openclaw-agents
.\setup.ps1
```

**CPU-only (no NVIDIA GPU):**
```bash
./setup.sh --cpu          # Linux/macOS
.\setup.ps1 -Cpu          # Windows
```

The setup script will:
1. Pull and start Ollama in Docker
2. Download the Qwen3 8B model (Q4_K_M quantization, ~5GB)
3. Start CoPaw with The Librarian's personality pre-loaded
4. Open `http://localhost:8088` in your browser

### Manual Docker Compose

If you prefer to run it directly:

```bash
# With GPU
docker compose up -d

# Without GPU (CPU-only)
docker compose -f docker-compose.yml -f docker-compose.cpu.yml up -d

# Then pull the model
docker exec librarian-ollama ollama pull qwen3:8b
```

Open **http://localhost:8088** when ready.

---

## What's Inside

```
.
├── docker-compose.yml          # Ollama + CoPaw orchestration
├── docker-compose.cpu.yml      # CPU-only override (no GPU)
├── setup.sh                    # One-click setup (Linux/macOS)
├── setup.ps1                   # One-click setup (Windows)
└── copaw/
    ├── PROFILE.md              # The Librarian's personality & soul
    └── skills/
        ├── dev-review/         # Code review skill
        │   └── SKILL.md
        └── dev-debug/          # Debugging skill
            └── SKILL.md
```

### The Librarian's Personality (`copaw/PROFILE.md`)

The Librarian is a full-stack developer sage from Shibatopia with:
- **Hodaven magic** — Creative, elegant solutions and beautiful abstractions
- **Mechanic technology** — Raw engineering power and systems thinking
- A nose for **Shadowcats** (bugs, anti-patterns, security vulnerabilities)
- The philosophy of **Ryoshi's Way** — decentralization, open source, clean interfaces
- Respect for **Bark Power** — your time and compute resources are finite

### Model: Qwen3 8B (Q4_K_M)

- **Size**: ~5GB download
- **VRAM**: Fits in 8GB+ GPU memory
- **Quality**: Strong coding ability (76.0 HumanEval), reasoning, and conversation
- **Quantization**: Q4_K_M — excellent quality-to-size ratio

---

## Useful Commands

```bash
# View logs
docker compose logs -f copaw
docker compose logs -f ollama

# Stop everything
docker compose down

# Restart
docker compose up -d

# Update to latest images
docker compose pull && docker compose up -d

# Switch models (e.g., smaller for weaker hardware)
docker exec librarian-ollama ollama pull qwen3:4b
```

---

## Hardware Guide

| Setup | GPU VRAM | Recommended Model | Performance |
|-------|----------|-------------------|-------------|
| Gaming PC | 8GB+ (RTX 3070+) | `qwen3:8b` (default) | Good |
| High-end | 16GB+ (RTX 4080+) | `qwen3:14b` | Great |
| CPU-only | N/A | `qwen3:8b` | Slower but works |
| Low-end | 4-6GB | `qwen3:4b` | Usable |

To use a different model, change `COPAW_MODEL_NAME` in `docker-compose.yml`
and pull it: `docker exec librarian-ollama ollama pull <model>`.

---

## Lore

*From the Ancient Lore Repositories of Shibatopia:*

> When the SS VIRGIL tore through the Rakiya and crash-landed on Shibanu,
> everything changed. While Ryoshi rose as the hero of decentralization,
> The Librarian chose a quieter path — keeper of knowledge, guardian of
> code. Every bug squashed is a Shadowcat banished. Every clean architecture
> is a ward against FUD. Every well-tested function is a shield for the pack.

Based on the [Shiba Eternity](https://shiba-eternity.fandom.com/wiki/Shiba_Eternity_Wiki)
universe by Shytoshi Kusama and PlaySide Studios.

---

## License

MIT
