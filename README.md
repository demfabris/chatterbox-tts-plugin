# Chatterbox TTS Plugin for Claude Code

Zero-shot voice cloning text-to-speech for Claude Code, powered by [Resemble AI's Chatterbox](https://github.com/resemble-ai/chatterbox).

## Features

- **Voice Cloning**: Clone any voice from a 5-15 second reference audio
- **MPS Acceleration**: Native Apple Silicon GPU support (3-4x faster than CPU)
- **Notification Speech**: Auto-speaks Claude's notifications
- **On-Demand TTS**: `/speak` command for instant text-to-speech
- **Paralinguistic Tags**: Natural `[laugh]`, `[sigh]`, `[cough]` expressions

## Quick Start

1. Install the plugin in Claude Code
2. **Run `/tts-setup`** to install dependencies (~500MB model download, takes 3-5 min)
3. Use `/speak "Hello world!"` to test
4. Check `/tts-status` if you have issues

After setup, the TTS server auto-starts with each Claude Code session. Notifications are spoken automatically.

## Requirements

- macOS with Apple Silicon (M1/M2/M3) or Linux with CUDA
- Python 3.10+
- ~2GB disk space

## Commands

| Command | Description |
|---------|-------------|
| `/tts-setup` | **Run first!** Install dependencies and configure |
| `/tts-status` | Check installation and server health |
| `/speak "text"` | Generate and play speech |

## Voice Customization

Replace the default voice with your own:

```bash
cp your-voice.wav ~/.claude/plugins/chatterbox-tts/voices/default.wav
```

Voice requirements:
- WAV format, mono channel
- 5-15 seconds of clear speech
- 16-48kHz sample rate

## Architecture

```
┌─────────────────┐     HTTP      ┌──────────────────┐
│  Claude Code    │──────────────▶│  TTS Server      │
│                 │               │  (localhost:8877)│
│  - /speak cmd   │               │                  │
│  - Notif hook   │◀──────────────│  - Chatterbox    │
│  - Session hook │    Audio      │  - MPS/CUDA/CPU  │
└─────────────────┘               └──────────────────┘
```

The TTS server auto-starts on Claude Code session start and keeps the model loaded for fast inference.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHATTERBOX_PORT` | 8877 | Server port |
| `CHATTERBOX_VOICE` | voices/default.wav | Voice file |
| `CHATTERBOX_OUTPUT_DIR` | ~/.chatterbox/output | Generated audio |
| `CHATTERBOX_VENV` | ~/.chatterbox/venv | Python venv |

## Performance

Approximate inference times per generation:

| Device | Time |
|--------|------|
| MPS (M1/M2/M3) | 2-4 seconds |
| CUDA (RTX 3080) | 1-2 seconds |
| CPU | 8-15 seconds |

## Troubleshooting

**Server not starting**: Check `~/.chatterbox/server.log`

**MPS float64 error**: Re-run `/tts-setup` - the setup script patches Chatterbox for MPS compatibility

**No audio playback**: Ensure `afplay` (macOS) or `aplay` (Linux) is available

## License

MIT

## Credits

- [Resemble AI](https://www.resemble.ai/) for the Chatterbox model
- Built for [Claude Code](https://claude.ai/code)
