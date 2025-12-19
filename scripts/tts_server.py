#!/usr/bin/env python3
"""
Chatterbox TTS Server - Lightweight API for Claude Code integration
Keeps model loaded in memory for fast inference
"""

import os
import sys
import hashlib
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
import numpy as np
import scipy.io.wavfile as wav

# Lazy load to speed up startup
model = None
DEVICE = None

def get_device():
    if torch.backends.mps.is_available():
        return "mps"
    elif torch.cuda.is_available():
        return "cuda"
    return "cpu"

def load_model():
    global model, DEVICE
    if model is None:
        from chatterbox.tts_turbo import ChatterboxTurboTTS
        DEVICE = get_device()
        print(f"Loading Chatterbox-Turbo on {DEVICE}...")
        model = ChatterboxTurboTTS.from_pretrained(DEVICE)
        print("Model loaded!")
    return model

app = FastAPI(title="Chatterbox TTS", description="TTS API for Claude Code")

# Directories - use plugin root or fallback
PLUGIN_ROOT = Path(os.environ.get("CLAUDE_PLUGIN_ROOT", Path(__file__).parent.parent))
OUTPUT_DIR = Path(os.environ.get("CHATTERBOX_OUTPUT_DIR", Path.home() / ".chatterbox" / "output"))
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Default reference voice
DEFAULT_VOICE = Path(os.environ.get("CHATTERBOX_VOICE", PLUGIN_ROOT / "voices" / "default.wav"))

class TTSRequest(BaseModel):
    text: str
    voice_path: str | None = None
    temperature: float = 0.8
    play: bool = False

@app.on_event("startup")
async def startup():
    """Pre-load model on server start"""
    load_model()

@app.get("/health")
async def health():
    return {"status": "ok", "device": DEVICE, "model_loaded": model is not None}

@app.post("/speak")
async def speak(req: TTSRequest):
    """Generate speech from text"""
    try:
        m = load_model()
        voice_path = req.voice_path or str(DEFAULT_VOICE)

        audio = m.generate(
            req.text,
            audio_prompt_path=voice_path,
            temperature=req.temperature,
        )

        text_hash = hashlib.md5(req.text.encode()).hexdigest()[:8]
        output_path = OUTPUT_DIR / f"tts_{text_hash}.wav"

        # MPS requires float32
        audio_np = audio.squeeze(0).cpu().float().numpy().astype(np.float32)
        wav.write(str(output_path), m.sr, audio_np)

        if req.play:
            # macOS
            if sys.platform == "darwin":
                os.system(f"afplay {output_path} &")
            # Linux
            elif sys.platform == "linux":
                os.system(f"aplay {output_path} &")

        return {
            "status": "ok",
            "path": str(output_path),
            "duration_seconds": len(audio_np) / m.sr,
            "text": req.text[:50] + "..." if len(req.text) > 50 else req.text
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/speak/{text}")
async def speak_get(text: str, play: bool = True):
    """Simple GET endpoint - just pass text in URL"""
    return await speak(TTSRequest(text=text, play=play))

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("CHATTERBOX_PORT", 8877))
    print(f"Starting TTS server on http://localhost:{port}")
    print(f"Device: {get_device()}")
    print(f"Output dir: {OUTPUT_DIR}")
    print(f"Default voice: {DEFAULT_VOICE}")
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="warning")
