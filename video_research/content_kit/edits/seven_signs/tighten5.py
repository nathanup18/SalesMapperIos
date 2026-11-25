"""Second pass on seg/main.mov: remove the S1 stumble and every silence >= 0.2 s (energy-based; Whisper spans run over pauses)."""
import wave, numpy as np, json, subprocess, os
FPS = 30; F = lambda x: round(x * FPS) / FPS
import json as _j
T = float(subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0','seg4/main.mov'],capture_output=True,text=True).stdout)
_W = _j.load(open('outwords4.json')); _S = _j.load(open('seg4/sec.json'))
cuts = [(0.0, 2.24)]                                         # first hook take, he restarts at "seven signs"
for k in ['S1','S2','S3','S4','S5','S6','S7']:               # spoken numbers: jump straight to the first real word
    ws = [w for w in _W if w['sec'] == k]
    cuts.append((_S[k][0], ws[1]['s'] - 0.03))
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
os.makedirs('seg5', exist_ok=True); L = open('seg5/list.txt', 'w'); tmap = []; t = 0
for k, (a, b) in enumerate(keep):
    a, b = F(a), F(b); d = b - a
    if d <= 0: continue
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.4f}', '-i', 'seg4/main.mov', '-t', f'{d:.4f}', '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx265', '-preset', 'medium', '-crf', '12',
                    '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['-af', f'afade=t=in:d=0.006,afade=t=out:st={d - 0.01:.3f}:d=0.01,apad', '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '2', '-t', f'{d:.4f}', f'seg5/k{k:02d}.mov'], check=True)
    L.write(f"file 'k{k:02d}.mov'\n"); tmap.append(dict(a=a, b=b, out0=round(t, 4))); t += d
L.close(); json.dump(tmap, open('seg5/tmap.json', 'w'))
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', 'seg5/list.txt', '-c', 'copy', 'seg5/main.mov'], check=True)
sec = json.load(open('seg4/sec.json'))
def m(tt):
    for s in tmap:
        if s['a'] - 1e-3 <= tt <= s['b'] + 1e-3: return s['out0'] + max(0, tt - s['a'])
    return min((s['out0'] for s in tmap if s['a'] > tt), default=t)
json.dump({k: [F(m(a)), F(m(b))] for k, (a, b) in sec.items()}, open('seg5/sec.json', 'w'))
print('new length', round(t, 2)); print(json.load(open('seg5/sec.json')))
