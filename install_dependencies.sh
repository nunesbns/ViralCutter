#!/usr/bin/env bash
set -e

# ==========================================
# ViralCutter - Instalador para Linux
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; }

MISSING=()

echo ""
echo "=========================================="
echo " ViralCutter - Verificando dependências"
echo "=========================================="
echo ""

# --- Python ---
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [[ "$PY_MAJOR" -eq 3 && "$PY_MINOR" -ge 10 && "$PY_MINOR" -le 11 ]]; then
        ok "Python $PY_VER"
    else
        warn "Python $PY_VER encontrado (recomendado: 3.10 ou 3.11). Pode funcionar, mas não é garantido."
    fi
else
    fail "Python 3 não encontrado"
    MISSING+=("python3")
fi

# --- pip / venv ---
if python3 -c "import venv" &>/dev/null; then
    ok "python3-venv"
else
    fail "python3-venv não encontrado"
    MISSING+=("python3-venv")
fi

# --- FFmpeg ---
if command -v ffmpeg &>/dev/null; then
    ok "ffmpeg $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
else
    fail "ffmpeg não encontrado"
    MISSING+=("ffmpeg")
fi

# --- Build tools (gcc/g++) ---
if command -v g++ &>/dev/null; then
    ok "g++ (build-essential)"
else
    fail "g++ não encontrado (necessário para compilar insightface)"
    MISSING+=("build-essential")
fi

# --- Git (para algumas dependências pip) ---
if command -v git &>/dev/null; then
    ok "git"
else
    fail "git não encontrado"
    MISSING+=("git")
fi

echo ""

# --- Se faltam dependências, mostra como instalar ---
if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${RED}Dependências faltando: ${MISSING[*]}${NC}"
    echo ""

    if command -v apt &>/dev/null; then
        echo "Instale com:"
        echo -e "  ${YELLOW}sudo apt update && sudo apt install -y ${MISSING[*]}${NC}"
    elif command -v dnf &>/dev/null; then
        echo "Instale com:"
        echo -e "  ${YELLOW}sudo dnf install -y ${MISSING[*]}${NC}"
    elif command -v pacman &>/dev/null; then
        echo "Instale com:"
        echo -e "  ${YELLOW}sudo pacman -S ${MISSING[*]}${NC}"
    else
        echo "Instale os pacotes acima usando o gerenciador de pacotes da sua distro."
    fi

    echo ""
    read -rp "Deseja continuar mesmo assim? (s/N): " choice
    [[ "$choice" =~ ^[sS]$ ]] || exit 1
fi

# --- GPU ---
echo "=========================================="
echo " Configuração de Placa de Vídeo"
echo "=========================================="
echo ""
echo " [1] NVIDIA (CUDA - Mais rápido)"
echo " [2] AMD / Nenhuma / Não sei (CPU)"
echo ""
read -rp "Escolha (1/2): " gpu_choice
echo ""

# --- Modo de instalação ---
echo "=========================================="
echo " Modo de Instalação"
echo "=========================================="
echo ""
echo " [1] Padrão (IAs em nuvem: Gemini, GPT-4)"
echo " [2] Avançado (Inclui LLMs locais via llama-cpp-python)"
echo ""
read -rp "Escolha (1/2): " install_mode
echo ""

# --- Criar venv ---
echo "=========================================="
echo " Criando ambiente virtual (.venv)..."
echo "=========================================="
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

# --- requirements.txt (primeiro, para não sobrescrever PyTorch depois) ---
echo ""
echo "=========================================="
echo " Instalando dependências do requirements.txt..."
echo "=========================================="
pip install -r requirements.txt

# --- PyTorch + ONNX (garante o index correto: CUDA ou CPU) ---
echo ""
echo "=========================================="
echo " Instalando PyTorch e ONNX..."
echo "=========================================="
if [[ "$gpu_choice" == "1" ]]; then
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu124
    pip install onnxruntime-gpu==1.20.1
else
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu
    pip install onnxruntime==1.20.1
fi

# --- LLM local (modo avançado) ---
if [[ "$install_mode" == "2" ]]; then
    echo ""
    echo "=========================================="
    echo " Instalando llama-cpp-python..."
    echo "=========================================="
    if [[ "$gpu_choice" == "1" ]]; then
        pip install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu124
    else
        pip install llama-cpp-python
    fi
fi

echo ""
echo -e "${GREEN}=========================================="
echo " Instalação concluída!"
echo "==========================================${NC}"
echo ""
echo "Para rodar:"
echo "  source .venv/bin/activate"
echo "  python webui/app.py        # Interface Web"
echo "  python main_improved.py    # CLI"
echo ""
