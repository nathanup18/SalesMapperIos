"""'3 lines' edit, LIGHT style (Nathan 2026-11-23): best take per line, natural beats kept (research: winners leave ~0.5 s pauses),
normal-size TikTok header + numbered labels, jump-cut zoom alternation, no inserts, no SFX. Clean version is primary (native captions in-app)."""
import json, wave, subprocess, os
import numpy as np
os.chdir(os.path.dirname(os.path.abspath(__file__)))
W = json.load(open('words.json')); FPS = 30; F = lambda x: round(x * FPS) / FPS
GRADE = "zscale=tin=bt709:t=bt709:min=bt2020nc:m=bt709:pin=bt2020:p=bt709:rin=tv:r=tv,format=yuv420p"
# (clip, lo, hi, label shown from this clip until the next label)
CLIPS = [("IMG_9804", 0, 99, None), ("IMG_9806", 0, 99, None),
         ("IMG_9809", 0, 99, "1. Say their objection first"), ("IMG_9811", 0, 99, None), ("IMG_9812", 0, 99, None), ("IMG_9813", 0, 99, None),
         ("IMG_9815", 0, 99, "2. Ask for a no"), ("IMG_9816", 0, 99, None), ("IMG_9818", 7.1, 99, None), ("IMG_9821", 0, 99, None),
         ("IMG_9822", 0, 99, "3. Remind them they can say no"), ("IMG_9823", 0, 99, None), ("IMG_9825", 0, 99, None),
         ("IMG_9828", 0, 99, None), ("IMG_9831", 0, 99, None)]
HEADER = "3 lines that raise your close rate"
GAP_MAX, KEEP_AFTER, KEEP_BEFORE, LEAD, TAIL = 0.60, 0.16, 0.12, 0.05, 0.22   # keep natural beats; only trim real dead air
out = 'build'; os.makedirs(f'{out}/segs', exist_ok=True)
def energy(n):
    a = wave.open(f'{n}.wav'); x = np.frombuffer(a.readframes(a.getnframes()), np.int16).astype(float) / 32768
    db = 20 * np.log10(np.array([np.sqrt(np.mean(x[i:i + 160] ** 2)) for i in range(0, len(x) - 160, 160)]) + 1e-9)
    return db, np.percentile(db, 10), len(x) / 16000
def regions(db, fl, thr=10):
    sp = db > fl + thr; regs = []; i = 0
    while i < len(sp):
        if sp[i]:
            j = i
            while j < len(sp) and sp[j]: j += 1
            if j - i >= 5: regs.append([i * .01, j * .01])
            i = j
        else: i += 1
    m = []
    for r in regs:
        if m and r[0] - m[-1][1] < 0.15: m[-1][1] = r[1]
        else: m.append(r)
    return m
segs = []
for n, lo, hi, _ in CLIPS:
    db, fl, dur = energy(n); ws = [w for w in W[n] if lo - 0.05 <= w['s'] < hi]; last = ws[-1]['e']
    regs = [[max(r[0], lo), min(r[1], hi)] for r in regions(db, fl) if r[1] > lo and r[0] < last + 0.4]
    i0 = int(regs[0][0] * 100); onset = next((k / 100 for k in range(i0, len(db)) if db[k] > fl + 20), regs[0][0])
    start = max(lo, onset - LEAD); end = min(dur - 0.02, regs[-1][1] + TAIL); regs = [r for r in regs if r[1] > start]; cur = start
    for r0, r1 in zip(regs, regs[1:]):
        if r1[0] - r0[1] > GAP_MAX: segs.append((n, cur, r0[1] + KEEP_AFTER)); cur = r1[0] - KEEP_BEFORE
    segs.append((n, cur, end))
tl = []; t = 0.0; zi = 0
with open(f'{out}/segs/list.txt', 'w') as L:
    for i, (n, a, b) in enumerate(segs):
        d = F(b - a); z = 1.0
        if i > 0: zi += 1; z = 1.12 if zi % 2 == 0 else 1.0        # alternate framing on every cut so jump cuts read as intentional
        crop = f"crop=iw/{z}:ih/{z}:(iw-ow)/2:(ih-oh)*0.36,scale=1080:1920:flags=lanczos," if z > 1 else ""
        f = f'{out}/segs/s{i:02d}.mkv'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', f'{n}.MOV', '-t', f'{d:.4f}', '-vf', f'{GRADE},{crop}fps={FPS},setsar=1',
                        '-af', f'afade=t=in:d=0.012,afade=t=out:st={d - 0.015:.3f}:d=0.015,apad', '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx264', '-crf', '16',
                        '-pix_fmt', 'yuv420p', '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '1', '-t', f'{d:.4f}', f], check=True)
        tl.append(dict(i=i, clip=n, a=round(a, 3), b=round(a + d, 3), out0=round(t, 4), dur=d, zoom=z)); L.write(f"file 's{i:02d}.mkv'\n"); t += d
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', f'{out}/segs/list.txt', '-c', 'copy', f'{out}/main.mkv'], check=True)
json.dump(tl, open(f'{out}/timeline.json', 'w'), indent=1); json.dump([], open(f'{out}/inserts.json', 'w'))
sec = {}
for s in tl:
    v = sec.setdefault(s['clip'], [s['out0'], s['out0'] + s['dur']]); v[1] = s['out0'] + s['dur']
# captions (backup version only)
def to_out(c, s):
    ss = [x for x in tl if x['clip'] == c]; s = max(s, ss[0]['a'])
    for x in ss:
        if x['a'] <= s < x['b']: return x['out0'] + (s - x['a'])
FIX = {'Knows': 'nos.', '112%.': '112%.', 'Is': 'is'}
words = []
for n, lo, hi, _ in CLIPS:
    for w in W[n]:
        if w['s'] < lo - 0.05: continue
        o = to_out(n, w['s'] + 0.02)
        if o is not None: words.append(dict(w=FIX.get(w['w'], w['w']), s=round(o, 3), e=round(o + w['e'] - w['s'], 3), clip=n))
def ts(x): return f"{int(x // 3600)}:{int(x % 3600 // 60):02d}:{x % 60:05.2f}"
hdr = open('captions3.ass').read().split('[Events]')[0].replace('Nunito Sans Black,104', 'TikTok Sans Black,84')
chunks, cur = [], []
for w in words:
    if cur and (len(cur) == 3 or w['clip'] != cur[-1]['clip'] or w['s'] - cur[-1]['e'] > 0.35 or cur[-1]['w'].endswith(('.', ',', '?'))): chunks.append(cur); cur = []
    cur.append(w)
chunks.append(cur); ev = []
for ci, ch in enumerate(chunks):
    nxt = chunks[ci + 1][0]['s'] if ci + 1 < len(chunks) else ch[-1]['e'] + 0.3
    ev.append(f"Dialogue: 0,{ts(ch[0]['s'])},{ts(max(min(nxt, ch[-1]['e'] + 0.35), ch[0]['s'] + 0.2))},Caption,,0,0,0,,{{\\an5\\pos(540,1640)}}{' '.join(x['w'] for x in ch)}")
open(f'{out}/captions.ass', 'w').write(hdr + "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n" + "\n".join(ev) + "\n")
# header + labels: TikTok native text box, normal size
def label(txt, k):
    open(f'{out}/lab{k}.html', 'w').write(open('ov/label_tiktok.html').read().replace('LABEL', txt))
    subprocess.run(['node', '../template/shot.js', os.path.abspath(f'{out}/lab{k}.html'), os.path.abspath(f'{out}/lab{k}.png')], check=True); return f'{out}/lab{k}.png'
starts = [(F(sec[n][0]), txt) for n, _, _, txt in CLIPS if txt]
labels = [(label(HEADER, 0), 0.0, starts[0][0])]
for k, (a, txt) in enumerate(starts):
    b = starts[k + 1][0] if k + 1 < len(starts) else F(sec['IMG_9828'][0])
    labels.append((label(txt, k + 1), a, b))
labels.append(('../raw3/ov/cta.png', F(sec['IMG_9831'][0]), t))
args = ['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv'] + sum([['-i', p] for p, _, _ in labels], [])
fc = ['[0:v]setsar=1[b0]']; last = 'b0'; half = 0.5 / FPS
for j, (p, a, b) in enumerate(labels):
    fc.append(f"[{last}][{j + 1}:v]overlay=0:0:enable='gte(t,{a - half:.4f})*lt(t,{b - half:.4f})'[t{j}]"); last = f't{j}'
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv', '-af', 'highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000', f'{out}/voice.wav'], check=True)
for kind in ['clean', 'captions']:
    tail = f'[{last}]ass={out}/captions.ass:fontsdir=/root/.fonts[v]' if kind == 'captions' else f'[{last}]null[v]'
    subprocess.run(args + ['-filter_complex', ';'.join(fc + [tail]), '-map', '[v]', '-map', '0:a', '-af', 'highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000,alimiter=limit=0.95',
                           '-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p', '-r', str(FPS), '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart',
                           f'd2d_3_lines_{kind}.mp4'], check=True)
print('done', round(t, 2), 's;', {k: [round(a, 2), round(b, 2)] for k, (a, b) in sec.items()})
