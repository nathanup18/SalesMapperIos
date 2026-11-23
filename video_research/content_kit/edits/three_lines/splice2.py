"""Tight HDR splice (F35 + F36): original picture untouched; speech detected per clip; every pause squeezed to ~GAP s."""
import json, wave, subprocess, numpy as np
W = json.load(open('words.json')); FPS = 30
CLIPS = [("IMG_9804", 0), ("IMG_9806", 0), ("IMG_9809", 0), ("IMG_9811", 0), ("IMG_9812", 0), ("IMG_9813", 0), ("IMG_9815", 0), ("IMG_9816", 0),
         ("IMG_9818", 7.1), ("IMG_9821", 0), ("IMG_9822", 0), ("IMG_9823", 0), ("IMG_9825", 0), ("IMG_9828", 0), ("IMG_9831", 0)]
PRE, POST, MAXGAP = 0.03, 0.06, 0.15      # keep 40 ms before speech, 90 ms after; any silence longer than MAXGAP gets cut out
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
for n, lo in CLIPS:
    regs, dur = speech(n); ws = W[n]; last = ws[-1]['e']
    regs = [r for r in regs if r[1] > lo + 0.05 and r[0] < last + 0.5]
    cur = max(lo, regs[0][0] - PRE)
    for r0, r1 in zip(regs, regs[1:]):
        g0, g1 = r0[1] + POST, r1[0] - PRE
        for w in ws:                                   # never cut through a word: shrink the cut to stop at Whisper's word edges
            if w['s'] < g1 and w['e'] > g0:
                if w['s'] >= g0 - 0.05: g1 = min(g1, w['s'])
                else: g0 = max(g0, w['e'])
        if r1[0] - r0[1] > MAXGAP and g1 - g0 > 0.08: segs.append((n, cur, g0)); cur = g1
    segs.append((n, cur, min(dur - 0.02, regs[-1][1] + POST)))
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
L = open('splice/list2.txt', 'w'); tl = []; t = 0
for i, (n, a, b) in enumerate(segs):
    d = round((b - a) * FPS) / FPS; f = f'splice/t{i:02d}.mov'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', f'{n}.MOV', '-t', f'{d:.4f}', '-map', '0:v:0', '-map', '0:a:0',
                    '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X,
                    '-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv', '-tag:v', 'hvc1',
                    '-af', f'afade=t=in:d=0.008,afade=t=out:st={d - 0.012:.3f}:d=0.012,apad', '-c:a', 'pcm_s16le', '-ar', '48000', '-t', f'{d:.4f}', f], check=True)
    L.write(f"file 't{i:02d}.mov'\n"); tl.append(dict(i=i, clip=n, a=round(a, 3), b=round(b, 3), out0=round(t, 3), dur=d)); t += d
L.close(); json.dump(tl, open('splice/timeline2.json', 'w'), indent=1)
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', 'splice/list2.txt', '-c:v', 'copy', '-tag:v', 'hvc1',
                '-c:a', 'aac', '-b:a', '256k', '-movflags', '+faststart', 'd2d_3_lines_SPLICE_tight5.mp4'], check=True)
print(len(segs), 'segments from', len(CLIPS), 'takes;', round(t, 2), 's')
