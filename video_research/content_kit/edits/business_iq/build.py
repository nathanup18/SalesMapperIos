"""D2D IQ video: tight splice (F36) in original HDR (F35) + spec-sheet term cards (title + card) converted INTO HLG and overlaid per spoken term."""
import json, wave, subprocess, os, numpy as np, cv2
W = json.load(open('words.json')); FPS = 30; F = lambda x: round(x * FPS) / FPS
CLIPS = [("HOOK", "IMG_9870", 0, 99), ("B1", "IMG_9871", 0, 99), ("B2", "IMG_9872", 0, 99), ("B3", "IMG_9873", 0, 99), ("B4", "IMG_9874", 7.6, 99),
         ("O1", "IMG_9875", 9.3, 99)]    # outro: complete second take from the restart at 9.45 (F46: 6.8-7.45 is a false start "If you know", then a 2 s pause)
FILE = {a: f for a, f, _, _ in CLIPS}
TERMS = [("ltv", "B1", 3.9), ("cac", "B1", 4.7), ("arr", "B1", 5.2), ("gm", "B1", 5.75),
         ("cm", "B2", 2.2), ("churn", "B2", 3.3), ("ndr", "B2", 3.85), ("payback", "B2", 4.9),
         ("ccc", "B3", 1.9), ("dso", "B3", 3.4), ("wc", "B3", 4.0), ("ramp", "B3", 4.8),
         ("ebitda", "B4", 8.1), ("r40", "B4", 8.8), ("oplev", "B4", 9.8), ("unit", "B4", 10.6)]
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
for n, fn, lo, hi in CLIPS:
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
                   ['-af', f'afade=t=in:d=0.008,afade=t=out:st={d - 0.012:.3f}:d=0.012,apad', '-c:a', 'pcm_s16le', '-ar', '48000', '-t', f'{d:.4f}', f], check=True)
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
starts = [(k, c, F(to_out(c, s) - 0.03)) for k, c, s in TERMS]
win = []
for i, (k, c, a) in enumerate(starts):
    b = starts[i + 1][2] if i + 1 < len(starts) and starts[i + 1][1] == c else F(sec[c][1])
    if i + 1 < len(starts) and starts[i + 1][1] != c: b = F(sec[c][1])
    win.append((k, a, b))
# --- cards -> HLG: sRGB -> linear -> BT.2020 primaries -> SDR white at HLG reference (75% signal, BT.2408) -> HLG OETF
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073
E_REF = (np.exp((0.75 - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def to_hlg(png, out):
    im = cv2.imread(png, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]; al = im[..., 3]
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4) @ M.T * E_REF
    e = np.where(lin <= 1 / 12, np.sqrt(3 * np.clip(lin, 0, None)), a_ * np.log(np.clip(12 * lin - b_, 1e-9, None)) + c_)
    cv2.imwrite(out, (np.dstack([e[..., ::-1], al]) * 65535).round().astype(np.uint16))
os.makedirs('hlg', exist_ok=True)
blank = np.zeros((1920, 1080, 4), np.uint16); cv2.imwrite('hlg/blank.png', blank)
with open('hlg/list.txt', 'w') as L:
    cur = 0.0
    for k, a, b in win:
        to_hlg(f'cards/card_{k}.png', f'hlg/{k}.png')
        if a > cur + 1e-3: L.write(f"file 'blank.png'\nduration {a - cur:.4f}\n")
        L.write(f"file '{k}.png'\nduration {b - a:.4f}\n"); cur = b
    L.write(f"file 'blank.png'\nduration {t - cur + 0.5:.4f}\nfile 'blank.png'\n")
fc = ("[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];"
      "[0:v][ov]overlay=format=yuv420p10:eof_action=pass[v]")
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', 'seg/main.mov', '-f', 'concat', '-safe', '0', '-i', 'hlg/list.txt', '-filter_complex', fc, '-map', '[v]', '-map', '0:a',
                '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
               ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{t:.3f}', '-movflags', '+faststart', 'd2d_IQ_terms.mp4'], check=True)
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', 'seg/main.mov', '-c:v', 'copy', '-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-movflags', '+faststart', 'd2d_IQ_no_cards.mp4'], check=True)
json.dump(win, open('seg/cards.json', 'w'), indent=1)
print(len(segs), 'segments,', round(t, 2), 's'); [print(f'  {k:8s} {a:6.2f}-{b:6.2f} ({b - a:.2f}s)') for k, a, b in win]
