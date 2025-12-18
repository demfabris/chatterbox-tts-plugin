#!/bin/bash
# Simple TTS wrapper for Claude Code
# Usage: ./speak.sh "Hello world" [true|false]

TEXT="$1"
PLAY="${2:-true}"
TTS_SERVER="${CHATTERBOX_SERVER:-http://localhost:8877}"

if [ -z "$TEXT" ]; then
    echo "Usage: ./speak.sh \"text to speak\" [play:true|false]"
    exit 1
fi

# Check if server is running
if ! curl -s --connect-timeout 1 "$TTS_SERVER/health" > /dev/null 2>&1; then
    echo "TTS server not running at $TTS_SERVER"
    exit 1
fi

# URL encode the text
ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$TEXT'''))")

# Call TTS server
response=$(curl -s "$TTS_SERVER/speak/${ENCODED}?play=${PLAY}")

# Parse response
status=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','error'))" 2>/dev/null)

if [ "$status" = "ok" ]; then
    path=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('path',''))" 2>/dev/null)
    duration=$(echo "$response" | python3 -c "import sys,json; print(f\"{json.load(sys.stdin).get('duration_seconds',0):.1f}\")" 2>/dev/null)
    echo "Generated: $path (${duration}s)"
else
    echo "Error: $response" >&2
    exit 1
fi
