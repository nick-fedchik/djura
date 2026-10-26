#!/usr/bin/env python3
import math
import struct
import wave
import os

SAMPLE_RATE = 44100
OUT_DIR = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio"))

def write_wav_stereo(filename, left_samples, right_samples, sample_rate=SAMPLE_RATE):
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(2)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        raw_data = bytearray()
        n = min(len(left_samples), len(right_samples))
        for i in range(n):
            l = max(-1.0, min(1.0, left_samples[i]))
            r = max(-1.0, min(1.0, right_samples[i]))
            l_int = int(l * 32767.0)
            r_int = int(r * 32767.0)
            raw_data.extend(struct.pack("<hh", l_int, r_int))
        wav_file.writeframes(raw_data)
    print(f"Generated STEREO {filepath} ({n} stereo frames, {n/sample_rate:.2f}s)")

# --- SYNTHESIS PRIMITIVES (80s Jarre Style) ---

def saw_wave(freq, t):
    if freq <= 0:
        return 0.0
    return 2.0 * (t * freq - math.floor(t * freq + 0.5))

def triangle_wave(freq, t):
    if freq <= 0:
        return 0.0
    period = 1.0 / freq
    phase = (t % period) / period
    return 4.0 * abs(phase - 0.5) - 1.0

def square_wave(freq, t, duty=0.5):
    if freq <= 0:
        return 0.0
    period = 1.0 / freq
    phase = (t % period) / period
    return 1.0 if phase < duty else -1.0

def sine_wave(freq, t):
    if freq <= 0:
        return 0.0
    return math.sin(2.0 * math.pi * freq * t)

# Pseudo-random noise
class NoiseGen:
    def __init__(self, seed=54321):
        self.state = seed
    def get(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return ((self.state >> 16) & 0xFF) / 127.5 - 1.0

def generate_jarre_bgm():
    # 124 BPM Jarre-esque space electronica (Oxygene IV / Equinoxe V homage)
    bpm = 124.0
    beat_dur = 60.0 / bpm
    sixteenth = beat_dur / 4.0
    num_measures = 16
    total_beats = num_measures * 4 # 64 beats
    total_sixteenths = total_beats * 4 # 256 sixteenth notes
    total_time = total_beats * beat_dur
    total_samples = int(SAMPLE_RATE * total_time)

    left = [0.0] * total_samples
    right = [0.0] * total_samples

    # 1. ARP BASS SEQUENCE (The iconic Oxygene-style driving analog sequencer)
    # A minor chord progression: Am -> F -> Dm -> G -> Em -> F -> Dm -> E
    chords_root = [
        # Measure 1-2: Am
        220.00 / 2, 220.00 / 2,
        # Measure 3-4: F
        174.61 / 2, 174.61 / 2,
        # Measure 5-6: Dm
        146.83 / 2, 146.83 / 2,
        # Measure 7-8: G -> E
        196.00 / 2, 164.81 / 2,
        # Measure 9-10: Am
        220.00 / 2, 220.00 / 2,
        # Measure 11-12: F
        174.61 / 2, 174.61 / 2,
        # Measure 13-14: Dm
        146.83 / 2, 146.83 / 2,
        # Measure 15-16: Em -> Emaj
        164.81 / 2, 164.81 / 2
    ]

    # Arp pattern offsets (semitones: Root, Octave, 5th, 8ve, 3rd, etc.)
    arp_intervals = [0, 12, 7, 12, 3, 7, 12, 7, 0, 12, 7, 12, 3, 7, 12, 15]

    for s in range(total_sixteenths):
        m_idx = s // 16 # which measure (0..15)
        root = chords_root[m_idx]
        note_offset = arp_intervals[s % 16]
        freq = root * (2.0 ** (note_offset / 12.0))
        
        start_idx = int(s * sixteenth * SAMPLE_RATE)
        note_samples = int(sixteenth * SAMPLE_RATE)
        
        # Panning ping-pong every 2 sixteenths
        pan_left = 0.75 if (s % 4 < 2) else 0.25
        pan_right = 1.0 - pan_left

        for i in range(note_samples):
            idx = start_idx + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                # Resonant filter decay envelope (Plucky analog sound)
                env = math.exp(-t * 22.0)
                # Blend of Saw + Triangle (Eminent/ARP style)
                v = (saw_wave(freq, t) * 0.6 + triangle_wave(freq, t) * 0.4) * env * 0.22
                left[idx] += v * pan_left
                right[idx] += v * pan_right

    # 2. EMINENT 310 STRING CHORD PADS (Phased analog string ensemble)
    chord_triads = [
        # Measures 1-2: Am (A3, C4, E4)
        [220.0, 261.63, 329.63], [220.0, 261.63, 329.63],
        # Measures 3-4: F (F3, A3, C4)
        [174.61, 220.0, 261.63], [174.61, 220.0, 261.63],
        # Measures 5-6: Dm (D3, F3, A3)
        [146.83, 174.61, 220.0], [146.83, 174.61, 220.0],
        # Measures 7-8: G (G3, B3, D4) -> E7 (E3, G#3, B3)
        [196.0, 246.94, 293.66], [164.81, 207.65, 246.94],
        # Measures 9-10: Am
        [220.0, 261.63, 329.63], [220.0, 261.63, 329.63],
        # Measures 11-12: F
        [174.61, 220.0, 261.63], [174.61, 220.0, 261.63],
        # Measures 13-14: Dm
        [146.83, 174.61, 220.0], [146.83, 174.61, 220.0],
        # Measures 15-16: Em -> Emaj
        [164.81, 196.00, 246.94], [164.81, 207.65, 246.94]
    ]

    meas_dur = beat_dur * 4.0
    for m in range(num_measures):
        triad = chord_triads[m]
        start_idx = int(m * meas_dur * SAMPLE_RATE)
        m_samples = int(meas_dur * SAMPLE_RATE)
        for i in range(m_samples):
            idx = start_idx + i
            if idx < total_samples:
                global_t = idx / SAMPLE_RATE
                local_t = i / SAMPLE_RATE
                # Smooth swell envelope
                fade_in = min(1.0, local_t / 0.25)
                fade_out = min(1.0, (meas_dur - local_t) / 0.25)
                env = fade_in * fade_out * 0.11
                # Smallphaser slow LFO modulation (0.28 Hz)
                phase_lfo = math.sin(global_t * 2.0 * math.pi * 0.28)
                chord_val_l = 0.0
                chord_val_r = 0.0
                for note in triad:
                    # Detuned oscillators for rich lush string shimmer
                    osc1 = saw_wave(note * 1.002, local_t)
                    osc2 = saw_wave(note * 0.998, local_t)
                    osc3 = triangle_wave(note * 1.000, local_t)
                    mix = (osc1 + osc2 + osc3) * 0.33
                    chord_val_l += mix * (1.0 + phase_lfo * 0.4)
                    chord_val_r += mix * (1.0 - phase_lfo * 0.4)
                left[idx] += chord_val_l * env * 0.5
                right[idx] += chord_val_r * env * 0.5

    # 3. KORG MINI-POPS RHYTHM (Classic vintage analog beat)
    noise_gen = NoiseGen(seed=98765)
    for b in range(total_beats):
        beat_start = int(b * beat_dur * SAMPLE_RATE)
        beat_in_meas = b % 4

        # Bass Drum on 1 & 3 (Soft rounded 80s kick)
        if beat_in_meas == 0 or beat_in_meas == 2:
            kick_dur = 0.12
            k_samples = int(kick_dur * SAMPLE_RATE)
            for i in range(k_samples):
                idx = beat_start + i
                if idx < total_samples:
                    t = i / SAMPLE_RATE
                    # Pitch drops 120 -> 48 Hz
                    freq = 48.0 + 72.0 * math.exp(-t * 35.0)
                    k_env = math.exp(-t * 24.0)
                    kv = sine_wave(freq, t) * k_env * 0.32
                    left[idx] += kv * 0.5
                    right[idx] += kv * 0.5

        # Snare / Rimshot on 2 & 4
        if beat_in_meas == 1 or beat_in_meas == 3:
            snare_dur = 0.09
            s_samples = int(snare_dur * SAMPLE_RATE)
            for i in range(s_samples):
                idx = beat_start + i
                if idx < total_samples:
                    t = i / SAMPLE_RATE
                    n = noise_gen.get()
                    s_env = math.exp(-t * 38.0)
                    body = sine_wave(210.0, t) * math.exp(-t * 45.0) * 0.25
                    sv = (n * 0.75 + body) * s_env * 0.22
                    left[idx] += sv * 0.5
                    right[idx] += sv * 0.5

    # Guiro / Hi-hat 16th groove (Minipops signature shuffle)
    for s in range(total_sixteenths):
        s_start = int(s * sixteenth * SAMPLE_RATE)
        h_dur = 0.03
        h_samples = int(h_dur * SAMPLE_RATE)
        accent = 1.3 if (s % 4 == 2) else 0.75
        pan_l = 0.65 if (s % 2 == 0) else 0.35
        pan_r = 1.0 - pan_l
        for i in range(h_samples):
            idx = s_start + i
            if idx < total_samples:
                t = i / SAMPLE_RATE
                n = noise_gen.get()
                h_env = math.exp(-t * 110.0)
                hv = n * h_env * 0.08 * accent
                left[idx] += hv * pan_l
                right[idx] += hv * pan_r

    # 4. LYRICAL SOARING LEAD MELODY (Whistling Moog / Solina lead with delay & vibrato)
    # Enters at measure 1 through 16 with a dreamy, memorable theme
    melody_events = [
        # Measure 1-2: A minor theme
        (220.0 * 2, 4), (261.63 * 2, 4), (293.66 * 2, 4), (329.63 * 2, 4),
        (392.00 * 2, 4), (329.63 * 2, 4), (293.66 * 2, 4), (261.63 * 2, 4),
        # Measure 3-4: F theme
        (349.23 * 2, 6), (329.63 * 2, 2), (293.66 * 2, 4), (261.63 * 2, 4),
        (220.00 * 2, 8), (246.94 * 2, 4), (261.63 * 2, 4),
        # Measure 5-6: Dm theme (soaring higher)
        (293.66 * 2, 4), (349.23 * 2, 4), (440.00 * 2, 6), (392.00 * 2, 2),
        (349.23 * 2, 4), (329.63 * 2, 4), (293.66 * 2, 8),
        # Measure 7-8: G -> E turnaround
        (392.00 * 2, 4), (329.63 * 2, 4), (293.66 * 2, 4), (246.94 * 2, 4),
        (329.63 * 2, 10), (0, 6),
        # Measure 9-10: Climax Variation
        (440.00 * 2, 4), (392.00 * 2, 2), (440.00 * 2, 2), (523.25 * 2, 4), (440.00 * 2, 4),
        (392.00 * 2, 4), (329.63 * 2, 4), (293.66 * 2, 4), (261.63 * 2, 4),
        # Measure 11-12: Gentle Descent
        (349.23 * 2, 6), (392.00 * 2, 2), (349.23 * 2, 4), (329.63 * 2, 4),
        (293.66 * 2, 6), (261.63 * 2, 2), (220.00 * 2, 8),
        # Measure 13-14: Poetic resolution
        (261.63 * 2, 4), (293.66 * 2, 4), (329.63 * 2, 4), (392.00 * 2, 4),
        (349.23 * 2, 4), (329.63 * 2, 4), (293.66 * 2, 8),
        # Measure 15-16: Soft landing into loop
        (246.94 * 2, 4), (261.63 * 2, 4), (293.66 * 2, 4), (246.94 * 2, 4),
        (220.00 * 2, 12), (0, 4)
    ]

    curr_sixteenth = 0
    for freq, num_sixteenths in melody_events:
        dur = num_sixteenths * sixteenth
        n_samples = int(dur * SAMPLE_RATE)
        start_idx = int(curr_sixteenth * sixteenth * SAMPLE_RATE)

        if freq > 0:
            for i in range(n_samples):
                idx = start_idx + i
                if idx < total_samples:
                    t = i / SAMPLE_RATE
                    # Attack & release envelope
                    att = min(1.0, t / 0.05)
                    rel = min(1.0, (dur - t) / 0.06)
                    env = att * rel * 0.28
                    
                    # Singing vibrato after 0.12s
                    vib_amp = min(0.02, max(0.0, (t - 0.12) * 0.04))
                    vib = math.sin(t * 2.0 * math.pi * 5.4) * vib_amp
                    mod_freq = freq * (1.0 + vib)
                    
                    # Warm pulse lead + sine body
                    lead_val = (square_wave(mod_freq, t, duty=0.42) * 0.6 + sine_wave(mod_freq, t) * 0.4) * env
                    
                    # Direct sound (Center-Left)
                    left[idx] += lead_val * 0.65
                    right[idx] += lead_val * 0.45
                    
                    # Stereo Tape Delay / Space Echo (0.18s later on the right)
                    delay_idx = idx + int(0.18 * SAMPLE_RATE)
                    if delay_idx < total_samples:
                        echo_val = lead_val * 0.38
                        left[delay_idx] += echo_val * 0.25
                        right[delay_idx] += echo_val * 0.75

        curr_sixteenth += num_sixteenths

    write_wav_stereo("bgm_stage.wav", left, right)

if __name__ == "__main__":
    generate_jarre_bgm()
    print("New 80s Jean-Michel Jarre style space BGM created successfully!")
