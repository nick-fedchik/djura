#!/usr/bin/env python3
import math
import struct
import wave
import os

SAMPLE_RATE = 44100
OUT_DIR = "/home/mfedchyk/geek-jack/assets/audio"

def write_wav_mono(filename, samples, sample_rate=SAMPLE_RATE):
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        raw_data = bytearray()
        for s in samples:
            val = max(-1.0, min(1.0, s))
            int_val = int(val * 32767.0)
            raw_data.extend(struct.pack("<h", int_val))
        wav_file.writeframes(raw_data)
    print(f"Generated MONO {filepath} ({len(samples)} samples)")

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
    print(f"Generated STEREO {filepath} ({n} stereo frames)")

def square_wave(freq, t, duty=0.5):
    if freq <= 0:
        return 0.0
    period = 1.0 / freq
    phase = (t % period) / period
    return 1.0 if phase < duty else -1.0

def triangle_wave(freq, t):
    if freq <= 0:
        return 0.0
    period = 1.0 / freq
    phase = (t % period) / period
    return 4.0 * abs(phase - 0.5) - 1.0

def noise(seed):
    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    val = ((seed >> 16) & 0xFF) / 127.5 - 1.0
    return val, seed

# 1. JUMP
def generate_jump():
    duration = 0.16
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 240.0 + (progress ** 0.8) * 580.0
        env = (1.0 - progress) ** 0.7
        val = square_wave(freq, t, duty=0.4) * env * 0.45
        samples.append(val)
    write_wav_mono("jump.wav", samples)

# 2. FLAP
def generate_flap():
    duration = 0.07
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 380.0 + progress * 240.0
        env = (1.0 - progress) ** 0.5
        val = square_wave(freq, t, duty=0.3) * env * 0.35
        samples.append(val)
    write_wav_mono("flap.wav", samples)

# 3. DROP
def generate_drop():
    duration = 0.14
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 600.0 - progress * 420.0
        env = (1.0 - progress) ** 0.8
        val = square_wave(freq, t, duty=0.25) * env * 0.4
        samples.append(val)
    write_wav_mono("drop.wav", samples)

# 4. REGULAR BOMB COLLECT
def generate_bomb_regular():
    duration = 0.12
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        if t < 0.04:
            freq = 987.77 # B5
            env = 1.0 - (t / 0.04) * 0.2
        else:
            freq = 1318.51 # E6
            t2 = t - 0.04
            env = (1.0 - t2 / 0.08) ** 1.5
        val = square_wave(freq, t, duty=0.5) * env * 0.45
        samples.append(val)
    write_wav_mono("bomb_regular.wav", samples)

# 5. LIT BOMB COLLECT (BRIGHT SPARKLE CHIME)
def generate_bomb_lit():
    duration = 0.28
    total_samples = int(SAMPLE_RATE * duration)
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51] # C5, E5, G5, C6, E6
    samples = []
    note_len = 0.05
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        idx = min(int(t / note_len), len(notes) - 1)
        freq = notes[idx]
        note_t = t - (idx * note_len)
        env = max(0.0, 1.0 - note_t / (note_len * 1.5))
        val1 = square_wave(freq, t, duty=0.5)
        val2 = square_wave(freq * 1.008, t, duty=0.25)
        val = ((val1 + val2) * 0.5) * env * 0.5
        samples.append(val)
    write_wav_mono("bomb_lit.wav", samples)

# 6. LEVEL COMPLETE FANFARE (STEREO)
def generate_level_clear():
    notes = [
        (523.25, 0.10), # C5
        (659.25, 0.10), # E5
        (783.99, 0.10), # G5
        (1046.50, 0.18), # C6
        (783.99, 0.10), # G5
        (1046.50, 0.40)  # C6 sustained
    ]
    left = []
    right = []
    for freq, dur in notes:
        n_samples = int(SAMPLE_RATE * dur)
        for i in range(n_samples):
            t = i / SAMPLE_RATE
            env = max(0.0, (1.0 - (t / dur) * 0.5))
            lead_val = square_wave(freq, t, duty=0.5) * env * 0.45
            harm_val = square_wave(freq * 1.25, t, duty=0.25) * env * 0.25 # major third harmony
            bass_val = triangle_wave(freq * 0.5, t) * env * 0.35
            # Stereo spread: lead slightly left, harmony slightly right, bass center
            l = lead_val * 0.75 + harm_val * 0.25 + bass_val * 0.5
            r = lead_val * 0.25 + harm_val * 0.75 + bass_val * 0.5
            left.append(l)
            right.append(r)
    write_wav_stereo("level_clear.wav", left, right)

# 7. BGM: RICH 3-CHANNEL AY-3-8910 ARCADE STEREO CHIPTUNE
def generate_bgm_loop():
    bpm = 136.0
    beat_dur = 60.0 / bpm
    sixteenth = beat_dur / 4.0

    melody_notes = [
        # Measure 1
        (523.25, 2), (0, 1), (523.25, 1), (587.33, 2), (659.25, 2),
        (523.25, 2), (440.00, 2), (392.00, 4),
        # Measure 2
        (440.00, 2), (0, 1), (440.00, 1), (523.25, 2), (587.33, 2),
        (659.25, 4), (587.33, 4),
        # Measure 3
        (523.25, 2), (0, 1), (523.25, 1), (659.25, 2), (783.99, 2),
        (880.00, 4), (783.99, 4),
        # Measure 4
        (659.25, 2), (587.33, 2), (523.25, 2), (440.00, 2),
        (523.25, 6), (0, 2)
    ]

    bass_notes = [
        # Measure 1
        (261.63, 4), (196.00, 4), (220.00, 4), (164.81, 4),
        # Measure 2
        (220.00, 4), (174.61, 4), (196.00, 4), (246.94, 4),
        # Measure 3
        (261.63, 4), (329.63, 4), (349.23, 4), (392.00, 4),
        # Measure 4
        (329.63, 4), (293.66, 4), (261.63, 4), (196.00, 4)
    ]

    total_sixteenths = sum(dur for _, dur in melody_notes)
    total_time = total_sixteenths * sixteenth
    total_samples = int(SAMPLE_RATE * total_time)

    left_samples = [0.0] * total_samples
    right_samples = [0.0] * total_samples

    # Channel 1: Lead Melody (Square wave, Panned 30% Left)
    curr_sample = 0
    for freq, num_sixteenths in melody_notes:
        dur = num_sixteenths * sixteenth
        n_samples = int(SAMPLE_RATE * dur)
        for i in range(n_samples):
            idx = curr_sample + i
            if idx < total_samples and freq > 0:
                t = i / SAMPLE_RATE
                gate = 0.85
                env = 1.0 - (t / (dur * gate)) * 0.25 if (t / dur) < gate else 0.0
                # Subtle vibrato on longer notes
                vib = math.sin(t * 36.0) * 0.015 if num_sixteenths >= 4 else 0.0
                val = square_wave(freq * (1.0 + vib), t, duty=0.5) * env * 0.26
                left_samples[idx] += val * 0.75
                right_samples[idx] += val * 0.35
        curr_sample += n_samples

    # Channel 2: Harmony Arpeggio / Echo (Square wave duty 25%, Panned 30% Right)
    curr_sample = 0
    for freq, num_sixteenths in melody_notes:
        dur = num_sixteenths * sixteenth
        n_samples = int(SAMPLE_RATE * dur)
        for i in range(n_samples):
            idx = curr_sample + i
            if idx < total_samples and freq > 0:
                t = i / SAMPLE_RATE
                gate = 0.70
                env = 1.0 - (t / (dur * gate)) * 0.35 if (t / dur) < gate else 0.0
                harm_freq = freq * 0.5 # lower octave counter-melody
                val = square_wave(harm_freq, t, duty=0.25) * env * 0.20
                left_samples[idx] += val * 0.35
                right_samples[idx] += val * 0.75
        curr_sample += n_samples

    # Channel 3: Bass (Triangle wave, Solid Center 50% Left + 50% Right)
    curr_sample = 0
    for freq, num_sixteenths in bass_notes:
        dur = num_sixteenths * sixteenth
        n_samples = int(SAMPLE_RATE * dur)
        for i in range(n_samples):
            idx = curr_sample + i
            if idx < total_samples and freq > 0:
                t = i / SAMPLE_RATE
                gate = 0.82
                env = 1.0 - (t / (dur * gate)) * 0.2 if (t / dur) < gate else 0.0
                val = triangle_wave(freq, t) * env * 0.28
                left_samples[idx] += val * 0.55
                right_samples[idx] += val * 0.55
        curr_sample += n_samples

    # Channel 4: Stereo Percussive Hi-Hats / Snare Noise (Alternating L / R)
    seed = 12345
    for s in range(total_sixteenths):
        if s % 2 == 1:
            hat_start = int(s * sixteenth * SAMPLE_RATE)
            hat_dur = 0.035
            hat_samples = int(SAMPLE_RATE * hat_dur)
            pan_left = 0.8 if (s % 4 == 1) else 0.3
            pan_right = 1.0 - pan_left
            for i in range(hat_samples):
                idx = hat_start + i
                if idx < total_samples:
                    n_val, seed = noise(seed)
                    env = (1.0 - i / hat_samples) ** 2.2
                    val = n_val * env * 0.10
                    left_samples[idx] += val * pan_left
                    right_samples[idx] += val * pan_right

    write_wav_stereo("bgm_stage.wav", left_samples, right_samples)

if __name__ == "__main__":
    generate_jump()
    generate_flap()
    generate_drop()
    generate_bomb_regular()
    generate_bomb_lit()
    generate_level_clear()
    generate_bgm_loop()
    print("Stereo authentic 8-bit Bomb Jack audio assets generated successfully!")
