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
         "IMG_9752": (0, "Then do this"), "IMG_9753": (0, None)}  # H12: TikTok-native labels "1. ..." 
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
        u = k / max(1, n - 1); e = u * u * (3 - 2 * u); z = z0 + (z1 - z0) * e   # smoothstep, no jitter (subpixel warp)
        cx, cyy = W_ / 2, H_ * cy
        M = np.float32([[z, 0, cx - z * cx], [0, z, cyy - z * cyy]])
        fr = cv2.warpAffine(np.frombuffer(buf, np.uint8).reshape(H_, W_, 3), M, (W_, H_), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
        enc.stdin.write(fr.tobytes()); k += 1
    enc.stdin.close(); enc.wait(); dec.wait(); os.replace(tmp, path)

# render segments, snapping each duration to whole frames
t = 0.0; timeline = []
with open(f'{out}/segs/list.txt', 'w') as L:
    for i, (name, a, b) in enumerate(segs):
        d = F(b - a); z = 1.0 if (i == 0 or i % 2 == 1) else 1.12
        crop = f"crop=iw/{z}:ih/{z}:(iw-ow)/2:(ih-oh)*0.36,scale=1080:1920:flags=lanczos," if z > 1 else ""
        f = f'{out}/segs/s{i:02d}.mkv'  # PCM audio: no AAC priming, so no A/V drift across segments
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', f'{name}.MOV', '-t', f'{d:.4f}',
                        '-vf', f'{GRADE},{crop}fps={FPS},setsar=1', '-af', f'afade=t=in:d=0.012,afade=t=out:st={d - 0.015:.3f}:d=0.015,apad',
                        '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx264', '-preset', 'medium', '-crf', '16', '-pix_fmt', 'yuv420p',
                        '-c:a', 'pcm_s16le', '-ar', '48000', '-t', f'{d:.4f}', f], check=True)
        if i == 0: pushin(f, d)
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

# ---------- 3. inserts (H5/H6) + labels
def at(word, clip, which='s', nth=0):
    return [w for w in words if w['w'].lower().strip('.,') == word and w['clip'] == clip][nth][which]
M = '../mockup/out/'
os.makedirs(f'{out}/anim', exist_ok=True)
def anim(scene, a, b, page='ios.html', **cues):
    q = '&'.join([f'dur={b - a:.3f}'] + [f'{k}={v:.3f}' for k, v in cues.items()])
    f = os.path.abspath(f'{out}/anim/{scene}.mp4')
    subprocess.run(['node', 'render2.js', f'{scene}&{q}', f, '60'], cwd='../mockup', env={**os.environ, 'PAGE': page}, check=True, capture_output=True)
    return f
s1 = at("it's", 'IMG_9749') - 0.05; e1 = sec['IMG_9749'][1]
s2 = at('if', 'IMG_9751') - 0.05;    e2 = sec['IMG_9751'][1]
s3 = sec['IMG_9752'][0];             e3 = sec['IMG_9752'][1]
c_close = at('close', 'IMG_9752'); c_no = at('if', 'IMG_9752', nth=1)
appclip = os.path.abspath(f'{out}/anim/app_sale.mp4')   # real SalesMapper UI: tap Sale, pin turns green
# unzoomed app clip; Sale tap (3.15 s) through pin fully green (5.05 s) = 1.9 s, sped up to fit the window
APP_A, APP_B = 3.10, 5.10; win = c_no - c_close
speed = max(1.0, (APP_B - APP_A) / (win - 0.25))       # leave about 0.25 s hold on the green pin
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{APP_A}', '-t', f'{APP_B - APP_A}', '-i', '../mockup/out/app_tap_nozoom.mp4',
                '-vf', f'setpts=PTS/{speed:.4f},fps=30,tpad=stop_mode=clone:stop_duration=2', '-t', f'{win + 0.4:.3f}', '-an', '-c:v', 'libx264', '-crf', '14', appclip], check=True)
print('app speed', round(speed, 2))
done = {'notes': at('they', 'IMG_9749') - s1 + 0.95, 'imessage': min(at('it?', 'IMG_9751', 'e') - s2 - 0.05, (e2 - s2) - 1.05) + 0.65,
        'reminders': at('figure', 'IMG_9752') - s3 + 0.3}
for k, (d, w) in {'notes': (done['notes'], e1 - s1), 'imessage': (done['imessage'], e2 - s2), 'reminders': (done['reminders'], e3 - s3)}.items():
    assert d + 0.4 <= w + 1e-6, f'H6: {k} finishes at {d:.2f}s but window is {w:.2f}s'
    print(f'runtime ok: {k} done {d:.2f}s, window {w:.2f}s, hold {w - d:.2f}s')
ins = [(anim('notes', s1, e1, strike=at('spouse.', 'IMG_9749') - s1 if False else at('not', 'IMG_9749') - s1, type=at('they', 'IMG_9749') - s1), s1, e1),
       (anim('imessage', s2, e2, say=0.05, send=min(at('it?', 'IMG_9751', 'e') - s2 - 0.05, (e2 - s2) - 1.05)), s2, e2),
       (anim('reminders', s3, e3, get=at('get', 'IMG_9752') - s3, close=c_close - s3, no=c_no - s3, fig=at('figure', 'IMG_9752') - s3), s3, e3),
       (appclip, c_close - 0.05, c_no - 0.05)]
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

labels = []
n = 0
for c in order:
    txt = CLIPS[c][1]
    if txt is None: continue
    n += 1
    h = open('ov/label_tiktok.html').read().replace('LABEL', f'{n}. {txt}')
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
hide = ''.join(f"*not(gte(t,{x - half:.4f})*lt(t,{y - half:.4f}))" for _, x, y in ins)  # labels never cover phone/app screens
for j, (p, a, b) in enumerate(labels):
    extra = hide if 0 < j < len(labels) - 1 else ''
    fc.append(f"[{last}][{len(ins) + 1 + j}:v]overlay=0:0:enable='gte(t,{a - half:.4f})*lt(t,{b - half:.4f}){extra}'[t{j}]"); last = f't{j}'
import wave as _w
def _load(n):
    w = _w.open(f'sfx/{n}.wav'); return np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32768
SR = 48000; track = np.zeros(int((t + 1) * SR)); ev = []
def fx(at_, name, g):
    if at_ < 0: at_ = 0
    x = _load(name) * g; i = int(at_ * SR); track[i:i + len(x)] += x[:max(0, len(track) - i)]; ev.append((round(at_, 3), name))
G = dict(whoosh=.13, swoosh_send=.12, imsg_send=.7, pop=.11, pop_hi=.09, tap=.10, key0=.035, key1=.035, key2=.035, key3=.035, check=.12, drop=.14, strike=.07)
fx(0.0, 'pop', G['pop'])                                                    # hook card
cuts = sorted({round(a, 3) for _, a, _ in ins} | {round(b, 3) for _, _, b in ins})
on_screen = lambda tt: any(x - 1e-3 <= tt < y - 1e-3 for _, x, y in ins)
for c in cuts:   # F26: whoosh only on face <-> screen cuts, never screen -> screen or app in/out
    before, after = on_screen(c - 0.02), on_screen(c + 0.02)
    if before != after: fx(c - 0.23, 'whoosh', G['whoosh'] * (1.0 if after else .75))
for j, (p, a, b) in enumerate(labels[1:], 1):                                # labels that show over the face
    vis = not any(x - 1e-3 <= a < y - 1e-3 for _, x, y in ins)
    if vis: fx(a + 0.03, 'pop_hi', G['pop_hi'])
strike_c = at('not', 'IMG_9749') - s1; type_c = at('they', 'IMG_9749') - s1
fx(s1 + strike_c, 'strike', G['strike'])
rng = np.random.default_rng(3)
def keys(t0, t1, nchar):
    for q in range(nchar):
        if rng.random() < .15: continue
        fx(t0 + (t1 - t0) * q / nchar + rng.uniform(-.01, .01), f'key{rng.integers(4)}', G['key0'] * rng.uniform(.7, 1.1))
keys(s1 + type_c, s1 + type_c + 0.9, 26)
send_c = min(at('it?', 'IMG_9751', 'e') - s2 - 0.05, (e2 - s2) - 1.05)
keys(s2 + 0.05, s2 + send_c - 0.08, 43); fx(s2 + send_c - 0.02, 'imsg_send', G['imsg_send'])   # F26: clearly audible send
fx(s3 + (at('get', 'IMG_9752') - s3), 'check', G['check']); fx(at('figure', 'IMG_9752'), 'check', G['check'])
fx(c_close - 0.05 + 0.10 / speed, 'tap', G['tap']); fx(c_close - 0.05 + 1.25 / speed, 'drop', G['drop'])
with _w.open(f'{out}/sfx_track.wav', 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.clip(track, -1, 1) * 32767).astype(np.int16).tobytes())
json.dump(ev, open(f'{out}/sfx_events.json', 'w'))
print(len(ev), 'sfx events')
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv', '-af', 'highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000', f'{out}/voice.wav'], check=True)  # for QA_VOICE
args += ['-i', f'{out}/sfx_track.wav']; FX = len(ins) + len(labels) + 1
for kind in ['captions', 'clean']:
    tail = [f'[{last}]ass={out}/captions.ass:fontsdir=/root/.fonts[v]' if kind == 'captions' else f'[{last}]null[v]',
            '[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[vo]', f'[{FX}:a]aresample=48000[fx]',   # loudnorm runs at 192k: resample before mixing
            f'[vo][fx]amix=inputs=2:normalize=0:duration=longest,atrim=0:{t:.4f},alimiter=limit=0.95[a]']
    final = f'd2d_spouse_objection_{V}_sfx_{kind}.mp4'
    subprocess.run(args + ['-filter_complex', ';'.join(fc + tail), '-map', '[v]', '-map', '[a]', '-c:v', 'libx264', '-preset', 'slow', '-crf', '17',
                           '-pix_fmt', 'yuv420p', '-r', str(FPS), '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-movflags', '+faststart', final], check=True)
    print(final, round(t, 2), 's')
