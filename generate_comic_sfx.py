#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = "/home/mfedchyk/geek-jack/assets/audio"
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
    print(f"Generated {filepath}")

def generate_comic_poof():
    # Comic bubble pop + quick cheerful slide whistle ("По-о-оф!")
    dur = 0.35
    n_samples = int(SAMPLE_RATE * dur)
    samples = []
    seed = 44211
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        
        # 1. Bubble pop impulse (0 - 0.05s)
        pop_env = math.exp(-t * 85.0)
        pop_freq = 600.0 - t * 4500.0
        pop = math.sin(2.0 * math.pi * max(80.0, pop_freq) * t) * pop_env
        
        # 2. White smoke puff hiss
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = (((seed >> 16) & 0xFF) / 127.5 - 1.0) * math.exp(-t * 22.0) * 0.35
        
        # 3. Comic ascending slide whistle with vibrato ("WHEEE-oop!")
        whistle_t = max(0.0, t - 0.03)
        whistle_env = math.exp(-whistle_t * 9.0) * (1.0 - math.exp(-whistle_t * 60.0))
        freq = 550.0 + 850.0 * (whistle_t / dur) + math.sin(whistle_t * 50.0) * 35.0
        whistle = math.sin(2.0 * math.pi * freq * whistle_t) * whistle_env * 0.55
        
        samples.append((pop * 0.7 + noise + whistle) * 0.85)
    
    write_wav("chort_poof.wav", samples)

def generate_comic_bonk():
    # Snappy wooden skull thud with comical springy jaw-harp vibration
    dur = 0.28
    n_samples = int(SAMPLE_RATE * dur)
    samples = []
    seed = 88991
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        
        # Snap click
        click_env = math.exp(-t * 240.0)
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        click = noise * click_env * 0.75
        
        # Low hollow thud
        thud_env = math.exp(-t * 28.0)
        freq = 70.0 + 260.0 * math.exp(-t * 40.0)
        thud = math.sin(2.0 * math.pi * freq * t) * thud_env * 0.70
        
        # Comical rubber spring / jaw-harp "boing" wobble
        boing_env = math.exp(-t * 14.0) * (1.0 - math.exp(-t * 80.0))
        boing_freq = 190.0 + math.sin(t * 70.0) * 45.0
        boing = math.sin(2.0 * math.pi * boing_freq * t) * boing_env * 0.45
        
        samples.append((click + thud + boing) * 0.75)
        
    write_wav("bonk.wav", samples)

if __name__ == "__main__":
    generate_comic_poof()
    generate_comic_bonk()
