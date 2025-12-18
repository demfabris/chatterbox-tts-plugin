---
description: Set up Chatterbox TTS (install dependencies, configure voice)
allowed-tools:
  - Bash
  - Read
  - Write
---

# /tts-setup Command

Install and configure Chatterbox TTS for Claude Code.

## Instructions

### Step 1: Check Prerequisites

Verify the user has:
- Python 3.10+ installed
- macOS (for MPS) or Linux (for CPU/CUDA)
- ~2GB disk space for model and dependencies

### Step 2: Run Setup Script

Execute the setup script:

```bash
chmod +x $CLAUDE_PLUGIN_ROOT/scripts/setup.sh
$CLAUDE_PLUGIN_ROOT/scripts/setup.sh
```

This will:
1. Create virtual environment at `~/.chatterbox/venv`
2. Install PyTorch with MPS support
3. Clone and patch Chatterbox for MPS compatibility
4. Install all dependencies

### Step 3: Start TTS Server

After setup completes, start the server:

```bash
source ~/.chatterbox/venv/bin/activate
python $CLAUDE_PLUGIN_ROOT/scripts/tts_server.py &
```

### Step 4: Verify Installation

Test the server:

```bash
curl http://localhost:8877/health
```

Expected response: `{"status":"ok","device":"mps","model_loaded":true}`

### Step 5: Test TTS

Generate test audio:

```bash
$CLAUDE_PLUGIN_ROOT/scripts/speak.sh "Hello! TTS setup is complete."
```

## Custom Voice

To use a custom voice, replace the default voice file:

```bash
cp /path/to/your/voice.wav $CLAUDE_PLUGIN_ROOT/voices/default.wav
```

Requirements for voice file:
- WAV format, mono
- At least 5 seconds of clear speech
- 16kHz-48kHz sample rate
- Clean audio without background noise

## Troubleshooting

### MPS Not Available
If running on Intel Mac or older macOS, the server falls back to CPU (slower but works).

### Model Download Fails
The model downloads from HuggingFace on first use (~500MB). Ensure internet connection.

### Float64 Error
The setup script patches the model for MPS. If you see float64 errors, re-run setup.

## Environment Variables

- `CHATTERBOX_PORT` - Server port (default: 8877)
- `CHATTERBOX_VENV` - Virtual environment path (default: ~/.chatterbox/venv)
- `CHATTERBOX_VOICE` - Custom voice file path
- `CHATTERBOX_OUTPUT_DIR` - Output directory for generated audio
