"""'We're not interested' edit. Playbook v15 rules: H1 waveform cuts, H2 captions below chin, H3/H14 face-first push-in,
H5 frame-grid/no flashes, H6 runtime gate, H9 accurate grade (own HLG clips only), H11 real-UI inserts, H12 TikTok text,
H13 captioned + clean, H15 subtle SFX (whoosh only face<->screen), F25 audio mix fix, QA_VOICE track.
Usage: python make_edit5.py
"""
import json, wave, subprocess, os, re
import numpy as np
D = os.path.dirname(os.path.abspath(__file__)); os.chdir(D)
W = json.load(open('words.json'))
FPS = 30; F = lambda x: round(x * FPS) / FPS
GRADE_HLG = "zscale=tin=bt709:t=bt709:min=bt2020nc:m=bt709:pin=bt2020:p=bt709:rin=tv:r=tv,format=yuv420p"
GRADE_SDR = "format=yuv420p"
CAP_Y = 1640
# clip: (file, lo, hi, label, grade)
CLIPS = {
    "HOOK":     ("HOOK.mov",     1.0, 99, None, GRADE_SDR),   # skip their "Hey!", open on "We're"                     # @claytonnelson_ "We're not interested. Sorry."
    "IMG_9770": ("IMG_9770.MOV", 0.0, 99, None, GRADE_HLG),                     # "If you knock doors, you hear that all day."
    "IMG_9771": ("IMG_9771.MOV", 18.6, 99, None, GRADE_HLG),                    # 2nd take: "It's one of the most common objections..."
    "IMG_9774": ("IMG_9774.MOV", 0.0, 99, "Instead: find common ground", GRADE_HLG),     # clean take, ends "pitch your services."
    "IMG_9779": ("IMG_9779.MOV", 0.0, 10.35, "What it sounds like", GRADE_HLG),
    "IMG_9780": ("IMG_9780.MOV", 0.0, 99, "Interest? Hook them. None? Move on", GRADE_HLG),  # "semblance of interest"
    "IMG_9781": ("IMG_9781.MOV", 0.0, 99, None, GRADE_HLG),                     # "Follow for more information like this."
}
order = list(CLIPS)
FACE_FIRST = "IMG_9770"           # push-in on first face shot (H14)
HOOK_CARD_ON = ["IMG_9770"]      # 9771 carries the door-outcomes screen
FIX = {"Amen.": "Hey man,", "Amen,": "Hey man,", "interested,": "interested.", "sorry.": "Sorry."}
GAP_MAX, KEEP_AFTER, KEEP_BEFORE, LEAD, TAIL = 0.30, 0.10, 0.08, 0.04, 0.14
out = "build"; os.makedirs(f"{out}/segs", exist_ok=True); os.makedirs(f"{out}/anim", exist_ok=True)


def energy(path):
    wav = f"{out}/{os.path.basename(path)}.wav"
    if not os.path.exists(wav):
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', path, '-ac', '1', '-ar', '16000', wav], check=True)
    a = wave.open(wav); x = np.frombuffer(a.readframes(a.getnframes()), np.int16).astype(float) / 32768
    db = 20 * np.log10(np.array([np.sqrt(np.mean(x[i:i + 160] ** 2)) for i in range(0, len(x) - 160, 160)]) + 1e-9)
    return db, np.percentile(db, 10), len(x) / 16000


def regions(db, floor, thr=10):
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


def pushin(path, d, z0=1.0, z1=1.10, cy=0.36):
    import cv2
    W_, H_ = 1080, 1920; tmp = path + '.v.mkv'
    dec = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', path, '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-'], stdout=subprocess.PIPE)
    enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-s', f'{W_}x{H_}', '-r', str(FPS), '-i', '-', '-i', path,
                            '-map', '0:v', '-map', '1:a', '-c:v', 'libx264', '-preset', 'medium', '-crf', '16', '-pix_fmt', 'yuv420p', '-c:a', 'copy', tmp], stdin=subprocess.PIPE)
    n = int(round(d * FPS)); k = 0
    while True:
        buf = dec.stdout.read(W_ * H_ * 3)
        if len(buf) < W_ * H_ * 3: break
        u = k / max(1, n - 1); e = u * u * (3 - 2 * u); z = z0 + (z1 - z0) * e
        M = np.float32([[z, 0, W_ / 2 - z * W_ / 2], [0, z, H_ * cy - z * H_ * cy]])
        enc.stdin.write(cv2.warpAffine(np.frombuffer(buf, np.uint8).reshape(H_, W_, 3), M, (W_, H_), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT).tobytes()); k += 1
    enc.stdin.close(); enc.wait(); dec.wait(); os.replace(tmp, path)


# ---------- 1. cut list from the waveform (H1)
segs = []
for name in order:
    path, lo, hi, _, _ = CLIPS[name]
    db, floor, dur = energy(path)
    ws = [w for w in W[name] if lo - 0.05 <= w['s'] < hi]
    last = min(hi, ws[-1]['e'])
    regs = [[max(r[0], lo), min(r[1], hi)] for r in regions(db, floor) if r[1] > lo and r[0] < min(hi, last + 0.4)]
    i0 = int(regs[0][0] * 100); onset = next((k / 100 for k in range(i0, len(db)) if db[k] > floor + (6 if name == "HOOK" else 20)), regs[0][0])  # quieter screen-recorded voice
    start = max(lo, onset - LEAD)
    end = min(dur - 0.02, hi, regs[-1][1] + TAIL)
    regs = [r for r in regs if r[1] > start]
    cur = start
    for r0, r1 in zip(regs, regs[1:]):
        if r1[0] - r0[1] > GAP_MAX:
            segs.append((name, cur, r0[1] + KEEP_AFTER)); cur = r1[0] - KEEP_BEFORE
    segs.append((name, cur, end))

t = 0.0; timeline = []; zi = 0
with open(f'{out}/segs/list.txt', 'w') as L:
    for i, (name, a, b) in enumerate(segs):
        d = F(b - a); path, _, _, _, grade = CLIPS[name]
        first_face = name == FACE_FIRST and not any(s['clip'] == name for s in timeline)
        z = 1.0
        if name != "HOOK" and not first_face:
            zi += 1; z = 1.12 if zi % 2 == 0 else 1.0
        crop = f"crop=iw/{z}:ih/{z}:(iw-ow)/2:(ih-oh)*0.36,scale=1080:1920:flags=lanczos," if z > 1 else ""
        f = f'{out}/segs/s{i:02d}.mkv'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', path, '-t', f'{d:.4f}',
                        '-vf', f'{grade},{crop}fps={FPS},setsar=1', '-af', f'afade=t=in:d=0.012,afade=t=out:st={d - 0.015:.3f}:d=0.015,apad',
                        '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx264', '-preset', 'medium', '-crf', '16', '-pix_fmt', 'yuv420p',
                        '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '1', '-t', f'{d:.4f}', f], check=True)
        if first_face: pushin(f, d)
        timeline.append(dict(i=i, clip=name, a=round(a, 3), b=round(a + d, 3), out0=round(t, 4), dur=d, zoom=z))
        L.write(f"file 's{i:02d}.mkv'\n"); t += d
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', f'{out}/segs/list.txt', '-c', 'copy', f'{out}/main.mkv'], check=True)
json.dump(timeline, open(f'{out}/timeline.json', 'w'), indent=1)
sec = {}
for s in timeline:
    v = sec.setdefault(s['clip'], [s['out0'], s['out0'] + s['dur']]); v[1] = s['out0'] + s['dur']
sec = {k: [F(a), F(b)] for k, (a, b) in sec.items()}

# ---------- 2. words + captions (H2)
def to_out(clip, s):
    ss = [x for x in timeline if x['clip'] == clip]; s = max(s, ss[0]['a'])
    for x in ss:
        if x['a'] <= s < x['b']: return x['out0'] + (s - x['a'])
words = []
for name in order:
    lo, hi = CLIPS[name][1], CLIPS[name][2]
    for w in W[name]:
        if w['s'] < lo - 0.05 or w['s'] >= hi: continue
        o = to_out(name, w['s'] + 0.02)
        if o is not None: words.append(dict(w=FIX.get(w['w'], w['w']), s=round(o, 3), e=round(o + w['e'] - w['s'], 3), clip=name))
json.dump(words, open(f'{out}/words.json', 'w'))
def ts(x): return f"{int(x // 3600)}:{int(x % 3600 // 60):02d}:{x % 60:05.2f}"
hdr = open('captions3.ass').read().split('[Events]')[0].replace('Nunito Sans Black,104', 'TikTok Sans Black,96')
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

# ---------- 3. inserts (H11) with runtime gate (H6)
def at(word, clip, which='s', nth=0):
    return [w for w in words if w['w'].lower().strip('.,?"') == word and w['clip'] == clip][nth][which]
def anim(scene, a, b, page='ios.html', **cues):
    import urllib.parse
    q = '&'.join([f'dur={b - a:.3f}'] + [f'{k}={urllib.parse.quote(str(v)) if isinstance(v, str) else f"{v:.3f}"}' for k, v in cues.items()])
    f = os.path.abspath(f'{out}/anim/{scene}.mp4')
    subprocess.run(['node', 'render2.js', f'{scene}&{q}', f, '60'], cwd='../mockup', env={**os.environ, 'PAGE': page}, check=True, capture_output=True)
    return f
s1 = F(at('saying', 'IMG_9774') - 0.05); e1 = sec['IMG_9774'][1]      # Notes runs to the end of the section: always moving
SPD = 0.6
NOTE = [('= find common ground', 'find'), ('• same street, same shirt', 'between'), ('• one thing you share', 'homeowner'), ('→ use it to pitch', 'use')]
tl = [at(w, 'IMG_9774') - s1 for _, w in NOTE]
t1 = at('i', 'IMG_9774') - s1 - 0.1; strike_c = at('you', 'IMG_9774') - s1 - 0.25; type_c = tl[0]
done_notes = tl[-1] + SPD
assert done_notes + 0.4 <= e1 - s1, f'H6: notes finishes {done_notes:.2f}s, window {e1 - s1:.2f}s'
print(f'runtime ok: notes done {done_notes:.2f}s, window {e1 - s1:.2f}s, hold {e1 - s1 - done_notes:.2f}s')
ins = [(anim('notes', s1, e1, t1=t1, strike=strike_c, type=type_c, spd=SPD, title='Objections', l1='"I totally get that"',
             **{f'l{k + 2}': txt for k, (txt, _) in enumerate(NOTE)}, **{f't{k + 2}': x for k, x in enumerate(tl)}), s1, e1)]
# door-outcomes breakdown in the SalesMapper app over "one of the most common objections" (bars done 1.6 s, highlight done 2.15 s)
s0, e0 = sec['IMG_9771']
assert 2.15 + 0.4 <= e0 - s0, f'H6: outcomes window {e0 - s0:.2f}s'
ins.insert(0, (anim('outcomes', s0, e0, page='mockup.html'), s0, e0))
# real app: tap a door, mark it Interested ("get that person on the hook"); scene action done at 6.4 s, sped up to fit
s3, e3 = F(at('if', 'IMG_9780') - 0.05), sec['IMG_9780'][1]
K = max(1.0, 6.4 / (e3 - s3 - 0.45)); raw = anim('tap', 0, 8, page='mockup.html', nozoom='1', pick='int')
tapf = os.path.abspath(f'{out}/anim/tap_fast.mp4')
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', raw, '-vf', f'setpts=PTS/{K:.4f}', '-t', f'{e3 - s3:.3f}', '-an', '-c:v', 'libx264', '-crf', '14', '-pix_fmt', 'yuv420p', tapf], check=True)
assert 6.4 / K + 0.4 <= e3 - s3 + 1e-6, 'H6: tap'
print(f'runtime ok: outcomes 2.15/{e0 - s0:.2f}s, tap done {6.4 / K:.2f}/{e3 - s3:.2f}s (x{K:.2f})')
ins.append((tapf, s3, e3))
json.dump(ins, open(f'{out}/inserts.json', 'w'))
padded = []
for k, (f, a, b) in enumerate(ins):
    p = f'{out}/ins{k}.mp4'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f, '-vf', f'fps={FPS},scale=1080:1920,setsar=1,tpad=start_mode=clone:start_duration={a:.4f}:stop_mode=clone:stop_duration=5',
                    '-t', f'{b + 0.3:.3f}', '-an', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '14', '-pix_fmt', 'yuv420p', p], check=True)
    padded.append(p)

# ---------- 4. labels (H10/H12)
labels = []   # no credit tag: Nathan adds it himself if needed
labels.append(('ov/hook.png', sec[HOOK_CARD_ON[0]][0], sec[HOOK_CARD_ON[-1]][1]))
n = 0
for c in order:
    txt = CLIPS[c][3]
    if not txt: continue
    n += 1
    h = open('ov/label_tiktok.html').read().replace('LABEL', f'{n}. {txt}')
    open(f'{out}/lab{n}.html', 'w').write(h)
    subprocess.run(['node', '../template/shot.js', os.path.abspath(f'{out}/lab{n}.html'), os.path.abspath(f'{out}/lab{n}.png')], check=True)
    a_, b_ = sec[c]
    labels.append((f'{out}/lab{n}.png', a_, b_))
labels.append(('ov/cta.png', *sec['IMG_9781']))                                 # on his spoken 'Follow for more'
args = ['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv'] + sum([['-i', p] for p in padded], []) + sum([['-i', p] for p, _, _ in labels], [])
fc = ['[0:v]setsar=1[b0]']; last = 'b0'; half = 0.5 / FPS
for i, (f, a, b) in enumerate(ins, 1):
    fc.append(f"[{last}][{i}:v]overlay=eof_action=pass:enable='gte(t,{a - half:.4f})*lt(t,{b - half:.4f})'[b{i}]"); last = f'b{i}'
hide = ''.join(f"*not(gte(t,{x - half:.4f})*lt(t,{y - half:.4f}))" for _, x, y in ins)
for j, (p, a, b) in enumerate(labels):
    fc.append(f"[{last}][{len(ins) + 1 + j}:v]overlay=0:0:enable='gte(t,{a - half:.4f})*lt(t,{b - half:.4f}){hide}'[t{j}]"); last = f't{j}'

# ---------- 5. SFX (H15/F26)
def _load(nm):
    w = wave.open(f'sfx/{nm}.wav'); return np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32768
SR = 48000; track = np.zeros(int((t + 1) * SR)); evs = []
def fx(at_, nm, g):
    at_ = max(0, at_); x = _load(nm) * g; i = int(at_ * SR); track[i:i + len(x)] += x[:max(0, len(track) - i)]; evs.append((round(at_, 3), nm))
G = dict(whoosh=.13, pop=.11, pop_hi=.09, strike=.07, key=.035)
fx(sec[HOOK_CARD_ON[0]][0], 'pop', G['pop'])                                     # hook card appears with first face shot
on_screen = lambda tt: any(x - 1e-3 <= tt < y - 1e-3 for _, x, y in ins)
for c in sorted({a for _, a, _ in ins} | {b for _, _, b in ins}):
    if on_screen(c - 0.02) != on_screen(c + 0.02): fx(c - 0.23, 'whoosh', G['whoosh'] * (1.0 if on_screen(c + 0.02) else .75))
for p, a, b in labels[1:]:
    if not on_screen(a + 0.02): fx(a + 0.03, 'pop_hi', G['pop_hi'])
fx(s1 + strike_c, 'strike', G['strike'])
fx(s3 + 4.35 / K, 'pop', G['pop'])                                               # Interested pin lands
rng = np.random.default_rng(3)
for txt, t0 in [('"I totally get that"', t1)] + [(x, y) for (x, _), y in zip(NOTE, tl)]:
    for q in range(len(txt)):
        if rng.random() < .3: continue
        fx(s1 + t0 + SPD * q / len(txt) + rng.uniform(-.01, .01), f'key{rng.integers(4)}', G['key'] * rng.uniform(.6, 1.0))
with wave.open(f'{out}/sfx_track.wav', 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.clip(track, -1, 1) * 32767).astype(np.int16).tobytes())
json.dump(evs, open(f'{out}/sfx_events.json', 'w'))
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv', '-af', 'highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000', f'{out}/voice.wav'], check=True)
args += ['-i', f'{out}/sfx_track.wav']; FX = len(ins) + len(labels) + 1
for kind in ['captions', 'clean']:
    tail = [f'[{last}]ass={out}/captions.ass:fontsdir=/root/.fonts[v]' if kind == 'captions' else f'[{last}]null[v]',
            '[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[vo]', f'[{FX}:a]aresample=48000[fx]',
            f'[vo][fx]amix=inputs=2:normalize=0:duration=longest,atrim=0:{t:.4f},alimiter=limit=0.95[a]']
    final = f'd2d_not_interested_{kind}.mp4'
    subprocess.run(args + ['-filter_complex', ';'.join(fc + tail), '-map', '[v]', '-map', '[a]', '-c:v', 'libx264', '-preset', 'slow', '-crf', '17',
                           '-pix_fmt', 'yuv420p', '-r', str(FPS), '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-movflags', '+faststart', final], check=True)
    print(final, round(t, 2), 's')
print('sections', {k: [round(a, 2), round(b, 2)] for k, (a, b) in sec.items()})
