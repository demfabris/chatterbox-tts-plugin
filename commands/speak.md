---
description: Speak text aloud using Chatterbox TTS
argument-hint: "<text to speak>"
allowed-tools:
  - Bash
---

# /speak Command

Generate speech from text using the Chatterbox TTS server.

## Instructions

1. Extract the text from the user's command arguments
2. Check if the TTS server is running by calling `curl -s http://localhost:8877/health`
3. If server is not running, inform the user to run `/tts-setup` first
4. Call the TTS server to generate and play audio:

```bash
TEXT="<user's text>"
ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$TEXT'''))")
curl -s "http://localhost:8877/speak/${ENCODED}?play=true"
```

5. Report the result to the user (file path and duration)

## Examples

User: `/speak Hello world!`
Action: Generate and play "Hello world!"

User: `/speak "This is a longer message with [laugh] some emotion tags"`
Action: Generate speech with paralinguistic tags

## Paralinguistic Tags

The model supports inline emotion tags:
- `[laugh]`, `[chuckle]` - Laughter
- `[sigh]`, `[gasp]` - Breathing
- `[cough]`, `[clear throat]` - Throat sounds
- `[groan]`, `[sniff]` - Other vocalizations

Example: "Oh really? [laugh] That's hilarious!"
