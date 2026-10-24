#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = "/home/mfedchyk/geek-jack/assets/audio"
SAMPLE_RATE = 44100

def generate_bonk():
    dur = 0.18
    n_samples = int(SAMPLE_RATE * dur)
    samples = []
    seed = 88991
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        progress = t / dur
        
        # Hard transient click / snap at t = 0 (skull hitting solid wood/stone)
        click_env = math.exp(-t * 220.0)
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        click = noise * click_env * 0.85
        
        # Low resonant thud (pitch drops rapidly 280Hz -> 90Hz -> 55Hz)
        thud_env = math.exp(-t * 32.0)
        freq = 60.0 + 220.0 * math.exp(-t * 45.0)
        thud = math.sin(2.0 * math.pi * freq * t) * thud_env * 0.75
        
        # Overtone resonance (hollow wooden platform resonance 380Hz)
        wood_env = math.exp(-t * 55.0)
        wood = math.sin(2.0 * math.pi * 380.0 * t) * wood_env * 0.35
        
        val = (click + thud + wood) * 0.70
        samples.append(max(-1.0, min(1.0, val)))
    
    filepath = os.path.join(OUT_DIR, "bonk.wav")
    with wave.open(filepath, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        raw = bytearray()
        for s in samples:
            raw.extend(struct.pack("<h", int(s * 32767.0)))
        w.writeframes(raw)
    print(f"Generated {filepath}")

if __name__ == "__main__":
    generate_bonk()
