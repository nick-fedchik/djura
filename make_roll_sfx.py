#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = "/home/mfedchyk/geek-jack/assets/audio"
SAMPLE_RATE = 44100

def generate_roll():
    dur = 0.28
    n_samples = int(SAMPLE_RATE * dur)
    samples = []
    seed = 45678
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        progress = t / dur
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        
        # Whoosh envelope
        env = math.sin(progress * math.pi) ** 1.5
        
        # Resonant sweep (pitch shifts 180 -> 360 -> 120 Hz)
        freq = 160.0 + 200.0 * math.sin(progress * math.pi)
        body = math.sin(2.0 * math.pi * freq * t) * 0.4
        cloth = noise * 0.6
        
        val = (body + cloth) * env * 0.45
        samples.append(val)
    
    filepath = os.path.join(OUT_DIR, "roll.wav")
    with wave.open(filepath, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        raw = bytearray()
        for s in samples:
            raw.extend(struct.pack("<h", int(s * 32767.0)))
        w.writeframes(raw)
    print("Generated roll.wav")

if __name__ == "__main__":
    generate_roll()
