"""Builds the Cursed Survivors soundtrack + effects.

    python gen_audio.py ..

Effects: 44.1 kHz mono WAV in assets/audio/sfx
Music:   22.05 kHz mono WAV loops in assets/audio/music
"""

import math
import os
import sys

import numpy as np

import audio_lib as A

SR = A.SR_MUSIC


# ---------------------------------------------------------------- theory

def midi_hz(m):
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


CHORDS = {
    "min": (0, 3, 7),
    "maj": (0, 4, 7),
    "dim": (0, 3, 6),
    "sus": (0, 5, 7),
}


def chord_notes(root_midi, quality="min", octaves=1, extra=()):
    notes = []
    for o in range(octaves):
        for step in CHORDS[quality]:
            notes.append(root_midi + step + 12 * o)
    notes.extend(root_midi + e for e in extra)
    return notes


# ---------------------------------------------------------------- instruments

def pad(freq, dur, amp=0.3, detune=0.004, attack=0.35, release=0.5, bright=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for mult, w in ((1.0, 1.0), (2.0, 0.32 * bright), (3.0, 0.14 * bright),
                    (4.0, 0.07 * bright), (0.5, 0.25)):
        for d in (-detune, 0.0, detune):
            out += np.sin(2 * np.pi * freq * mult * (1.0 + d) * t) * w / 3.0
    env = A.env_adsr(n, SR, attack, 0.2, 0.75, release)
    return out * env * amp


def pluck(freq, dur, amp=0.5, decay=0.9):
    n = int(dur * SR)
    t = np.arange(n) / SR
    body = np.zeros(n)
    for mult, w in ((1.0, 1.0), (2.0, 0.5), (3.0, 0.28), (4.0, 0.14), (5.0, 0.08)):
        body += np.sin(2 * np.pi * freq * mult * t) * w
    env = A.env_ad(n, 0.004, dur * decay, SR, 3.0)
    return body * env * amp


def bass(freq, dur, amp=0.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * np.pi * freq * t) * 1.0
    body += np.sin(2 * np.pi * freq * 2 * t) * 0.35
    body += np.sin(2 * np.pi * freq * 3 * t) * 0.12
    body = np.tanh(body * 1.4)
    env = A.env_adsr(n, SR, 0.008, 0.12, 0.6, 0.08)
    return body * env * amp


def drum_kick(amp=0.9):
    dur = 0.42
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = 105.0 * np.exp(-t * 26.0) + 42.0
    body = np.sin(2 * np.pi * np.cumsum(f) / SR)
    click = A.bandpass(A.noise(dur, SR), 1200.0, 6000.0, SR) * A.env_ad(n, 0.0, 0.02, SR) * 0.3
    env = A.env_ad(n, 0.002, 0.30, SR, 2.0)
    return (body * env + click) * amp


def drum_snare(amp=0.5):
    dur = 0.28
    n = int(dur * SR)
    noise = A.bandpass(A.noise(dur, SR), 900.0, 7000.0, SR)
    noise *= A.env_ad(n, 0.001, 0.16, SR, 2.2)
    tone = np.sin(2 * np.pi * 190.0 * np.arange(n) / SR) * A.env_ad(n, 0.001, 0.08, SR) * 0.4
    return (noise * 0.8 + tone) * amp


def drum_hat(amp=0.22):
    dur = 0.09
    n = int(dur * SR)
    noise = A.highpass(A.noise(dur, SR), 6500.0, SR)
    return noise * A.env_ad(n, 0.0, 0.05, SR) * amp


def timpani(amp=0.7):
    dur = 0.9
    n = int(dur * SR)
    t = np.arange(n) / SR
    body = np.zeros(n)
    for f, w in ((73.4, 1.0), (110.0, 0.4), (146.8, 0.2), (220.0, 0.1)):
        body += np.sin(2 * np.pi * f * t) * w
    env = A.env_ad(n, 0.004, 0.75, SR, 1.8)
    return body * env * amp


def wind(dur, amp=0.12):
    n = int(dur * SR)
    t = np.arange(n) / SR
    noise = A.bandpass(A.noise(dur, SR), 220.0, 1400.0, SR)
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.07 * t + 1.3)
    lfo2 = 0.6 + 0.4 * np.sin(2 * np.pi * 0.031 * t)
    return noise * lfo * lfo2 * amp


def rumble(dur, amp=0.16):
    n = int(dur * SR)
    t = np.arange(n) / SR
    noise = A.lowpass(A.noise(dur, SR), 120.0, SR, 2)
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * 0.05 * t)
    return noise * swell * amp


# ---------------------------------------------------------------- sequencer

class Track:
    def __init__(self, bpm, bars):
        self.bpm = bpm
        self.bars = bars
        self.beat = 60.0 / bpm
        self.length = self.bars * 4 * self.beat
        self.buf = np.zeros(int(self.length * SR) + SR, dtype=np.float64)

    def add(self, sig, at, gain=1.0):
        i = int(at * SR)
        if i < 0 or i >= self.buf.size:
            return
        j = min(self.buf.size, i + sig.size)
        self.buf[i:j] += sig[:j - i] * gain

    def note(self, midi, at, dur, inst="pluck", gain=1.0, **kw):
        freq = midi_hz(midi)
        if inst == "pluck":
            sig = pluck(freq, dur, **kw)
        elif inst == "pad":
            sig = pad(freq, dur, **kw)
        elif inst == "bass":
            sig = bass(freq, dur, **kw)
        elif inst == "bell":
            sig = A.bell(freq, dur, SR, **kw)
        else:
            sig = pluck(freq, dur, **kw)
        self.add(sig, at, gain)

    def render(self, wet=0.34, loop_crossfade=0.6):
        total = int(self.length * SR)
        out = self.buf[:total].copy()
        tail = self.buf[total:total + int(1.5 * SR)]
        out[:tail.size] += tail[:total] if tail.size else 0
        out = A.reverb(out, SR, wet=wet)
        cf = int(loop_crossfade * SR)
        if cf > 0 and out.size > cf * 3:
            head = out[:cf].copy()
            tailp = out[-cf:]
            ramp = np.linspace(0.0, 1.0, cf)
            out[:cf] = head * ramp + tailp * (1.0 - ramp)
            out = out[:-cf]
        return out


def arp(track, root, quality, bar_start, pattern, inst="pluck", gain=0.4,
        octave=12, step=0.25, **kw):
    notes = chord_notes(root + octave, quality, 1)
    for i, idx in enumerate(pattern):
        at = bar_start + i * track.beat * step
        if idx is None:
            continue
        track.note(notes[idx % len(notes)], at, track.beat * step * 2.2,
                   inst=inst, gain=gain, **kw)


def drums(track, bar_start, style="soft", gain=1.0):
    b = track.beat
    if style == "soft":
        track.add(drum_kick(0.55 * gain), bar_start + 0 * b)
        track.add(drum_kick(0.35 * gain), bar_start + 2 * b)
        track.add(drum_hat(0.14 * gain), bar_start + 1 * b)
        track.add(drum_hat(0.14 * gain), bar_start + 3 * b)
    elif style == "drive":
        for i in range(4):
            track.add(drum_kick(0.8 * gain), bar_start + i * b)
        track.add(drum_snare(0.5 * gain), bar_start + 1 * b)
        track.add(drum_snare(0.5 * gain), bar_start + 3 * b)
        for i in range(8):
            track.add(drum_hat(0.16 * gain), bar_start + i * b * 0.5)
    elif style == "boss":
        for i in range(4):
            track.add(drum_kick(0.95 * gain), bar_start + i * b)
            track.add(drum_kick(0.35 * gain), bar_start + i * b + b * 0.5)
        track.add(drum_snare(0.6 * gain), bar_start + 1 * b)
        track.add(drum_snare(0.6 * gain), bar_start + 3 * b)
        for i in range(16):
            track.add(drum_hat(0.10 * gain), bar_start + i * b * 0.25)
        track.add(timpani(0.5 * gain), bar_start + 0 * b)
        track.add(timpani(0.35 * gain), bar_start + 2.5 * b)


def pad_bars(track, prog, gain=0.26, attack=0.6, bright=1.0, octave=-12):
    for i, (root, quality) in enumerate(prog):
        at = i * 4 * track.beat
        for m in chord_notes(root + octave, quality, 2):
            track.note(m, at, 4 * track.beat * 0.98, inst="pad", gain=gain,
                       attack=attack, bright=bright)


def bass_bars(track, prog, gain=0.4, pattern=(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5)):
    for i, (root, quality) in enumerate(prog):
        base = i * 4 * track.beat
        for p in pattern:
            track.note(root - 12, base + p * track.beat, track.beat * 0.42,
                       inst="bass", gain=gain)


def bells(track, prog, every=2, gain=0.3, octave=0, high=False):
    for i, (root, quality) in enumerate(prog):
        if i % every:
            continue
        m = root + (12 if high else 0)
        track.note(m, i * 4 * track.beat, track.beat * 6, inst="bell", gain=gain)


# ---------------------------------------------------------------- tracks

MENU_PROG = [(50, "min"), (46, "maj"), (43, "min"), (45, "maj")]
GRAVE_PROG = [(50, "min"), (46, "maj"), (46, "maj"), (45, "maj")]
GRAVE_HOT = [(50, "min"), (46, "maj"), (43, "min"), (45, "maj")]
DEPTH_PROG = [(48, "min"), (44, "maj"), (51, "maj"), (46, "maj")]
DEPTH_HOT = [(48, "min"), (44, "maj"), (41, "min"), (43, "maj")]
BOSS_PROG = [(50, "min"), (50, "min"), (46, "maj"), (45, "maj")]


def music_menu():
    tr = Track(72, 8)
    prog = MENU_PROG * 2
    pad_bars(tr, prog, gain=0.30, attack=1.2, bright=0.7, octave=-24)
    bells(tr, prog, every=2, gain=0.34, high=True)
    for i in range(8):
        bar = i * 4 * tr.beat
        pattern = (0, 3, 2, 1, 3, None, 2, 0)
        arp(tr, prog[i][0], prog[i][1], bar, pattern, gain=0.16, step=0.5)
    tr.add(wind(tr.length, 0.07), 0.0)
    return tr.render(wet=0.46)


def music_graveyard(intense=False):
    tr = Track(100 if intense else 82, 8)
    prog = (GRAVE_HOT if intense else GRAVE_PROG) * 2
    pad_bars(tr, prog, gain=0.20 if intense else 0.26,
             attack=0.4 if intense else 0.9, bright=1.15 if intense else 0.8,
             octave=-24)
    bells(tr, prog, every=4 if intense else 2, gain=0.22, high=False)
    for i in range(8):
        bar = i * 4 * tr.beat
        if intense:
            arp(tr, prog[i][0], prog[i][1], bar, (0, 1, 2, 3, 2, 1, 2, 3),
                gain=0.20, step=0.25)
        else:
            arp(tr, prog[i][0], prog[i][1], bar, (0, None, 2, None, 1, None, 3, None),
                gain=0.17, step=0.5)
        drums(tr, bar, "drive" if intense else "soft", gain=1.0 if intense else 0.7)
    if intense:
        bass_bars(tr, prog, gain=0.34)
    else:
        bass_bars(tr, prog, gain=0.18, pattern=(0, 2))
    tr.add(wind(tr.length, 0.10 if intense else 0.09), 0.0)
    return tr.render(wet=0.34 if intense else 0.44)


def music_depths(intense=False):
    tr = Track(104 if intense else 68, 8)
    prog = (DEPTH_HOT if intense else DEPTH_PROG) * 2
    pad_bars(tr, prog, gain=0.22 if intense else 0.28,
             attack=0.5 if intense else 1.4, bright=1.3 if intense else 0.6,
             octave=-24)
    for i in range(8):
        bar = i * 4 * tr.beat
        if intense:
            arp(tr, prog[i][0], prog[i][1], bar, (0, 2, 1, 3, 0, 2, 3, 1),
                gain=0.20, step=0.25, octave=0)
            drums(tr, bar, "drive", gain=1.05)
        else:
            arp(tr, prog[i][0], prog[i][1], bar, (0, None, None, 2, None, None, 1, None),
                gain=0.14, step=0.5, octave=0)
    bells(tr, prog, every=4, gain=0.24, high=True)
    bass_bars(tr, prog, gain=0.36 if intense else 0.22,
              pattern=(0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75,
                       3, 3.25, 3.5, 3.75) if intense else (0, 1.5, 2, 3.5))
    tr.add(rumble(tr.length, 0.22 if intense else 0.16), 0.0)
    return tr.render(wet=0.30 if intense else 0.40)


def music_boss():
    tr = Track(94, 8)
    prog = BOSS_PROG * 2
    pad_bars(tr, prog, gain=0.28, attack=0.25, bright=1.5, octave=-24)
    for i in range(8):
        bar = i * 4 * tr.beat
        drums(tr, bar, "boss", gain=1.0)
        arp(tr, prog[i][0], prog[i][1], bar, (0, 1, 2, 3, 2, 1, 0, 1),
            gain=0.18, step=0.25, octave=12)
    bass_bars(tr, prog, gain=0.42, pattern=(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5))
    for i in (0, 4):
        tr.note(prog[i][0] + 6, i * 4 * tr.beat, tr.beat * 3, inst="bell", gain=0.3)
    tr.add(rumble(tr.length, 0.12), 0.0)
    return tr.render(wet=0.30)


MUSIC = {
    "menu": music_menu,
    "graveyard_calm": lambda: music_graveyard(False),
    "graveyard_intense": lambda: music_graveyard(True),
    "depths_calm": lambda: music_depths(False),
    "depths_intense": lambda: music_depths(True),
    "boss": music_boss,
}


def make_all(root=".."):
    sfx_dir = os.path.join(root, "assets", "audio", "sfx")
    music_dir = os.path.join(root, "assets", "audio", "music")
    os.makedirs(sfx_dir, exist_ok=True)
    os.makedirs(music_dir, exist_ok=True)

    for name, fn in A.SFX.items():
        sig = fn()
        A.save_wav(os.path.join(sfx_dir, name + ".wav"), sig, A.SR_SFX, peak=0.85)
        print("  sfx", name, "%.2fs" % (len(sig) / A.SR_SFX))

    for name, fn in MUSIC.items():
        sig = fn()
        A.save_wav(os.path.join(music_dir, name + ".wav"), sig, SR, peak=0.72)
        print("  music", name, "%.1fs" % (len(sig) / SR))

    print("audio done")


if __name__ == "__main__":
    make_all(sys.argv[1] if len(sys.argv) > 1 else "..")