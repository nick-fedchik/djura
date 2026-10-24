import wave
import struct
import math
import random

SAMPLE_RATE = 44100

def generate_vakula_sfx(filename="assets/audio/vakula_anvil.wav"):
    duration = 1.6
    total_samples = int(duration * SAMPLE_RATE)
    data = []
    
    # Fundamental frequencies of a small forged anvil / golden chime
    # Strike at 1100 Hz, 1750 Hz, 2900 Hz, 4400 Hz
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        
        # Fast metallic strike impulse (anvil ping)
        strike_env = math.exp(-t * 18.0)
        # Long resonant bell shimmer
        shimmer_env = math.exp(-t * 2.8)
        
        # Anvil harmonics
        anvil = (
            math.sin(2 * math.pi * 1175.0 * t) * 0.45 +
            math.sin(2 * math.pi * 1760.0 * t) * 0.35 +
            math.sin(2 * math.pi * 2950.0 * t) * 0.25 +
            math.sin(2 * math.pi * 4400.0 * t) * 0.15
        ) * strike_env
        
        # Golden melodic chime chord (D major - Dzhura triumph chord: D6, F#6, A6)
        chime = (
            math.sin(2 * math.pi * 1174.66 * t) * 0.30 +
            math.sin(2 * math.pi * 1479.98 * t) * 0.25 +
            math.sin(2 * math.pi * 1760.00 * t) * 0.20 +
            math.sin(2 * math.pi * 2349.32 * t) * 0.15
        ) * shimmer_env
        
        # Subtle harmonic vibrato / sparkle
        sparkle = math.sin(2 * math.pi * (3520.0 + math.sin(t * 25.0) * 80.0) * t) * shimmer_env * 0.12
        
        sample = (anvil + chime + sparkle) * 0.75
        sample = max(-1.0, min(1.0, sample))
        
        data.append(int(sample * 32767))
        
    with wave.open(filename, 'wb') as wav:
        wav.setnchannels(1) # mono
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        for s in data:
            wav.writeframes(struct.pack('<h', s))
    print(f"Generated {filename}")

if __name__ == "__main__":
    generate_vakula_sfx()
