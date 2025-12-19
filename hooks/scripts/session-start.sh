#!/bin/bash
# Claude Code SessionStart Hook - Auto-start TTS server
# Checks if server is running, starts it if not

TTS_SERVER="${CHATTERBOX_SERVER:-http://localhost:8877}"
TTS_PORT="${CHATTERBOX_PORT:-8877}"
VENV_DIR="${CHATTERBOX_VENV:-$HOME/.chatterbox/venv}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"
LOG_FILE="$HOME/.chatterbox/server.log"
FIRST_RUN_MARKER="$HOME/.chatterbox/.plugin_initialized"

# Ensure directories exist
mkdir -p "$HOME/.chatterbox"

# Check if this is first run (never seen this plugin before)
if [ ! -f "$FIRST_RUN_MARKER" ]; then
    # First time ever - show welcome message
    cat << 'EOF'
{"status":"welcome","message":"🎙️ Chatterbox TTS Plugin Installed!\n\nTo enable text-to-speech:\n  1. Run /tts-setup (takes ~5 min, downloads ~500MB)\n  2. After setup, TTS auto-starts each session\n  3. Use /speak \"text\" or notifications speak automatically\n\nRun /tts-status anytime to check health."}
EOF
    touch "$FIRST_RUN_MARKER"
    exit 0
fi

# Check if venv exists (setup completed)
if [ ! -d "$VENV_DIR" ]; then
    # Setup not complete - remind user
    echo '{"status":"setup_required","message":"TTS not configured. Run /tts-setup to enable voice."}'
    exit 0
fi

# Check if server is already running
if curl -s --connect-timeout 2 "$TTS_SERVER/health" > /dev/null 2>&1; then
    echo '{"status":"ok","message":"TTS server running"}'
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
sleep 3

# Verify it started
if curl -s --connect-timeout 2 "$TTS_SERVER/health" > /dev/null 2>&1; then
    echo '{"status":"ok","message":"TTS server started"}'
else
    echo '{"status":"error","message":"TTS server failed to start. Check ~/.chatterbox/server.log"}'
fi

exit 0
