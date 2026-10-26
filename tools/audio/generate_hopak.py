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

# Folk Sound Synthesis
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

# Tsymbaly (Hammered Dulcimer plucked tone)
def tsymbaly_note(freq, t):
    if freq <= 0: return 0.0
    # Plucked string harmonic decay
    env = math.exp(-t * 14.0)
    harm1 = sine_wave(freq, t)
    harm2 = sine_wave(freq * 2.0, t) * 0.5
    harm3 = sine_wave(freq * 3.01, t) * 0.25 # metallic slight inharmonicity
    return (harm1 + harm2 + harm3) * env

# Sopilka / Fiddle (Breathy vibrating folk lead)
def folk_fiddle(freq, t, dur):
    if freq <= 0: return 0.0
    att = min(1.0, t / 0.02)
    rel = min(1.0, (dur - t) / 0.03)
    env = att * rel
    vib = math.sin(2.0 * math.pi * 6.2 * t) * 0.018 if t > 0.05 else 0.0
    f = freq * (1.0 + vib)
    s = saw_wave(f, t) * 0.55 + triangle_wave(f, t) * 0.45
    return s * env

def generate_hopak_music():
    # 138 BPM Authentic Ukrainian Hopak (2/4 time signature, 4.10s full 6-phase duration)
    bpm = 138.0
    beat_dur = 60.0 / bpm # ~0.3947 sec per beat (quarter note)
    eighth = beat_dur / 2.0 # eighth note
    sixteenth = beat_dur / 4.0

    # 8 measures of 2/4 = 16 beats = 32 eighth notes = ~6.3s or 4 measures = ~3.2s
    # 4 bars of 2/4 with upbeat: 9 beats total (~3.55 seconds) - perfect fit for victory celebration!
    # Canonical Ukrainian Hopak Dance Motif ("Козачок / Гопак")
    # Pitch frequencies:
    D4 = 293.66; E4 = 329.63; F4 = 349.23; G4 = 392.00
    A4 = 440.00; Bb4 = 466.16; C5 = 523.25; Csh5 = 554.37
    D5 = 587.33; E5 = 659.25; F5 = 698.46; G5 = 783.99; A5 = 880.00

    # Melody sequence: (freq, duration_in_eighths)
    melody = [
        # Bar 1: Ascending Cossack run
        (D4, 0.5), (F4, 0.5), (G4, 0.5), (A4, 0.5),
        # Bar 2: Spirited Hopak bounce
        (Bb4, 1.0), (A4, 0.5), (G4, 0.5),
        # Bar 3: Cadence turn
        (A4, 1.0), (F4, 0.5), (D4, 0.5),
        # Bar 4: Syncopated punch
        (E4, 0.5), (F4, 0.5), (G4, 0.5), (E4, 0.5),
        # Bar 5: High spirited leap!
        (F5, 1.0), (D5, 0.5), (F5, 0.5),
        # Bar 6: Rapid Cossack flourish
        (G5, 0.5), (F5, 0.5), (E5, 0.5), (D5, 0.5),
        # Bar 7: Turnaround
        (Csh5, 0.5), (E5, 0.5), (A4, 1.0),
        # Bar 8: Final celebratory "Гоп!" chord & resolution
        (D5, 1.5), (0, 0.5), (D5, 1.5)
    ]

    total_eighths = sum(dur for _, dur in melody)
    total_time = total_eighths * eighth + 0.3 # ring out
    total_samples = int(SAMPLE_RATE * total_time)

    left = [0.0] * total_samples
    right = [0.0] * total_samples

    # 1. FOLK FIDDLE / SOPILKA LEAD (Center-Left)
    curr_t = 0.0
    for freq, num_eighths in melody:
        dur = num_eighths * eighth
        start_idx = int(curr_t * SAMPLE_RATE)
        n_samples = int(dur * SAMPLE_RATE)
        for i in range(n_samples):
            idx = start_idx + i
            if idx < total_samples and freq > 0:
                t = i / SAMPLE_RATE
                val = folk_fiddle(freq, t, dur) * 0.42
                left[idx] += val * 0.70
                right[idx] += val * 0.45
        curr_t += dur

    # 2. TSYMBALY (Hammered Dulcimer arpeggios, Center-Right sparkle)
    # Playing bouncy 16th-note arpeggio accompaniment
    curr_t = 0.0
    tsymbaly_pattern = [
        # Bar 1-2 (Dm)
        D4, A4, F4, A4, D4, A4, F4, A4,
        # Bar 3-4 (Gm -> A7)
        G4, Bb4, D5, Bb4, A4, Csh5, E5, Csh5,
        # Bar 5-6 (Dm -> Gm)
        D5, F5, A4, D5, G4, Bb4, D5, Bb4,
        # Bar 7-8 (A7 -> Dm Final Stomp)
        A4, Csh5, E5, Csh5, D4, F4, A4, D5
    ]
    for s_idx, t_freq in enumerate(tsymbaly_pattern):
        t_start = s_idx * (eighth * 0.5)
        start_idx = int(t_start * SAMPLE_RATE)
        t_samples = int(0.25 * SAMPLE_RATE)
        for i in range(t_samples):
            idx = start_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                val = tsymbaly_note(t_freq, t) * 0.28
                left[idx] += val * 0.35
                right[idx] += val * 0.75

    # 3. BASOLIA (Deep Folk Bass "Ум-ца, ум-ца")
    # Downbeats of each measure: D2, G2, A2, D2
    bass_notes = [
        (146.83 / 2, 1.0), # Dm root
        (196.00 / 2, 1.0), # Gm root
        (220.00 / 2, 1.0), # A7 root
        (146.83 / 2, 1.0), # Dm root
        (146.83 / 2, 1.0), # Dm
        (196.00 / 2, 1.0), # Gm
        (220.00 / 2, 1.0), # A7
        (146.83 / 2, 1.5)  # Dm final
    ]
    curr_t = 0.0
    for b_freq, b_dur in bass_notes:
        start_idx = int(curr_t * SAMPLE_RATE)
        n_samples = int(b_dur * beat_dur * SAMPLE_RATE)
        for i in range(n_samples):
            idx = start_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                env = math.exp(-t * 6.5)
                val = (triangle_wave(b_freq, t) * 0.7 + sine_wave(b_freq, t) * 0.3) * env * 0.50
                left[idx] += val * 0.55
                right[idx] += val * 0.55
        curr_t += b_dur * beat_dur

    # 4. BUBON Z BRIAZKALTSYAMY (Folk Tambourine & Bass Drum)
    total_beats = int(total_eighths / 2.0)
    seed = 77777
    for b in range(total_beats):
        b_time = b * beat_dur
        b_idx = int(b_time * SAMPLE_RATE)
        
        # Heavy Bass Drum on downbeat (The Hopak Stomp)
        k_samples = int(0.14 * SAMPLE_RATE)
        for i in range(k_samples):
            idx = b_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                freq = 55.0 + 80.0 * math.exp(-t * 40.0)
                val = sine_wave(freq, t) * math.exp(-t * 22.0) * 0.45
                left[idx] += val * 0.5
                right[idx] += val * 0.5
        
        # Shimmering Tambourine Jingles (Брязкальця) on offbeat
        offbeat_idx = b_idx + int(eighth * SAMPLE_RATE)
        j_samples = int(0.08 * SAMPLE_RATE)
        for i in range(j_samples):
            idx = offbeat_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
                n = ((seed >> 16) & 0xFF) / 127.5 - 1.0
                j_env = math.exp(-t * 50.0)
                # Jingle ring
                ring = math.sin(2.0 * math.pi * 3200.0 * t) * 0.4
                val = (n * 0.6 + ring) * j_env * 0.18
                left[idx] += val * 0.7
                right[idx] += val * 0.3

    write_stereo("hopak_music.wav", left, right)

if __name__ == "__main__":
    generate_hopak_music()
    print("Ukrainian folk Hopak celebration music generated successfully!")
