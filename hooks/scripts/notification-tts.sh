#!/bin/bash
# Claude Code Notification Hook - TTS via Chatterbox
# Speaks notifications using the local TTS server

TTS_SERVER="${CHATTERBOX_SERVER:-http://localhost:8877}"

# Pipe stdin to Python for reliable JSON handling
python3 -c "
import sys, json, urllib.parse, urllib.request, subprocess

TTS_SERVER = '$TTS_SERVER'

try:
    data = json.load(sys.stdin)
    message = data.get('message', '')

    if not message:
        sys.exit(0)

    # Check if TTS server is running
    try:
        urllib.request.urlopen(f'{TTS_SERVER}/health', timeout=1)
    except:
        sys.exit(0)  # Server not running, exit silently

    # Call TTS (fire and forget)
    encoded = urllib.parse.quote(message)
    subprocess.Popen(
        ['curl', '-s', f'{TTS_SERVER}/speak/{encoded}?play=true'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
except Exception:
    pass  # Fail silently

sys.exit(0)
"
