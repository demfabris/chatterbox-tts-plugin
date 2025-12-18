# MPS (Apple Silicon) Compatibility Fixes

Chatterbox requires patches to run on Apple Silicon GPUs via MPS (Metal Performance Shaders).

## The Problem

MPS doesn't support float64 (double precision). The original Chatterbox code uses float64 in several places:

1. **librosa.load()** returns float64 by default
2. **numpy operations** often upcast to float64
3. **torch.from_numpy()** preserves float64 dtype

When these float64 tensors hit MPS operations, PyTorch throws:
```
Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64
```

## The Fix

The setup script patches `tts_turbo.py` to force float32:

```python
# After librosa.load()
s3gen_ref_wav = s3gen_ref_wav.astype(np.float32)

# After librosa.resample()
ref_16k_wav = librosa.resample(...).astype(np.float32)

# After norm_loudness()
s3gen_ref_wav = s3gen_ref_wav.astype(np.float32)
```

## Manual Patching

If auto-patch fails, manually edit `~/.chatterbox/chatterbox-repo/src/chatterbox/tts_turbo.py`:

1. Add numpy import at top:
```python
import numpy as np
```

2. In `prepare_conditionals()`, after line `s3gen_ref_wav, _sr = librosa.load(...)`:
```python
s3gen_ref_wav = s3gen_ref_wav.astype(np.float32)
```

3. After `norm_loudness()` call:
```python
s3gen_ref_wav = s3gen_ref_wav.astype(np.float32)
```

4. After `librosa.resample()`:
```python
ref_16k_wav = librosa.resample(...).astype(np.float32)
```

## HuggingFace Token Issue

The original code requires HF authentication:
```python
token=os.getenv("HF_TOKEN") or True  # Forces auth
```

The patch changes to:
```python
token=os.getenv("HF_TOKEN") or None  # Anonymous access
```

The model is public, so no authentication needed.

## Verifying MPS

Check MPS is working:

```python
import torch
print(f"MPS available: {torch.backends.mps.is_available()}")
print(f"MPS built: {torch.backends.mps.is_built()}")
```

The TTS server reports device on startup:
```
Starting TTS server on http://localhost:8877
Device: mps
```

## Performance

MPS vs CPU inference times (approximate):
- **MPS (M1/M2)**: ~2-4 seconds per generation
- **CPU (M1/M2)**: ~8-15 seconds per generation
- **CUDA (RTX 3080)**: ~1-2 seconds per generation

MPS provides 3-4x speedup over CPU on Apple Silicon.
