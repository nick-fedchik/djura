#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio"))
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        raw = bytearray()
        for s in samples:
            val = max(-1.0, min(1.0, s))
            raw.extend(struct.pack("<h", int(val * 32767.0)))
        w.writeframes(raw)
    print(f"Generated {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

# 1. MAGIC FERN FLOWER CHIME (Цвіт Папороті - містичний перелив)
def generate_magic_flower():
    dur = 0.85
    n_samples = int(SAMPLE_RATE * dur)
    samples = [0.0] * n_samples
    # Ascending pentatonic arpeggio of ringing magic bells (Cossack fairy motif)
    freqs = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98] # C5, E5, G5, C6, E6, G6
    for idx, f in enumerate(freqs):
        start_t = idx * 0.08
        start_i = int(start_t * SAMPLE_RATE)
        for i in range(int(0.45 * SAMPLE_RATE)):
            sample_idx = start_i + i
            if sample_idx < n_samples:
                t = i / SAMPLE_RATE
                env = math.exp(-t * 9.0)
                # Bell harmonics
                h1 = math.sin(2.0 * math.pi * f * t)
                h2 = math.sin(2.0 * math.pi * f * 2.01 * t) * 0.4
                h3 = math.sin(2.0 * math.pi * f * 3.02 * t) * 0.2
                shimmer = 1.0 + math.sin(2.0 * math.pi * 14.0 * t) * 0.15
                samples[sample_idx] += (h1 + h2 + h3) * env * shimmer * 0.22
    
    # Peak normalization
    peak = max(abs(x) for x in samples) or 1.0
    samples = [s / peak * 0.88 for s in samples]
    write_wav("magic_flower.wav", samples)

# 2. CHORT POOF / BANISH SOUND (Кумедний хлопок зникнення нечисті)
def generate_chort_poof():
    dur = 0.25
    n_samples = int(SAMPLE_RATE * dur)
    samples = []
    seed = 77123
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Noise burst
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        n_env = math.exp(-t * 40.0)
        
        # Funny descending cartoon pitch sweep (480Hz -> 80Hz)
        f = 80.0 + 400.0 * math.exp(-t * 25.0)
        sweep = math.sin(2.0 * math.pi * f * t) * math.exp(-t * 18.0)
        
        # Sparkle tail
        spark = math.sin(2.0 * math.pi * 1800.0 * t) * math.exp(-t * 30.0) * 0.3
        
        val = (noise * 0.45 * n_env + sweep * 0.55 + spark) * 0.85
        samples.append(val)
    
    write_wav("chort_poof.wav", samples)

if __name__ == "__main__":
    generate_magic_flower()
    generate_chort_poof()
