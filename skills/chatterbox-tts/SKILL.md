---
name: Chatterbox TTS
description: |
  Use this skill when the user asks about text-to-speech setup, voice cloning configuration,
  TTS troubleshooting, or wants to understand how the Chatterbox TTS integration works.
  Trigger phrases: "setup TTS", "configure voice", "TTS not working", "chatterbox",
  "voice cloning", "speak command", "notification voice", "MPS error", "float64 error"
---

# Chatterbox TTS for Claude Code

Chatterbox is a zero-shot voice cloning TTS model from Resemble AI. This plugin integrates it with Claude Code for:
- Speaking notifications aloud
- On-demand TTS via `/speak` command
- Voice cloning from a reference audio file

## Architecture

```
┌─────────────────┐     HTTP      ┌──────────────────┐
│  Claude Code    │──────────────▶│  TTS Server      │
│                 │               │  (FastAPI)       │
│  - /speak cmd   │               │                  │
│  - Notif hook   │◀──────────────│  - Chatterbox    │
│  - Session hook │    Audio      │  - MPS/CUDA/CPU  │
└─────────────────┘               └──────────────────┘
```

## Quick Start

1. Run `/tts-setup` to install dependencies
2. Server auto-starts on new Claude Code sessions
3. Use `/speak "text"` for on-demand TTS
4. Notifications are spoken automatically

## Commands

### /speak "text"
Generate and play speech from text. Supports paralinguistic tags:
- `[laugh]`, `[chuckle]` - Laughter
- `[sigh]`, `[gasp]` - Breathing sounds
- `[cough]`, `[clear throat]` - Throat clearing

Example: `/speak "Oh really? [laugh] That's hilarious!"`

### /tts-setup
Install dependencies and configure TTS. Run once after plugin installation.

## Voice Configuration

The plugin uses a default voice file at `voices/default.wav`. To change:

1. Prepare a WAV file (5-15 seconds of clear speech)
2. Replace the default: `cp your-voice.wav $CLAUDE_PLUGIN_ROOT/voices/default.wav`
3. Restart the TTS server

Voice file requirements:
- WAV format, mono channel
- 16kHz-48kHz sample rate
- Clear speech without background noise
- At least 5 seconds duration

## Troubleshooting

See `references/mps-fixes.md` for Apple Silicon specific issues.
See `references/voice-config.md` for voice quality tips.

### Common Issues

**Server not starting**: Check `~/.chatterbox/server.log` for errors

**MPS float64 error**: Re-run `/tts-setup` to apply patches

**Model download fails**: Ensure internet connection, HuggingFace accessible

**Audio not playing**: Verify `afplay` (macOS) or `aplay` (Linux) is available

## API Reference

The TTS server runs on `http://localhost:8877`:

- `GET /health` - Server status
- `GET /speak/{text}?play=true` - Generate and play speech
- `POST /speak` - Full control with JSON body

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHATTERBOX_PORT` | 8877 | Server port |
| `CHATTERBOX_VENV` | ~/.chatterbox/venv | Virtual environment |
| `CHATTERBOX_VOICE` | voices/default.wav | Voice file path |
| `CHATTERBOX_OUTPUT_DIR` | ~/.chatterbox/output | Generated audio |
