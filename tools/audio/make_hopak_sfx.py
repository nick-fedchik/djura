#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio"))
SAMPLE_RATE = 44100

def write_mono(filename, samples):
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
    print(f"Generated {filepath}")

def generate_hopak_sfx():
    # Punch swoosh & snap (0.12s)
    dur = 0.12
    n = int(SAMPLE_RATE * dur)
    seed = 65432
    samples_punch = []
    for i in range(n):
        t = i / SAMPLE_RATE
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        env = math.exp(-t * 35.0)
        snap = math.sin(2.0 * math.pi * (240.0 + (1.0 - t/dur) * 450.0) * t) * math.exp(-t * 40.0)
        samples_punch.append((noise * 0.45 + snap * 0.55) * env * 0.5)
    write_mono("hopak_punch.wav", samples_punch)

    # Kick swoosh & power thump (0.18s)
    dur = 0.18
    n = int(SAMPLE_RATE * dur)
    seed = 87654
    samples_kick = []
    for i in range(n):
        t = i / SAMPLE_RATE
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        env = math.exp(-t * 22.0)
        thump = math.sin(2.0 * math.pi * (160.0 + (1.0 - t/dur) * 320.0) * t) * math.exp(-t * 25.0)
        samples_kick.append((noise * 0.4 + thump * 0.6) * env * 0.55)
    write_mono("hopak_kick.wav", samples_kick)

if __name__ == "__main__":
    generate_hopak_sfx()
