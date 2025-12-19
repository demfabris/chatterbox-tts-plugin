---
description: Check Chatterbox TTS status and health
allowed-tools:
  - Bash
---

# /tts-status Command

Check the status of Chatterbox TTS installation and server.

## Instructions

Run these checks and report results to the user:

### 1. Check Setup Status

```bash
if [ -d "$HOME/.chatterbox/venv" ]; then
    echo "Setup: Complete"
else
    echo "Setup: NOT CONFIGURED - Run /tts-setup"
fi
```

### 2. Check Server Health

```bash
response=$(curl -s --connect-timeout 2 http://localhost:8877/health 2>/dev/null)
if [ -n "$response" ]; then
    echo "Server: Running"
    echo "Health: $response"
else
    echo "Server: NOT RUNNING"
fi
```

### 3. Check Voice File

```bash
if [ -f "$CLAUDE_PLUGIN_ROOT/voices/default.wav" ]; then
    echo "Voice: Configured"
else
    echo "Voice: Missing default.wav"
fi
```

### 4. Test TTS (if server running)

If server is healthy, generate a test phrase:

```bash
curl -s "http://localhost:8877/speak/Status%20check%20complete?play=true"
```

## Summary Format

Present results as a status table:

| Component | Status |
|-----------|--------|
| Setup | Complete/Not configured |
| Server | Running/Stopped |
| Device | mps/cuda/cpu |
| Voice | Configured/Missing |

If any issues, provide the fix command (usually `/tts-setup`).
