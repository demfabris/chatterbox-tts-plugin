#!/bin/bash
# Claude Code SessionStart Hook - Auto-start TTS server
# Checks if server is running, starts it if not

TTS_SERVER="${CHATTERBOX_SERVER:-http://localhost:8877}"
TTS_PORT="${CHATTERBOX_PORT:-8877}"
VENV_DIR="${CHATTERBOX_VENV:-$HOME/.chatterbox/venv}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
LOG_FILE="$HOME/.chatterbox/server.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Check if server is already running
if curl -s --connect-timeout 2 "$TTS_SERVER/health" > /dev/null 2>&1; then
    # Server is running
    exit 0
fi

# Check if venv exists (setup completed)
if [ ! -d "$VENV_DIR" ]; then
    # Setup not complete, skip auto-start
    exit 0
fi

# Start the server in background
(
    source "$VENV_DIR/bin/activate"
    export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
    export CHATTERBOX_PORT="$TTS_PORT"
    nohup python "$PLUGIN_ROOT/scripts/tts_server.py" >> "$LOG_FILE" 2>&1 &
) &

# Wait briefly for server to start
sleep 2

exit 0
