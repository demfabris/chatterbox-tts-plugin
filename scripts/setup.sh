#!/bin/bash
# Chatterbox TTS Setup Script
# Installs dependencies and patches for MPS compatibility

set -e

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
VENV_DIR="${CHATTERBOX_VENV:-$HOME/.chatterbox/venv}"
REPO_DIR="${CHATTERBOX_REPO:-$HOME/.chatterbox/chatterbox-repo}"

echo "=== Chatterbox TTS Setup ==="
echo "Plugin root: $PLUGIN_ROOT"
echo "Virtual env: $VENV_DIR"
echo "Repo dir: $REPO_DIR"
echo ""

# Check Python version
PYTHON_CMD=""
for cmd in python3.13 python3.12 python3.11 python3; do
    if command -v $cmd &> /dev/null; then
        version=$($cmd -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        major=$(echo $version | cut -d. -f1)
        minor=$(echo $version | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
            PYTHON_CMD=$cmd
            echo "Found Python $version at $(which $cmd)"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "ERROR: Python 3.10+ required but not found"
    exit 1
fi

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo ""
    echo "Creating virtual environment..."
    $PYTHON_CMD -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"
pip install --upgrade pip -q

# Install PyTorch with MPS support
echo ""
echo "Installing PyTorch..."
pip install torch torchvision torchaudio -q

# Clone and patch chatterbox repo
if [ ! -d "$REPO_DIR" ]; then
    echo ""
    echo "Cloning Chatterbox repository..."
    git clone https://github.com/resemble-ai/chatterbox.git "$REPO_DIR"
fi

# Apply MPS patches
echo ""
echo "Applying MPS compatibility patches..."

# Patch pyproject.toml - relax version constraints
cat > "$REPO_DIR/pyproject.toml" << 'PYPROJECT'
[project]
name = "chatterbox-tts"
version = "0.1.6"
description = "Chatterbox: Open Source TTS and Voice Conversion by Resemble AI"
readme = "README.md"
requires-python = ">=3.10"
license = {file = "LICENSE"}
authors = [
    {name = "resemble-ai", email = "engineering@resemble.ai"}
]
dependencies = [
    "numpy>=1.24.0",
    "librosa>=0.10.0",
    "s3tokenizer",
    "torch>=2.6.0",
    "torchaudio>=2.6.0",
    "transformers>=4.46.0",
    "diffusers>=0.29.0",
    "resemble-perth>=1.0.1",
    "conformer>=0.3.2",
    "safetensors>=0.5.3",
    "spacy-pkuseg",
    "pykakasi>=2.3.0",
    "gradio>=5.0.0",
    "pyloudnorm",
    "omegaconf"
]

[project.urls]
Homepage = "https://github.com/resemble-ai/chatterbox"
Repository = "https://github.com/resemble-ai/chatterbox"

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]
PYPROJECT

# Patch tts_turbo.py for MPS float32 compatibility
TTS_FILE="$REPO_DIR/src/chatterbox/tts_turbo.py"
if [ -f "$TTS_FILE" ]; then
    # Add numpy import if missing
    if ! grep -q "import numpy as np" "$TTS_FILE"; then
        sed -i.bak 's/import librosa/import numpy as np\nimport librosa/' "$TTS_FILE"
    fi

    # Patch token requirement
    sed -i.bak 's/token=os.getenv("HF_TOKEN") or True/token=os.getenv("HF_TOKEN") or None/' "$TTS_FILE"

    # Patch float64 to float32 for MPS
    if ! grep -q "astype(np.float32)" "$TTS_FILE"; then
        sed -i.bak 's/s3gen_ref_wav, _sr = librosa.load(wav_fpath, sr=S3GEN_SR)/s3gen_ref_wav, _sr = librosa.load(wav_fpath, sr=S3GEN_SR)\n        s3gen_ref_wav = s3gen_ref_wav.astype(np.float32)/' "$TTS_FILE"
    fi

    rm -f "$TTS_FILE.bak"
fi

# Patch s3tokenizer.py for MPS float32 compatibility
S3TOK_FILE="$REPO_DIR/src/chatterbox/models/s3tokenizer/s3tokenizer.py"
if [ -f "$S3TOK_FILE" ]; then
    # Convert to float32 before moving to device
    sed -i.bak 's/wav = wav.to(self.device)/wav = wav.float().to(self.device)  # MPS requires float32/' "$S3TOK_FILE"
    rm -f "$S3TOK_FILE.bak"
fi

# Patch voice_encoder.py for MPS float32 compatibility
VE_FILE="$REPO_DIR/src/chatterbox/models/voice_encoder/voice_encoder.py"
if [ -f "$VE_FILE" ]; then
    # Convert to float32 before moving to device
    sed -i.bak 's/mels.to(self.device)/mels.float().to(self.device)  # MPS requires float32/' "$VE_FILE"
    rm -f "$VE_FILE.bak"
fi

# Install chatterbox from patched source
echo ""
echo "Installing Chatterbox (this may take a few minutes)..."
pip install -e "$REPO_DIR" -q

# Install FastAPI dependencies
pip install fastapi uvicorn -q

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To start the TTS server manually:"
echo "  source $VENV_DIR/bin/activate"
echo "  python $PLUGIN_ROOT/scripts/tts_server.py"
echo ""
echo "The server will auto-start with Claude Code sessions."
