# Voice Configuration Guide

Chatterbox performs zero-shot voice cloning from a reference audio file. Quality of the reference directly impacts output quality.

## Requirements

| Property | Requirement |
|----------|-------------|
| Format | WAV (PCM) |
| Channels | Mono (stereo will be converted) |
| Sample Rate | 16kHz - 48kHz |
| Duration | 5-15 seconds optimal |
| Bit Depth | 16-bit or 24-bit |

## Recording Tips

### Environment
- Quiet room with minimal echo
- No background noise (AC, fans, traffic)
- Soft surfaces help reduce reverb

### Speaking Style
- Natural conversational tone
- Consistent volume throughout
- Clear enunciation without over-articulating
- Include varied intonation (questions, statements)

### What to Say
Good reference content includes:
- Mix of short and long sentences
- Various phonemes and sounds
- Natural pauses between phrases

Example script:
> "Hello, this is a test of my voice for the text-to-speech system. I'm speaking naturally, with a conversational tone. How does this sound? I think it captures my voice well."

## Preparing Audio Files

### Using ffmpeg

Convert any audio to the correct format:

```bash
# Convert to mono 24kHz WAV
ffmpeg -i input.mp3 -ar 24000 -ac 1 output.wav

# Trim to specific duration (first 10 seconds)
ffmpeg -i input.wav -t 10 -ar 24000 -ac 1 trimmed.wav

# Normalize audio levels
ffmpeg -i input.wav -af "loudnorm=I=-16:LRA=11:TP=-1.5" normalized.wav
```

### Using Audacity

1. Import your audio file
2. Convert to mono: Tracks → Mix → Mix Stereo Down to Mono
3. Change sample rate: Tracks → Resample → 24000 Hz
4. Normalize: Effect → Normalize → -1.0 dB
5. Trim silence: Select and delete
6. Export: File → Export → Export as WAV

## Voice File Location

Default location: `$CLAUDE_PLUGIN_ROOT/voices/default.wav`

To use a custom voice:

```bash
# Replace default voice
cp /path/to/your/voice.wav $CLAUDE_PLUGIN_ROOT/voices/default.wav

# Or set environment variable
export CHATTERBOX_VOICE=/path/to/custom/voice.wav
```

## Troubleshooting Voice Quality

### Robotic/Distorted Output
- Reference audio may have too much reverb
- Try a cleaner recording environment
- Ensure audio isn't clipping (too loud)

### Wrong Pitch/Speed
- Chatterbox may struggle with very high/low pitched voices
- Try speaking at a moderate pace in the reference

### Inconsistent Quality
- Longer references (10-15s) often work better
- Include more varied speech patterns
- Ensure consistent microphone distance

### Foreign Accents
- Chatterbox is primarily trained on English
- Non-native accents may not clone as accurately
- Clear enunciation helps significantly

## Multiple Voice Files

For switching between voices, store multiple files:

```
voices/
├── default.wav      # Primary voice
├── voice-formal.wav # Formal tone
└── voice-casual.wav # Casual tone
```

Then specify via environment variable before starting server:

```bash
export CHATTERBOX_VOICE=$CLAUDE_PLUGIN_ROOT/voices/voice-formal.wav
```

## Sample Rates and Quality

| Sample Rate | Quality | File Size | Use Case |
|-------------|---------|-----------|----------|
| 16kHz | Good | ~320KB/10s | Voice calls |
| 22.05kHz | Better | ~440KB/10s | Podcasts |
| 24kHz | Best | ~480KB/10s | Recommended |
| 44.1kHz | Overkill | ~880KB/10s | Not needed |

The model internally resamples to 24kHz, so higher rates waste space without quality improvement.
