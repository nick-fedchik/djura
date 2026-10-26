#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio"))
SAMPLE_RATE = 44100

def normalize_wav(filename, target_peak=0.92):
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "r") as w:
        n_channels = w.getnchannels()
        sampwidth = w.getsampwidth()
        framerate = w.getframerate()
        n_frames = w.getnframes()
        data = w.readframes(n_frames)
    
    samples = struct.unpack(f"<{n_frames * n_channels}h", data)
    max_amp = max(abs(s) for s in samples)
    if max_amp == 0:
        return
    
    scale = (target_peak * 32767.0) / max_amp
    print(f"Normalizing {filename}: max was {max_amp} ({max_amp/32767.0:.2f}), scale={scale:.2f}")
    
    new_data = bytearray()
    for s in samples:
        v = int(s * scale)
        v = max(-32767, min(32767, v))
        new_data.extend(struct.pack("<h", v))
    
    with wave.open(filepath, "w") as w:
        w.setnchannels(n_channels)
        w.setsampwidth(sampwidth)
        w.setframerate(framerate)
        w.writeframes(new_data)

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

# Generate Footsteps for Dzhura's Parkour movement
def generate_steps():
    # Step 1: Light leather boot tap (higher pitch)
    dur = 0.035
    n_samples = int(SAMPLE_RATE * dur)
    samples1 = []
    seed = 11111
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Noise burst
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        env = math.exp(-t * 90.0)
        click = math.sin(2.0 * math.pi * 320.0 * t) * math.exp(-t * 140.0)
        samples1.append((noise * 0.4 + click * 0.6) * env * 0.35)
    write_mono("step1.wav", samples1)

    # Step 2: Alternate foot tap (slightly different pitch)
    samples2 = []
    seed = 22222
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        env = math.exp(-t * 85.0)
        click = math.sin(2.0 * math.pi * 280.0 * t) * math.exp(-t * 130.0)
        samples2.append((noise * 0.4 + click * 0.6) * env * 0.35)
    write_mono("step2.wav", samples2)

    # Landing thud
    land_dur = 0.07
    land_samples = int(SAMPLE_RATE * land_dur)
    samples_land = []
    seed = 33333
    for i in range(land_samples):
        t = i / SAMPLE_RATE
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
        env = math.exp(-t * 45.0)
        thud = math.sin(2.0 * math.pi * 140.0 * math.exp(-t * 30.0) * t)
        samples_land.append((noise * 0.35 + thud * 0.65) * env * 0.55)
    write_mono("land.wav", samples_land)

if __name__ == "__main__":
    generate_steps()
    normalize_wav("bgm_stage.wav", target_peak=0.92)
