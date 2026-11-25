"""Second pass on seg/main.mov: remove the S1 stumble and every silence >= 0.2 s (energy-based; Whisper spans run over pauses)."""
import wave, numpy as np, json, subprocess, os
FPS = 30; F = lambda x: round(x * FPS) / FPS
w = wave.open('main.wav'); x = np.frombuffer(w.readframes(w.getnframes()), np.int16) / 32768; T = len(x) / 16000
db = np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + 160] ** 2)) + 1e-9) for i in range(0, len(x) - 160, 160)])
on = db > np.percentile(db, 5) + 12; on = np.array([on[max(0, i - 1):i + 2].sum() >= 2 for i in range(len(on))])
cuts = [(10.50, 12.10)]                                   # "They're already spending..." false start
i = 0
while i < len(on):
    if not on[i]:
        j = i
        while j < len(on) and not on[j]: j += 1
        a, b = i / 100, j / 100
        if b - a >= 0.2 and a > 0.1: cuts.append((a + 0.06, b - 0.06))
        i = j
    else: i += 1
# guard short Whisper words (reliable timings): never cut through their core; long spans (>0.4 s) usually swallow a pause, so ignore them
WS = [w for w in json.load(open('outwords.json')) if w['e'] - w['s'] < 0.4]
g = []
for a, b in cuts:
    if (a, b) == (10.50, 12.10): g.append((a, b)); continue
    for w in WS:
        cs, ce = w['s'] + 0.2 * (w['e'] - w['s']), w['e'] - 0.2 * (w['e'] - w['s'])
        if cs < b and ce > a:
            if cs - a >= b - ce: b = min(b, cs)
            else: a = max(a, ce)
    if b - a >= 0.08: g.append((a, b))
cuts = g
cuts = sorted(cuts); merged = []
for a, b in cuts:
    if merged and a <= merged[-1][1]: merged[-1] = (merged[-1][0], max(b, merged[-1][1]))
    else: merged.append((a, b))
keep, cur = [], 0.0
for a, b in merged:
    if a - cur >= 0.1: keep.append((cur, a))
    cur = b
keep.append((cur, T))
print(len(merged), 'cuts, removed', round(sum(b - a for a, b in merged), 2), 's')
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
os.makedirs('seg2', exist_ok=True); L = open('seg2/list.txt', 'w'); tmap = []; t = 0
for k, (a, b) in enumerate(keep):
    a, b = F(a), F(b); d = b - a
    if d <= 0: continue
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.4f}', '-i', 'seg/main.mov', '-t', f'{d:.4f}', '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx265', '-preset', 'medium', '-crf', '12',
                    '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['-af', f'afade=t=in:d=0.006,afade=t=out:st={d - 0.01:.3f}:d=0.01,apad', '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '2', '-t', f'{d:.4f}', f'seg2/k{k:02d}.mov'], check=True)
    L.write(f"file 'k{k:02d}.mov'\n"); tmap.append(dict(a=a, b=b, out0=round(t, 4))); t += d
L.close(); json.dump(tmap, open('seg2/tmap.json', 'w'))
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', 'seg2/list.txt', '-c', 'copy', 'seg2/main.mov'], check=True)
sec = json.load(open('seg/sec.json'))
def m(tt):
    for s in tmap:
        if s['a'] - 1e-3 <= tt <= s['b'] + 1e-3: return s['out0'] + max(0, tt - s['a'])
    return min((s['out0'] for s in tmap if s['a'] > tt), default=t)
json.dump({k: [F(m(a)), F(m(b))] for k, (a, b) in sec.items()}, open('seg2/sec.json', 'w'))
print('new length', round(t, 2)); print(json.load(open('seg2/sec.json')))
