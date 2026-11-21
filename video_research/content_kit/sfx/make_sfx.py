"""Synthesize an original, royalty-free SFX kit (48 kHz mono WAV). Subtle by design."""
import numpy as np, wave, os
from scipy.signal import butter, sosfilt
SR = 48000; rng = np.random.default_rng(7)
def save(name, x):
    x = np.clip(x / (np.max(np.abs(x)) + 1e-9) * 0.9, -1, 1)
    with wave.open(os.path.join(os.path.dirname(__file__), name + '.wav'), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
def env(n, a, r):  # attack/release in samples, smooth
    e = np.ones(n); ka = max(1, int(a)); kr = max(1, int(r))
    e[:ka] = np.sin(np.linspace(0, np.pi / 2, ka)) ** 2; e[-kr:] *= np.cos(np.linspace(0, np.pi / 2, kr)) ** 2; return e
def sweep_noise(dur, f0, f1, q=1.4):
    n = int(dur * SR); x = rng.standard_normal(n); out = np.zeros(n); blk = 480
    for i in range(0, n, blk):
        f = f0 + (f1 - f0) * (i / n); lo, hi = f / q, min(f * q, SR / 2 - 100)
        sos = butter(2, [lo, hi], btype='band', fs=SR, output='sos'); out[i:i + blk] = sosfilt(sos, x[i:i + blk])
    return out
# whoosh: airy band-passed noise sweeping up then fading (screen cuts)
n = int(.42 * SR); w = sweep_noise(.42, 500, 2600) * env(n, .55 * n, .45 * n); save('whoosh', w)
# soft swoosh: shorter, higher (iMessage send)
n = int(.28 * SR); w = sweep_noise(.28, 1200, 4200) * env(n, .35 * n, .65 * n); save('swoosh_send', w)
# pop: pitch-dropping sine blip (labels, headline)
def pop(f0, f1, dur=.09, decay=38):
    t = np.arange(int(dur * SR)) / SR; ph = 2 * np.pi * np.cumsum(np.linspace(f0, f1, len(t))) / SR
    return np.sin(ph) * np.exp(-decay * t) * env(len(t), 24, 200)
save('pop', pop(760, 300)); save('pop_hi', pop(1150, 620, .07, 48))
# tap: tiny filtered click (UI taps)
t = int(.025 * SR); c = rng.standard_normal(t) * np.exp(-np.arange(t) / SR * 260); c = sosfilt(butter(2, [1800, 7000], btype='band', fs=SR, output='sos'), c); save('tap', c)
# key: keyboard click, slight variants
for k in range(4):
    t = int(.03 * SR); c = rng.standard_normal(t) * np.exp(-np.arange(t) / SR * (300 + 40 * k))
    c = sosfilt(butter(2, [2500 + 300 * k, 9000], btype='band', fs=SR, output='sos'), c); save(f'key{k}', c)
# check: soft two-tone blip (Reminders tick)
a = pop(880, 820, .06, 55); b = pop(1320, 1250, .08, 45); x = np.zeros(int(.13 * SR)); x[:len(a)] += a; x[int(.045 * SR):int(.045 * SR) + len(b)] += b * .9; save('check', x)
# drop: pin landing, low soft thud + pop
t = np.arange(int(.18 * SR)) / SR; th = np.sin(2 * np.pi * (140 - 200 * t) * t) * np.exp(-22 * t); p = pop(950, 500, .07, 50)
x = th * .8; x[:len(p)] += p * .6; save('drop', x)
# strike: quick pencil-like scratch (Notes strike-through)
n = int(.22 * SR); s = sweep_noise(.22, 3000, 5200, 1.8) * env(n, .1 * n, .5 * n); save('strike', s)
print('ok')
