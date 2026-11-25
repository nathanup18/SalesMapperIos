"""More doors = less money reel: tight splice in original HDR (stereo forced)."""
import json, wave, subprocess, os, numpy as np, cv2
W = json.load(open('words.json')); FPS = 30; F = lambda x: round(x * FPS) / FPS
CLIPS = [("HOOK", "IMG_9995", 31.4, 34.75), ("LOOP", "IMG_9998", 4.6, 99), ("R1", "IMG_9999", 0, 99), ("R2", "IMG_0001", 7.35, 99), ("PAY", "IMG_0002", 15.95, 99), ("CLOSE", "IMG_0003", 0, 99)]
FILE = {a: f for a, f, _, _ in CLIPS}
SECT = []; TITLE_SPAN = {}
PRE, POST, MAXGAP = 0.02, 0.04, 0.08   # F40: keep it moving
def speech(n):
    w = wave.open(f'{n}.wav'); x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32768
    db = np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + 160] ** 2)) + 1e-9) for i in range(0, len(x) - 160, 160)])
    on = db > np.percentile(db, 5) + 12; sp = np.array([on[max(0, i - 1):i + 2].sum() >= 2 for i in range(len(on))])
    regs, i = [], 0
    while i < len(sp):
        if sp[i]:
            j = i
            while j < len(sp) and sp[j]: j += 1
            if j - i >= 4: regs.append([i / 100, j / 100])
            i = j
        else: i += 1
    return regs, len(x) / 16000
segs = []
FORCE = set()
for n, fn, lo, hi in CLIPS:
    if n in FORCE: segs.append((n, lo, hi)); continue
    regs, dur = speech(fn); ws = [w for w in W[fn] if lo - 0.3 <= w['s'] < hi]; last = min(hi, ws[-1]['e'])
    regs = [[r[0], min(r[1], hi)] for r in regs if r[1] > lo + 0.05 and r[0] < min(hi, last + 0.5)]
    cur = max(lo, regs[0][0] - PRE)
    for r0, r1 in zip(regs, regs[1:]):
        g0, g1 = r0[1] + POST, r1[0] - PRE
        for w in ws:                         # guard only each word's core: Whisper spans in fast lists run word-to-word with no gap
            cs, ce = w['s'] + 0.3 * (w['e'] - w['s']), w['e'] - 0.3 * (w['e'] - w['s'])
            if cs < g1 and ce > g0:
                if cs >= g0: g1 = min(g1, cs)
                else: g0 = max(g0, ce)
        if r1[0] - r0[1] > MAXGAP and g1 - g0 > 0.04: segs.append((n, cur, g0)); cur = g1
    segs.append((n, cur, min(dur - 0.02, hi, regs[-1][1] + POST)))
segs = [g for g in segs if g[2] - g[1] >= 0.2]   # drop breath/noise slivers between phrases
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
os.makedirs('seg', exist_ok=True); L = open('seg/list.txt', 'w'); tl = []; t = 0
for i, (n, a, b) in enumerate(segs):
    d = F(b - a); f = f'seg/s{i:02d}.mov'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', f'{FILE[n]}.MOV', '-t', f'{d:.4f}', '-map', '0:v:0', '-map', '0:a:0', '-vf', f'fps={FPS}',
                    '-c:v', 'libx265', '-preset', 'medium', '-crf', '12', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
                   ['-af', f'afade=t=in:d=0.008,afade=t=out:st={d - 0.012:.3f}:d=0.012,apad', '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '2', '-t', f'{d:.4f}', f], check=True)
    L.write(f"file 's{i:02d}.mov'\n"); tl.append(dict(clip=n, a=round(a, 3), b=round(a + d, 3), out0=round(t, 4), dur=d)); t += d
L.close(); json.dump(tl, open('seg/timeline.json', 'w'), indent=1)
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', 'seg/list.txt', '-c', 'copy', 'seg/main.mov'], check=True)
def to_out(c, s):
    best = None
    for x in tl:
        if x['clip'] != c: continue
        if x['a'] - 0.05 <= s < x['b']: return x['out0'] + max(0, s - x['a'])
        if x['a'] > s and best is None: best = x['out0']          # term fell in a removed gap: snap to next kept piece
    return best
sec = {}
for s in tl:
    v = sec.setdefault(s['clip'], [s['out0'], s['out0'] + s['dur']]); v[1] = s['out0'] + s['dur']
win = []
json.dump({k: [F(sec[al[0]][0]), F(sec[al[-1]][1])] for k, al in TITLE_SPAN.items()}, open('seg/titles.json', 'w'))
json.dump({a: [F(v[0]), F(v[1])] for a, v in sec.items()}, open('seg/sec.json', 'w'))
json.dump(win, open('seg/cards.json', 'w'), indent=1)
print(len(segs), 'segments,', round(t, 2), 's'); [print(f'  {k:8s} {a:6.2f}-{b:6.2f} ({b - a:.2f}s)') for k, a, b in win]
