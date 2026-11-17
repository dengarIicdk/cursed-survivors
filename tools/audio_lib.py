"""Procedural gothic sound design for Cursed Survivors.

Everything is synthesised from scratch (no third-party samples), so the
whole soundtrack stays original and licence-free.

    python gen_audio.py ..

Writes 44.1 kHz mono WAV effects to assets/audio/sfx and 22.05 kHz mono
music loops to assets/audio/music.
"""

import math
import os
import sys
import wave

import numpy as np

SR_SFX = 44100
SR_MUSIC = 22050

RNG = np.random.default_rng(2024)


# ---------------------------------------------------------------- helpers

def t_axis(dur, sr):
    return np.arange(int(dur * sr), dtype=np.float64) / sr


def sine(freq, dur, sr, phase=0.0):
    t = t_axis(dur, sr)
    return np.sin(2.0 * np.pi * freq * t + phase)


def sweep(f0, f1, dur, sr, curve=1.0):
    t = t_axis(dur, sr)
    k = np.linspace(0.0, 1.0, t.size) ** curve
    phase = 2.0 * np.pi * np.cumsum(f0 + (f1 - f0) * k) / sr
    return np.sin(phase)


def noise(dur, sr):
    return RNG.uniform(-1.0, 1.0, int(dur * sr))


def env_ad(n, attack, decay, sr, curve=2.0):
    """Attack/decay envelope over n samples."""
    a = max(1, int(attack * sr))
    d = max(1, int(decay * sr))
    total = max(a + d, n)
    e = np.zeros(total)
    e[:a] = np.linspace(0.0, 1.0, a) ** 0.6
    e[a:a + d] = np.linspace(1.0, 0.0, d) ** curve
    if total < n:
        e = np.pad(e, (0, n - total))
    return e[:n]


def env_adsr(n, sr, attack=0.01, decay=0.1, sustain=0.6, release=0.2):
    a = int(attack * sr)
    d = int(decay * sr)
    r = int(release * sr)
    s = max(0, n - a - d - r)
    parts = [
        np.linspace(0.0, 1.0, a, endpoint=False) if a else np.array([]),
        np.linspace(1.0, sustain, d, endpoint=False) if d else np.array([]),
        np.full(s, sustain),
        np.linspace(sustain, 0.0, r) if r else np.array([]),
    ]
    e = np.concatenate(parts)
    if e.size < n:
        e = np.pad(e, (0, n - e.size))
    return e[:n]


def lowpass(x, cutoff, sr, order=2):
    """One-pole cascade lowpass (cheap, vectorised with a python loop)."""
    if cutoff >= sr / 2.0:
        return x
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff / sr)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    for _ in range(order - 1):
        acc = 0.0
        for i in range(y.size):
            acc += alpha * (y[i] - acc)
            y[i] = acc
    return y


def highpass(x, cutoff, sr):
    return x - lowpass(x, cutoff, sr, 1)


def bandpass(x, lo, hi, sr):
    return lowpass(highpass(x, lo, sr), hi, sr, 2)


def reverb(x, sr, taps=((0.031, 0.55), (0.057, 0.42), (0.089, 0.33),
                        (0.131, 0.26), (0.197, 0.18), (0.263, 0.12)),
           wet=0.32):
    """Cheap multi-tap reverb with a touch of damping."""
    out = x.copy()
    for delay, gain in taps:
        d = int(delay * sr)
        if d <= 0 or d >= x.size:
            continue
        tail = lowpass(x[:-d], 4200.0, sr, 1) * gain
        out[d:] += tail
    peak = np.max(np.abs(out)) or 1.0
    out = out / peak * max(1.0, np.max(np.abs(x)))
    return x * (1.0 - wet) + out * wet


def normalise(x, peak=0.9):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def fade(x, sr, attack=0.004, release=0.02):
    a = max(1, int(attack * sr))
    r = max(1, int(release * sr))
    x = x.copy()
    x[:a] *= np.linspace(0.0, 1.0, a)
    x[-r:] *= np.linspace(1.0, 0.0, r)
    return x


def save_wav(path, x, sr, peak=0.9):
    x = normalise(np.nan_to_num(x), peak)
    if x.size < 2:
        return
    data = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sr)
        f.writeframes(data.tobytes())


# ---------------------------------------------------------------- sfx

def sfx_hit(dur=0.13, sr=SR_SFX):
    n = int(dur * sr)
    body = lowpass(noise(dur, sr), 2600.0, sr, 2) * env_ad(n, 0.001, 0.09, sr)
    crunch = bandpass(noise(dur, sr), 700.0, 5200.0, sr) * env_ad(n, 0.0, 0.035, sr) * 0.5
    thump = sine(78.0, dur, sr) * env_ad(n, 0.002, 0.07, sr) * 0.9
    return fade(body * 0.8 + crunch + thump, sr)


def sfx_hit_heavy(dur=0.34, sr=SR_SFX):
    n = int(dur * sr)
    low = sine(52.0, dur, sr) * env_ad(n, 0.004, 0.26, sr, 2.4)
    body = lowpass(noise(dur, sr), 1500.0, sr, 2) * env_ad(n, 0.001, 0.16, sr) * 0.8
    ring = sum(sine(f, dur, sr) * env_ad(n, 0.0, 0.12, sr, 3.0) * a
               for f, a in ((418.0, 0.22), (631.0, 0.16), (947.0, 0.10)))
    return fade(reverb(low + body + ring, sr, wet=0.2), sr)


def sfx_orb_hit(dur=0.16, sr=SR_SFX):
    n = int(dur * sr)
    zap = sweep(1250.0, 320.0, dur, sr, 0.7) * env_ad(n, 0.002, 0.12, sr)
    air = bandpass(noise(dur, sr), 1800.0, 7000.0, sr) * env_ad(n, 0.0, 0.05, sr) * 0.35
    return fade(zap * 0.7 + air, sr)


def sfx_lightning(dur=0.42, sr=SR_SFX):
    n = int(dur * sr)
    crackle = bandpass(noise(dur, sr), 1200.0, 9000.0, sr)
    stopper = np.zeros(n)
    for _ in range(7):
        p = RNG.integers(0, max(1, n - 400))
        ln = RNG.integers(120, 900)
        stopper[p:p + ln] += RNG.uniform(0.5, 1.0)
    crackle *= stopper
    boom = sine(60.0, dur, sr) * env_ad(n, 0.002, 0.2, sr) * 0.7
    return fade(reverb(crackle * 0.8 + boom, sr, wet=0.3), sr)


def bell(freq, dur, sr, amp=0.6, decay=1.0):
    n = int(dur * sr)
    partials = ((1.0, 1.0), (2.01, 0.55), (2.98, 0.32), (4.21, 0.18), (5.43, 0.10))
    out = np.zeros(n)
    for mult, a in partials:
        d = dur * (0.85 / (1.0 + 0.12 * mult)) * decay
        e = env_ad(n, 0.003, min(0.98, d), sr, 2.6)
        out += sine(freq * mult, dur, sr) * e * a
    return out * amp


def sfx_xp_pickup(sr=SR_SFX, base=1180.0):
    dur = 0.22
    n = int(dur * sr)
    tone = bell(base, dur, sr, 0.55, 0.8)
    spark = sweep(base * 1.9, base * 2.4, dur * 0.5, sr) * env_ad(n // 2, 0.001, 0.08, sr) * 0.25
    out = tone.copy()
    out[:spark.size] += spark
    return fade(reverb(out, sr, wet=0.22), sr)


def sfx_coin(sr=SR_SFX):
    dur = 0.3
    a = sfx_xp_pickup(sr, 1560.0)
    b = sfx_xp_pickup(sr, 2080.0)
    out = np.zeros(int(dur * sr))
    out[:a.size] += a
    shift = int(0.06 * sr)
    out[shift:shift + b.size] += b * 0.7
    return fade(out, sr)


def sfx_heart(sr=SR_SFX):
    dur = 0.5
    n = int(dur * sr)
    warm = (sine(196.0, dur, sr) + sine(294.0, dur, sr) * 0.5
            + sine(392.0, dur, sr) * 0.3) * env_adsr(n, sr, 0.01, 0.08, 0.45, 0.3)
    return fade(reverb(warm * 0.6, sr, wet=0.35), sr)


def sfx_level_up(sr=SR_SFX):
    dur = 1.35
    n = int(dur * sr)
    notes = (293.66, 349.23, 440.00, 587.33, 698.46)   # D minor add9 rise
    out = np.zeros(n)
    step = int(0.085 * sr)
    for i, f in enumerate(notes):
        seg = int((dur - i * 0.085) * sr)
        t = np.arange(seg) / sr
        tone = np.zeros(seg)
        for mult, a in ((1.0, 1.0), (2.0, 0.45), (3.0, 0.22), (4.0, 0.12)):
            tone += np.sin(2 * np.pi * f * mult * t) * a
        tone *= env_adsr(seg, sr, 0.01, 0.12, 0.35, 0.55)
        out[i * step:i * step + min(seg, n - i * step)] += tone[:n - i * step] * (0.6 - i * 0.06)
    out += bell(587.33, dur, sr, 0.35, 1.2) * 0.5
    return fade(reverb(out, sr, wet=0.3), sr, 0.006, 0.15)


def sfx_evolve(sr=SR_SFX):
    dur = 2.2
    n = int(dur * sr)
    rise = np.zeros(n)
    ris = sweep(120.0, 880.0, dur * 0.8, sr, 1.6)
    rise[:ris.size] = ris * env_adsr(ris.size, sr, 0.3, 0.2, 0.6, 0.3)
    rise *= 0.45
    choir = np.zeros(n)
    for f in (146.83, 220.0, 293.66, 440.0):
        seg = sine(f, dur, sr) * 0.22
        seg *= env_adsr(n, sr, 0.4, 0.3, 0.5, 0.7)
        choir += seg
    toll = bell(146.83, dur, sr, 0.55, 1.6)
    out = rise + choir + toll
    return fade(reverb(out, sr, wet=0.42), sr, 0.01, 0.25)


def sfx_enemy_die(sr=SR_SFX):
    dur = 0.26
    n = int(dur * sr)
    squish = lowpass(noise(dur, sr), 1800.0, sr, 2) * env_ad(n, 0.001, 0.14, sr)
    drop = sweep(320.0, 70.0, dur, sr, 0.8) * env_ad(n, 0.002, 0.18, sr) * 0.7
    rattle = bandpass(noise(dur, sr), 2500.0, 6500.0, sr) * env_ad(n, 0.03, 0.1, sr) * 0.2
    return fade(squish * 0.7 + drop + rattle, sr)


def sfx_boss_die(sr=SR_SFX):
    dur = 3.0
    n = int(dur * sr)
    boom = sine(38.0, dur, sr) * env_ad(n, 0.01, 1.6, sr, 1.8) * 1.2
    rumble = lowpass(noise(dur, sr), 240.0, sr, 2) * env_ad(n, 0.05, 2.2, sr) * 0.9
    out = boom + rumble
    for i, f in enumerate((73.42, 110.0, 146.83)):
        toll = bell(f, dur - i * 0.1, sr, 0.5, 1.8)
        out[:toll.size] += toll * 0.8
    return fade(reverb(out, sr, wet=0.45), sr, 0.01, 0.4)


def sfx_player_die(sr=SR_SFX):
    dur = 2.6
    n = int(dur * sr)
    out = np.zeros(n)
    for i, f in enumerate((220.0, 174.61, 146.83, 110.0)):
        seg = sine(f, dur - i * 0.18, sr) * env_adsr(n - int(i * 0.18 * sr), sr,
                                                     0.02, 0.25, 0.4, 0.6) * (0.6 - i * 0.08)
        s0 = int(i * 0.18 * sr)
        out[s0:s0 + seg.size] += seg
    drum = sine(44.0, dur, sr) * env_ad(n, 0.005, 1.5, sr, 1.6) * 0.9
    return fade(reverb(out + drum, sr, wet=0.4), sr, 0.01, 0.5)


def sfx_blink(sr=SR_SFX):
    dur = 0.24
    n = int(dur * sr)
    whoosh = bandpass(noise(dur, sr), 600.0, 6500.0, sr) * env_adsr(n, sr, 0.05, 0.05, 0.4, 0.1)
    tone = sweep(720.0, 190.0, dur, sr, 1.2) * env_ad(n, 0.005, 0.16, sr) * 0.4
    return fade(whoosh + tone, sr)


def sfx_surge(sr=SR_SFX):
    dur = 0.85
    n = int(dur * sr)
    rising = sweep(90.0, 1400.0, dur, sr, 1.5) * env_adsr(n, sr, 0.15, 0.1, 0.5, 0.2) * 0.5
    buzz = np.sign(np.sin(2 * np.pi * sweep(160.0, 620.0, dur, sr) * t_axis(dur, sr))) * 0.18
    crack = bandpass(noise(dur, sr), 2000.0, 10000.0, sr) * env_ad(n, 0.2, 0.5, sr) * 0.4
    return fade(reverb(rising + lowpass(buzz, 3000.0, sr, 1) + crack, sr, wet=0.25), sr)


def sfx_last_stand(sr=SR_SFX):
    dur = 1.2
    n = int(dur * sr)
    horn = np.zeros(n)
    for f in (73.42, 110.0, 146.83, 220.0):
        horn += np.sin(2 * np.pi * f * t_axis(dur, sr)) * 0.3
    horn *= env_adsr(n, sr, 0.06, 0.2, 0.5, 0.45)
    horn = np.tanh(horn * 1.8) * 0.7
    return fade(reverb(horn + bell(110.0, dur, sr, 0.4, 1.2), sr, wet=0.35), sr)


def sfx_boss_spawn(sr=SR_SFX):
    dur = 2.4
    n = int(dur * sr)
    roar = np.zeros(n)
    for f, a in ((55.0, 1.0), (82.5, 0.6), (110.0, 0.45), (164.0, 0.25)):
        vibrato = np.sin(2 * np.pi * 0.7 * t_axis(dur, sr)) * 3.0
        phase = 2 * np.pi * np.cumsum(f + vibrato) / sr
        roar += np.sin(phase) * a
    roar = np.tanh(roar * 1.5) * env_adsr(n, sr, 0.35, 0.3, 0.6, 0.8)
    return fade(reverb(roar * 0.8 + bell(55.0, dur, sr, 0.6, 1.6), sr, wet=0.4), sr, 0.02, 0.35)


def sfx_run_start(sr=SR_SFX):
    dur = 1.6
    out = bell(146.83, dur, sr, 0.7, 1.4)
    out += bell(220.0, dur, sr, 0.35, 1.2) * 0.6
    return fade(reverb(out, sr, wet=0.45), sr, 0.01, 0.3)


def sfx_ui_click(sr=SR_SFX):
    dur = 0.09
    n = int(dur * sr)
    click = bandpass(noise(dur, sr), 900.0, 5200.0, sr) * env_ad(n, 0.0, 0.03, sr)
    wood = sine(320.0, dur, sr) * env_ad(n, 0.001, 0.06, sr) * 0.6
    return fade(click * 0.7 + wood, sr)


def sfx_ui_hover(sr=SR_SFX):
    dur = 0.07
    n = int(dur * sr)
    tone = sine(880.0, dur, sr) * env_ad(n, 0.002, 0.05, sr) * 0.35
    return fade(tone, sr)


def sfx_ui_denied(sr=SR_SFX):
    dur = 0.22
    n = int(dur * sr)
    thud = lowpass(noise(dur, sr), 700.0, sr, 2) * env_ad(n, 0.001, 0.12, sr)
    tone = sine(110.0, dur, sr) * env_ad(n, 0.005, 0.14, sr) * 0.6
    return fade(thud + tone, sr)


def sfx_gem_absorb(sr=SR_SFX):
    dur = 0.14
    n = int(dur * sr)
    tone = sweep(1800.0, 2600.0, dur, sr) * env_ad(n, 0.001, 0.09, sr) * 0.5
    return fade(tone + bandpass(noise(dur, sr), 3000.0, 9000.0, sr) *
                env_ad(n, 0.0, 0.04, sr) * 0.2, sr)


SFX = {
    "hit": sfx_hit,
    "hit_heavy": sfx_hit_heavy,
    "orb_hit": sfx_orb_hit,
    "lightning": sfx_lightning,
    "xp_pickup": sfx_xp_pickup,
    "coin": sfx_coin,
    "heart": sfx_heart,
    "level_up": sfx_level_up,
    "weapon_evolve": sfx_evolve,
    "enemy_die": sfx_enemy_die,
    "boss_die": sfx_boss_die,
    "player_die": sfx_player_die,
    "blink": sfx_blink,
    "surge": sfx_surge,
    "last_stand": sfx_last_stand,
    "boss_spawn": sfx_boss_spawn,
    "run_start": sfx_run_start,
    "ui_click": sfx_ui_click,
    "ui_hover": sfx_ui_hover,
    "ui_denied": sfx_ui_denied,
    "gem_absorb": sfx_gem_absorb,
}