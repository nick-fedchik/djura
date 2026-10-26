#!/usr/bin/env python3
import math
import struct
import wave
import os

OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio"))
SAMPLE_RATE = 44100

def write_stereo(filename, left, right):
    filepath = os.path.join(OUT_DIR, filename)
    n = min(len(left), len(right))
    peak = max(max(abs(x) for x in left[:n]), max(abs(x) for x in right[:n]), 1e-6)
    gain = 0.92 / peak
    with wave.open(filepath, "w") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        raw = bytearray()
        for i in range(n):
            l = max(-1.0, min(1.0, left[i] * gain))
            r = max(-1.0, min(1.0, right[i] * gain))
            raw.extend(struct.pack("<hh", int(l * 32767.0), int(r * 32767.0)))
        w.writeframes(raw)
    print(f"Generated STEREO {filepath} ({n} frames, {n/SAMPLE_RATE:.2f}s, gain={gain:.2f}x)")

def saw_wave(freq, t):
    if freq <= 0: return 0.0
    return 2.0 * (t * freq - math.floor(t * freq + 0.5))

def triangle_wave(freq, t):
    if freq <= 0: return 0.0
    period = 1.0 / freq
    phase = (t % period) / period
    return 4.0 * abs(phase - 0.5) - 1.0

def sine_wave(freq, t):
    if freq <= 0: return 0.0
    return math.sin(2.0 * math.pi * freq * t)

# Plucked Bandura / Kobza string
def bandura_pluck(freq, t):
    if freq <= 0: return 0.0
    env = math.exp(-t * 16.0)
    h1 = sine_wave(freq, t)
    h2 = sine_wave(freq * 2.0, t) * 0.45
    h3 = sine_wave(freq * 3.02, t) * 0.22
    return (h1 + h2 + h3) * env

# Ukrainian Folk Sopilka
def sopilka_note(freq, t, dur):
    if freq <= 0: return 0.0
    att = min(1.0, t / 0.025)
    rel = min(1.0, (dur - t) / 0.04)
    env = att * rel
    vib = math.sin(2.0 * math.pi * 6.2 * t) * 0.016 if t > 0.06 else 0.0
    f = freq * (1.0 + vib)
    sound = triangle_wave(f, t) * 0.65 + sine_wave(f * 2.0, t) * 0.25 + saw_wave(f, t) * 0.10
    return sound * env

# Sparkling Tsymbaly
def tsymbaly_strike(freq, t):
    if freq <= 0: return 0.0
    env = math.exp(-t * 12.0)
    s = (sine_wave(freq, t) + sine_wave(freq * 2.01, t) * 0.5 + sine_wave(freq * 3.01, t) * 0.25) * env
    return s

def generate_stage_bgm():
    # 134 BPM Driving Ukrainian Cossack Campaign Folklore
    bpm = 134.0
    quarter = 60.0 / bpm
    eighth = quarter / 2.0
    sixteenth = quarter / 4.0
    
    # Notes
    D3 = 146.83; E3 = 164.81; F3 = 174.61; G3 = 196.00; A3 = 220.00; Bb3 = 233.08
    C4 = 261.63; D4 = 293.66; E4 = 329.63; F4 = 349.23; G4 = 392.00; A4 = 440.00; Bb4 = 466.16
    C5 = 523.25; Csh5 = 554.37; D5 = 587.33; E5 = 659.25; F5 = 698.46; G5 = 783.99; A5 = 880.00

    # 16-measure loop based on historical Cossack motifs (Dm -> Gm -> C -> F -> Bb -> Gm -> A7 -> Dm)
    # Sopilka Lead Melody (freq, duration_in_eighths)
    melody = [
        # Phrase 1: "Засвистали козаченьки" motif
        (A4, 1.0), (D5, 1.0), (E5, 1.0), (F5, 1.0),
        (E5, 1.5), (D5, 0.5), (E5, 2.0),
        (F5, 1.0), (G5, 1.0), (A5, 1.5), (G5, 0.5),
        (F5, 1.5), (E5, 0.5), (D5, 2.0),
        
        # Phrase 2: Steppe Flight & Flourish
        (D5, 1.0), (F5, 1.0), (G5, 1.0), (A5, 1.0),
        (Bb5 if 'Bb5' in locals() else Bb4 * 2, 1.5), (A5, 0.5), (G5, 2.0),
        (A5, 1.0), (F5, 1.0), (G5, 1.0), (E5, 1.0),
        (F5, 1.0), (D5, 1.0), (D5, 2.0),
        
        # Phrase 3: Cossack Campaign Variation (Gm -> C -> F -> Bb)
        (G4, 1.0), (Bb4, 1.0), (D5, 1.5), (C5, 0.5),
        (C5, 1.0), (E5, 1.0), (F5, 2.0),
        (D5, 1.0), (F5, 1.0), (G5, 1.5), (F5, 0.5),
        (E5, 1.5), (D5, 0.5), (Csh5, 2.0),
        
        # Phrase 4: Final Cossack Resolve into Loop
        (D5, 1.0), (F5, 1.0), (A5, 1.0), (F5, 1.0),
        (G5, 1.5), (F5, 0.5), (E5, 2.0),
        (F5, 1.0), (D5, 1.0), (E5, 1.0), (Csh5, 1.0),
        (D5, 3.0), (0, 1.0)
    ]
    
    total_eighths = sum(dur for _, dur in melody)
    total_time = total_eighths * eighth
    total_samples = int(SAMPLE_RATE * total_time)
    
    left = [0.0] * total_samples
    right = [0.0] * total_samples
    
    # 1. SOPILKA (Lead Melody, Center-Left with subtle tape delay)
    curr_t = 0.0
    for freq, num_eighths in melody:
        dur = num_eighths * eighth
        start_idx = int(curr_t * SAMPLE_RATE)
        n_samples = int(dur * SAMPLE_RATE)
        if freq > 0:
            for i in range(n_samples):
                idx = start_idx + i
                if idx < total_samples:
                    t = i / SAMPLE_RATE
                    val = sopilka_note(freq, t, dur) * 0.38
                    left[idx] += val * 0.70
                    right[idx] += val * 0.45
                    # Space echo delay
                    d_idx = idx + int(0.18 * SAMPLE_RATE)
                    if d_idx < total_samples:
                        left[d_idx] += val * 0.15
                        right[d_idx] += val * 0.30
        curr_t += dur

    # 2. BANDURA / KOBZA 16th-note Arpeggios (Warm plucked accompaniment)
    # Harmony loop across 16 bars (4 eighths per bar = 8 sixteenths per bar)
    chords = [
        [D4, F4, A4, D5], [A3, Csh5, E5, A4], [D4, F4, A4, D5], [D4, F4, A4, D5],
        [D4, F4, A4, D5], [G4, Bb4, D5, G5], [D4, F4, A4, D5], [D4, F4, A4, D5],
        [G3, Bb3, D4, G4], [C4, E4, G4, C5], [F3, A3, C4, F4], [A3, Csh5, E5, A4],
        [D4, F4, A4, D5], [G4, Bb4, D5, G5], [A3, Csh5, E5, A4], [D4, F4, A4, D4]
    ]
    
    total_sixteenths = int(total_eighths * 2)
    for s in range(total_sixteenths):
        bar_idx = (s // 8) % len(chords)
        chord = chords[bar_idx]
        note = chord[s % len(chord)]
        t_start = s * sixteenth
        start_idx = int(t_start * SAMPLE_RATE)
        s_samples = int(0.22 * SAMPLE_RATE)
        for i in range(s_samples):
            idx = start_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                val = bandura_pluck(note, t) * 0.28
                left[idx] += val * 0.60
                right[idx] += val * 0.40

    # 3. TSYMBALY (Center-Right sparkle on downbeats and syncopated turns)
    for s in range(0, total_sixteenths, 2):
        bar_idx = (s // 8) % len(chords)
        chord = chords[bar_idx]
        note = chord[(s // 2) % len(chord)] * 2.0 # Upper octave sparkle
        t_start = s * sixteenth
        start_idx = int(t_start * SAMPLE_RATE)
        s_samples = int(0.18 * SAMPLE_RATE)
        for i in range(s_samples):
            idx = start_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                val = tsymbaly_strike(note, t) * 0.18
                left[idx] += val * 0.25
                right[idx] += val * 0.70

    # 4. BASOLIA (Deep bouncing folk bass on beats 1 and 3)
    bass_prog = [
        D3, A3, D3, D3,
        D3, G3, D3, D3,
        G3, C4, F3, A3,
        D3, G3, A3, D3
    ]
    for b_idx, b_note in enumerate(bass_prog):
        t_start = b_idx * (quarter * 2.0)
        # Note on beat 1
        for beat in [0.0, quarter]:
            start_idx = int((t_start + beat) * SAMPLE_RATE)
            b_samples = int(0.35 * SAMPLE_RATE)
            for i in range(b_samples):
                idx = start_idx + i
                if idx < total_samples:
                    t = i / SAMPLE_RATE
                    env = math.exp(-t * 6.5)
                    val = (triangle_wave(b_note / 2.0, t) * 0.75 + sine_wave(b_note / 2.0, t) * 0.25) * env * 0.55
                    left[idx] += val * 0.50
                    right[idx] += val * 0.50

    # 5. COSSACK BUBON & TAMBOURINE (Percussion)
    seed = 33333
    total_beats = int(total_eighths / 2.0)
    for b in range(total_beats):
        b_time = b * quarter
        b_idx = int(b_time * SAMPLE_RATE)
        # Kick on downbeat
        k_samples = int(0.12 * SAMPLE_RATE)
        for i in range(k_samples):
            idx = b_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                freq = 55.0 + 85.0 * math.exp(-t * 35.0)
                val = sine_wave(freq, t) * math.exp(-t * 20.0) * 0.42
                left[idx] += val * 0.5
                right[idx] += val * 0.5
        
        # Tambourine jingle on offbeat
        off_idx = b_idx + int(eighth * SAMPLE_RATE)
        j_samples = int(0.08 * SAMPLE_RATE)
        for i in range(j_samples):
            idx = off_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
                noise = ((seed >> 16) & 0xFF) / 127.5 - 1.0
                j_env = math.exp(-t * 50.0)
                ring = math.sin(2.0 * math.pi * 3400.0 * t) * 0.45
                val = (noise * 0.6 + ring) * j_env * 0.16
                left[idx] += val * 0.65
                right[idx] += val * 0.35

    write_stereo("bgm_stage.wav", left, right)

if __name__ == "__main__":
    generate_stage_bgm()
    print("Ukrainian 17-19th century Cossack campaign stage BGM generated!")
