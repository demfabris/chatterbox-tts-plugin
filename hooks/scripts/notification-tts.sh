#!/bin/bash
# Claude Code Notification Hook - TTS via Chatterbox
# Speaks notifications using the local TTS server
#
# Features:
#   - Extracts actual Claude message from transcript (not just generic notification)
#   - LLM formatting via Haiku for natural speech (numbers, symbols, markdown)
#   - Debug logging support via TTS_DEBUG=1
#
# Testing:
#   TTS_DEBUG=1 echo '{"transcript_path":"/path/to/transcript.jsonl","message":"fallback"}' | ./notification-tts.sh
#   tail -f ~/.claude/hooks/tts-debug.log

TTS_SERVER="${CHATTERBOX_SERVER:-http://localhost:8877}"

# Pipe stdin to Python for reliable JSON handling
python3 -c "
import sys, json, urllib.parse, urllib.request, subprocess, os
from datetime import datetime

TTS_SERVER = '$TTS_SERVER'
MAX_CHARS = 500  # Truncate long messages for TTS
DEBUG = os.environ.get('TTS_DEBUG', '0') == '1'
LOG_FILE = os.path.expanduser('~/.claude/hooks/tts-debug.log')

def log(msg):
    if not DEBUG:
        return
    try:
        with open(LOG_FILE, 'a') as f:
            ts = datetime.now().strftime('%H:%M:%S')
            f.write(f'[{ts}] {msg}\n')
    except:
        pass

TTS_PROMPT = '''Convert this text to natural spoken form for text-to-speech. Rules:
- Convert symbols: \$ → dollars, % → percent, @ → at, & → and, etc.
- Expand numbers naturally: 500 → five hundred, 3.14 → three point one four
- Skip or summarize code blocks, file paths, URLs (just say 'a file path' or 'a link')
- Remove markdown formatting (**, \`, #, etc.)
- Keep it concise and conversational
- Return ONLY the speakable text, nothing else

Text to convert:
'''

def get_last_assistant_message(transcript_path):
    \"\"\"Read transcript JSONL and extract last assistant message with actual text content.\"\"\"
    try:
        log(f'Reading transcript: {transcript_path}')
        with open(transcript_path, 'r') as f:
            lines = f.readlines()
        log(f'Transcript has {len(lines)} lines')

        for line in reversed(lines):
            try:
                entry = json.loads(line.strip())
                if entry.get('type') == 'assistant':
                    content = entry.get('message', {}).get('content', [])
                    # Only extract text blocks (skip tool_use, thinking, etc)
                    texts = [block.get('text', '') for block in content if block.get('type') == 'text']
                    result = ' '.join(texts).strip()
                    # Keep searching if this entry has no text (e.g., only tool_use)
                    if result:
                        log(f'Found assistant text: {result[:100]}...')
                        return result
                    else:
                        log(f'Skipping assistant entry with no text content')
            except json.JSONDecodeError:
                continue
        log('No assistant message with text found in transcript')
    except Exception as e:
        log(f'Error reading transcript: {e}')
    return None

def format_for_tts(text):
    \"\"\"Use Haiku via Claude CLI to format text for better TTS output.\"\"\"
    try:
        log(f'Formatting via Haiku: {text[:80]}...')
        prompt = TTS_PROMPT + text
        result = subprocess.run(
            ['claude', '--model', 'haiku', '--no-session-persistence', '-p', prompt],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            formatted = result.stdout.strip()
            log(f'Haiku output: {formatted[:100]}...')
            return formatted
        log(f'Haiku failed: rc={result.returncode}, stderr={result.stderr[:100]}')
        return text
    except Exception as e:
        log(f'Haiku error: {e}')
        return text

try:
    log('--- TTS Hook Start ---')
    data = json.load(sys.stdin)
    log(f'Input: {json.dumps(data)[:200]}...')
    transcript_path = data.get('transcript_path', '')
    fallback_message = data.get('message', '')

    message = get_last_assistant_message(transcript_path) if transcript_path else None

    if not message:
        log('No transcript message, using fallback')
        message = fallback_message

    if not message:
        log('No message at all, exiting')
        sys.exit(0)

    # Truncate before LLM call to save tokens
    if len(message) > MAX_CHARS:
        log(f'Truncating from {len(message)} to {MAX_CHARS} chars')
        message = message[:MAX_CHARS] + '...'

    # Format for speakability via Haiku
    message = format_for_tts(message)

    # Check if TTS server is running
    try:
        urllib.request.urlopen(f'{TTS_SERVER}/health', timeout=1)
        log('TTS server healthy')
    except Exception as e:
        log(f'TTS server not available: {e}')
        sys.exit(0)

    # Call TTS (fire and forget)
    encoded = urllib.parse.quote(message)
    url = f'{TTS_SERVER}/speak/{encoded}?play=true'
    log(f'Calling TTS: {url[:100]}...')
    subprocess.Popen(
        ['curl', '-s', url],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    log('TTS request sent')
except Exception as e:
    log(f'Fatal error: {e}')

log('--- TTS Hook End ---')
sys.exit(0)
"
