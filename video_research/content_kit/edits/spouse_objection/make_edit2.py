"""One-shot edit: cut -> captions -> composite, for a named clip order.
Usage: python make_edit.py v4|v5   (v4 = hook,questions,re-knock,give,cta ; v5 = hook,give,questions,re-knock,cta)
Implements PLAYBOOK hard rules H1 (waveform cut points), H2 (captions below chin), H5 (frame-grid, no flashes), H6 (full animations).
"""
import json, wave, subprocess, os, sys, re
import numpy as np

V = sys.argv[1]
D = os.path.dirname(os.path.abspath(__file__)); os.chdir(D)
W = json.load(open('words.json'))
GRADE = "zscale=tin=bt709:t=bt709:min=bt2020nc:m=bt709:pin=bt2020:p=bt709:rin=tv:r=tv,format=yuv420p"  # H9: no contrast grade
FPS = 30; F = lambda x: round(x * FPS) / FPS
CAP_Y = 1640
# clip -> (source start override, section label)
CLIPS = {"IMG_9748": (0, None), "IMG_9749": (0, "It's not the spouse"), "IMG_9751": (0, "Ask this"),
         "IMG_9752": (0, "Then do this"), "IMG_9753": (0, None)}
ORDERS = {"v1": ["IMG_9748", "IMG_9749", "IMG_9751", "IMG_9752", "IMG_9753"]}
order = ORDERS[V]
LO = {c: 0 for c in order}
LO["IMG_9748"] = 5.6    # skip false start "Here's how to handle the..."
LO["IMG_9749"] = 13.5   # keep the third, cleanest take
GAP_MAX, KEEP_AFTER, KEEP_BEFORE, LEAD, TAIL = 0.30, 0.10, 0.08, 0.04, 0.14
out = f"build_{V}"; os.makedirs(f"{out}/segs", exist_ok=True)


def energy(name):
    a = wave.open(name + '.wav'); x = np.frombuffer(a.readframes(a.getnframes()), np.int16).astype(float) / 32768
    hop = int(a.getframerate() * 0.01)
    db = 20 * np.log10(np.array([np.sqrt(np.mean(x[i:i + hop] ** 2)) for i in range(0, len(x) - hop, hop)]) + 1e-9)
    return db, np.percentile(db, 10), len(x) / a.getframerate()


def regions(db, floor, thr):
    sp = db > floor + thr; regs = []; i = 0
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


# ---------- 1. cut list (H1: cut points from the waveform only)
segs = []
for idx, name in enumerate(order):
    db, floor, dur = energy(name); lo = LO[name]
    ws = [w for w in W[name] if w['s'] >= lo - 0.05]
    last = ws[-1]['e']
    regs = [[max(r[0], lo), r[1]] for r in regions(db, floor, 10) if r[1] > lo and r[0] < last + 0.4]
    # onset = first 10 ms frame >= floor+20 dB at/after the first region (ignores breaths and handling noise)
    i0 = int(regs[0][0] * 100); onset = next((k / 100 for k in range(i0, len(db)) if db[k] > floor + 20), regs[0][0])
    start = max(lo, onset - LEAD) if lo == 0 or onset - LEAD > lo else lo
    end = min(dur - 0.02, regs[-1][1] + TAIL)
    regs = [r for r in regs if r[1] > start]
    cur = start
    for r0, r1 in zip(regs, regs[1:]):
        if r1[0] - r0[1] > GAP_MAX:
            segs.append((name, cur, r0[1] + KEEP_AFTER)); cur = r1[0] - KEEP_BEFORE
    segs.append((name, cur, end))

# render segments, snapping each duration to whole frames
t = 0.0; timeline = []
with open(f'{out}/segs/list.txt', 'w') as L:
    for i, (name, a, b) in enumerate(segs):
        d = F(b - a); z = 1.0 if i % 2 == 0 else 1.12
        crop = f"crop=iw/{z}:ih/{z}:(iw-ow)/2:(ih-oh)*0.36,scale=1080:1920:flags=lanczos," if z > 1 else ""
        f = f'{out}/segs/s{i:02d}.mkv'  # PCM audio: no AAC priming, so no A/V drift across segments
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', f'{name}.MOV', '-t', f'{d:.4f}',
                        '-vf', f'{GRADE},{crop}fps={FPS},setsar=1', '-af', f'afade=t=in:d=0.012,afade=t=out:st={d - 0.015:.3f}:d=0.015,apad',
                        '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx264', '-preset', 'medium', '-crf', '16', '-pix_fmt', 'yuv420p',
                        '-c:a', 'pcm_s16le', '-ar', '48000', '-t', f'{d:.4f}', f], check=True)
        timeline.append(dict(i=i, clip=name, a=round(a, 3), b=round(a + d, 3), out0=round(t, 4), dur=d, zoom=z))
        L.write(f"file 's{i:02d}.mkv'\n"); t += d
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', f'{out}/segs/list.txt', '-c', 'copy', f'{out}/main.mkv'], check=True)
json.dump(timeline, open(f'{out}/timeline.json', 'w'), indent=1)
sec = {}
for s in timeline:
    v = sec.setdefault(s['clip'], [s['out0'], s['out0'] + s['dur']]); v[1] = s['out0'] + s['dur']
sec = {k: [F(a), F(b)] for k, (a, b) in sec.items()}

# ---------- 2. words + captions (H2: below the chin)
FIX = {"Spose": "spouse", "Need": "need", "Talk": "talk", "My": "my", "Objection.": "objection.", "fall": "follow"}
def to_out(clip, s):
    ss = [x for x in timeline if x['clip'] == clip]
    s = max(s, ss[0]['a'])
    for x in ss:
        if x['a'] <= s < x['b']: return x['out0'] + (s - x['a'])
words = []
for name in order:
    for w in W[name]:
        if w['s'] < LO[name] - 0.05: continue
        o = to_out(name, w['s'] + 0.02)
        if o is not None:
            txt = FIX.get(w['w'], w['w'])
            words.append(dict(w=txt, s=round(o, 3), e=round(o + w['e'] - w['s'], 3), clip=name))
json.dump(words, open(f'{out}/words.json', 'w'))
def ts(x): return f"{int(x // 3600)}:{int(x % 3600 // 60):02d}:{x % 60:05.2f}"
hdr = open('captions3.ass').read().split('[Events]')[0].replace('Nunito Sans Black,104', 'Nunito Sans Black,96')
chunks, cur = [], []
for w in words:
    if cur and (len(cur) == 2 or w['clip'] != cur[-1]['clip'] or w['s'] - cur[-1]['e'] > 0.35 or cur[-1]['w'].endswith(('.', ',', '?'))):
        chunks.append(cur); cur = []
    cur.append(w)
chunks.append(cur); ev = []
for ci, ch in enumerate(chunks):
    nxt = chunks[ci + 1][0]['s'] if ci + 1 < len(chunks) else ch[-1]['e'] + 0.3
    for j, w in enumerate(ch):
        s0 = w['s']; e0 = ch[j + 1]['s'] if j + 1 < len(ch) else min(nxt, ch[-1]['e'] + 0.35)
        txt = " ".join(("{\\c&H59C734&}" + x['w'].upper() + "{\\c&HFFFFFF&}") if k == j else x['w'].upper() for k, x in enumerate(ch))
        ev.append(f"Dialogue: 0,{ts(s0)},{ts(max(e0, s0 + 0.08))},Caption,,0,0,0,,{{\\an5\\pos(540,{CAP_Y})}}{txt}")
open(f'{out}/captions.ass', 'w').write(hdr + "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n" + "\n".join(ev) + "\n")

# ---------- 3. inserts (H5/H6) + labels
def at(word, clip, which='s', nth=0):
    return [w for w in words if w['w'].lower().strip('.,') == word and w['clip'] == clip][nth][which]
M = '../mockup/out/'
os.makedirs(f'{out}/anim', exist_ok=True)
def anim(scene, a, b, **cues):
    q = '&'.join([f'dur={b - a:.3f}'] + [f'{k}={v:.3f}' for k, v in cues.items()])
    f = os.path.abspath(f'{out}/anim/{scene}.mp4')
    subprocess.run(['node', 'render2.js', f'{scene}&{q}', f, '60'], cwd='../mockup', env={**os.environ, 'PAGE': 'inserts.html'}, check=True, capture_output=True)
    return f
s1 = at("it's", 'IMG_9749') - 0.05; e1 = sec['IMG_9749'][1]
s2 = at('if', 'IMG_9751') - 0.05;    e2 = sec['IMG_9751'][1]
s3 = sec['IMG_9752'][0];             e3 = sec['IMG_9752'][1]
ins = [(anim('notspouse', s1, e1), s1, e1),
       (anim('theline', s2, e2, say=0.06), s2, e2),
       (anim('branch', s3, e3, get=at('get', 'IMG_9752') - s3, close=at('close', 'IMG_9752') - s3,
             no=at('if', 'IMG_9752', nth=1) - s3, fig=at('figure', 'IMG_9752') - s3), s3, e3)]
starts = {v[0]: k for k, v in sec.items()}; ends = {v[1]: k for k, v in sec.items()}
fixed = []
for f, a, b in ins:
    a, b = F(a), F(b)
    near = [s for s in starts if -0.5 < a - s < 0.5]          # opens a section -> start on the cut (no face flash)
    if near: a = near[0]
    tail = [e for e in ends if abs(e - b) < 0.5]             # ends within 0.5 s of a section end (either side) -> end exactly on the cut
    if tail: b = tail[0]
    try: anim = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]))
    except Exception: anim = 0
    if 'ins_' in f and b - a < anim - 0.1: print('WARN window shorter than animation', f, b - a, anim)
    fixed.append((f, a, b))
ins = fixed
json.dump(ins, open(f'{out}/inserts.json', 'w'))
# pre-render padded 30 fps insert clips (exact length, frame-aligned)
padded = []
for k, (f, a, b) in enumerate(ins):
    p = f'{out}/ins{k}.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f, '-vf', f'fps={FPS},scale=1080:1920,setsar=1,tpad=start_mode=clone:start_duration={a:.4f}:stop_mode=clone:stop_duration=5',
                    '-t', f'{b + 0.3:.3f}', '-an', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '14', '-pix_fmt', 'yuv420p', p], check=True)
    padded.append(p)
# labels per section
css = open('ov/tip1.html').read()
labels = []
n = 0
for c in order:
    txt = CLIPS[c][1]
    if txt is None: continue
    n += 1
    h = re.sub(r'<div class="n">\d</div>[^<]+', f'<div class="n">{n}</div>{txt}', css)
    open(f'{out}/lab{n}.html', 'w').write(h)
    subprocess.run(['node', '../template/shot.js', os.path.abspath(f'{out}/lab{n}.html'), os.path.abspath(f'{out}/lab{n}.png')], check=True)
    labels.append((f'{out}/lab{n}.png', *sec[c]))
labels = [('ov/hook.png', *sec[order[0]])] + labels + [('ov/cta.png', *sec[order[-1]])]
args = ['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv']
for p in padded: args += ['-i', p]
for p, a, b in labels: args += ['-i', p]
fc = ['[0:v]setsar=1[b0]']; last = 'b0'; half = 0.5 / FPS
for i, (f, a, b) in enumerate(ins, 1):
    fc.append(f"[{last}][{i}:v]overlay=eof_action=pass:enable='gte(t,{a - half:.4f})*lt(t,{b - half:.4f})'[b{i}]"); last = f'b{i}'
for j, (p, a, b) in enumerate(labels):
    fc.append(f"[{last}][{len(ins) + 1 + j}:v]overlay=0:0:enable='gte(t,{a - half:.4f})*lt(t,{b - half:.4f})'[t{j}]"); last = f't{j}'
fc += [f'[{last}]ass={out}/captions.ass:fontsdir=/root/.fonts[v]', '[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11[a]']
final = f'd2d_spouse_objection_{V}_final.mp4'
subprocess.run(args + ['-filter_complex', ';'.join(fc), '-map', '[v]', '-map', '[a]', '-c:v', 'libx264', '-preset', 'slow', '-crf', '17',
                       '-pix_fmt', 'yuv420p', '-r', str(FPS), '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-movflags', '+faststart', final], check=True)
print(final, round(t, 2), 's')
