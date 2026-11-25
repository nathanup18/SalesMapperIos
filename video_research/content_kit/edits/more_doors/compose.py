"""More doors = less money reel (F71). Nathan cut out (rembg masks, his original HLG pixels, no colour math) over a photo per section;
hook: 3 photo tiles above his head over a blurred copy of his own room. Header + one-word captions in TikTok classic text.
Run in the work dir after cut.py: needs seg/main.mov, seg/sec.json, outwords.json, face.json, masks/, the photos + ov.html, env LUT and SFX."""
import json, os, subprocess, urllib.parse, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS; W_, H_ = 1080, 1920
sec = json.load(open('seg/sec.json')); T = sec['CLOSE'][1]; NF = round(T * FPS)
WD = json.load(open('outwords.json')); FC = json.load(open('face.json'))
def run(a, **k): return subprocess.run(['ffmpeg', '-v', 'error', '-y'] + a, check=True, **k)
wt = lambda k, w: next(x['s'] for x in WD if x['k'] == k and x['w'].lower().startswith(w))
# ---------- shots: (start, photo or None for blurred room, person scale a->b)
BUT, GO = wt('R1', 'but'), wt('PAY', 'go')
SHOTS = [(0, None, .78, .84), (sec['LOOP'][0], 'rep.png', .88, .88), (sec['R1'][0], 'p6.png', .80, .80), (BUT - 0.03, 'p5.png', .88, .88),
         (sec['R2'][0], 'p5.png', .80, .80), (sec['PAY'][0], 'p3.png', .88, .88), (GO - 0.03, 'c_fill.png', .80, .80), (sec['CLOSE'][0], 'p1.png', .88, .88)]
SHOTS = [(F(a), p, s0, s1) for a, p, s0, s1 in SHOTS]
def shot(t):
    i = max(j for j, s in enumerate(SHOTS) if s[0] <= t + 1e-6); a = SHOTS[i][0]; b = SHOTS[i + 1][0] if i + 1 < len(SHOTS) else T
    u = (t - a) / (b - a); return i, SHOTS[i][1], SHOTS[i][2] + (SHOTS[i][3] - SHOTS[i][2]) * (u * u * (3 - 2 * u)), u
def sec_of(t): return max((k for k, v in sec.items() if v[0] <= t + 1e-6), key=lambda k: sec[k][0])
# ---------- overlay states
def cy(t):                                                          # caption top: under the chin of the cut-out at its scale
    _, _, s, _ = shot(t); return int(H_ - (H_ - FC[sec_of(t)]['chin']) * s) + 26
FOLLOW = wt('CLOSE', 'follow')
def states(cap):
    S = []; ws = [x for x in WD if x['s'] < FOLLOW - 1e-3]
    tl = [(0, 1), (F(wt('HOOK', 'doors')), 2), (F(wt('HOOK', 'money')), 3)]
    for i, x in enumerate(ws):
        a, b = x['s'], (ws[i + 1]['s'] if i + 1 < len(ws) else FOLLOW)
        if x['k'] == 'HOOK': a = 0.0 if i == 0 else a
        q = {}
        if x['k'] == 'HOOK':
            q.update(hd='Knocking more doors is making you less money', tiles=max(n for t0, n in tl if t0 <= a + 1e-6))
        if cap: q.update(w=x['w'].replace('1pm', '1 PM').replace('three', '3').replace('eight', '8'), cy=cy(a))
        if q: S.append((q, a, b))
    ctay = max(960, int(H_ - (H_ - FC['CLOSE']['chin']) * .88) + 26)
    S.append((dict(cta='follow for more', ctay=ctay), FOLLOW, T))
    out = []                                                        # split hook states where a tile pops mid-word
    for q, a, b in S:
        cuts = [t0 for t0, _ in tl if a < t0 < b] if 'tiles' in q else []
        pts = [a] + cuts + [b]
        for x0, x1 in zip(pts, pts[1:]):
            q2 = dict(q)
            if 'tiles' in q: q2['tiles'] = max(n for t0, n in tl if t0 <= x0 + 1e-6)
            out.append((q2, F(x0), F(x1)))
    return [s for s in out if s[2] > s[1]]
os.makedirs('png', exist_ok=True); uniq = {}
for c in (True, False):
    for q, a, b in states(c): uniq[urllib.parse.urlencode(q)] = None
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
for i, qs in enumerate(uniq):
    uniq[qs] = f'png/q{i:03d}.png'
    js += f"await p.goto('file://'+path.resolve('ov.html')+'?{qs}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(80); await p.screenshot({{path:'{uniq[qs]}',omitBackground:true}});\n"
open('png/r.js', 'w').write(js + "await b.close();})();"); subprocess.run(['node', 'png/r.js'], check=True)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073; E = (np.exp((0.88 - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def hlg(rgb, al, wide=None):
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4); l2 = lin @ M.T
    if wide is not None: l2[wide] = lin[wide]
    l2 *= E; e = np.where(l2 <= 1 / 12, np.sqrt(3 * np.clip(l2, 0, None)), a_ * np.log(np.clip(12 * l2 - b_, 1e-9, None)) + c_)
    return (np.dstack([np.clip(e, 0, 1)[..., ::-1], al]) * 65535).round().astype(np.uint16)
os.makedirs('hl', exist_ok=True); HL = {}
for qs, f in uniq.items():
    im = cv2.imread(f, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]
    red = ((rgb[..., 0] > .85) & (rgb[..., 1] < .2) & (rgb[..., 2] < .3)) if 'cta=' in qs else None
    HL[qs] = f'hl/{os.path.basename(f)}'; cv2.imwrite(HL[qs], hlg(rgb, im[..., 3], red))
cv2.imwrite('hl/blank.png', np.zeros((H_, W_, 4), np.uint16))
def ovlist(name, S):
    with open(f'hl/{name}.txt', 'w') as L:
        cur = 0.0
        for q, a, b in S:
            a = max(a, cur)
            if b <= a: continue
            if a > cur + 1e-3: L.write(f"file 'blank.png'\nduration {a - cur:.4f}\n")
            L.write(f"file '{os.path.basename(HL[urllib.parse.urlencode(q)])}'\nduration {b - a:.4f}\n"); cur = b
        L.write(f"file 'blank.png'\nduration {T - cur + 0.5:.4f}\nfile 'blank.png'\n")
ovlist('cap', states(True)); ovlist('clean', states(False))
# ---------- background photos: cover-crop to 9:16, SDR -> HLG through the 0.88-white LUT (F50), kept as 10-bit planes
LUT = os.environ.get('LUT', 'sdr2hlg_bright.cube'); YS, CS = W_ * H_, W_ * H_ // 4; FB = (YS + 2 * CS) * 2
def planes(buf):
    a = np.frombuffer(buf, np.uint16); return [a[:YS].reshape(H_, W_), a[YS:YS + CS].reshape(H_ // 2, W_ // 2), a[YS + CS:].reshape(H_ // 2, W_ // 2)]
PH = {}
for p in {s[1] for s in SHOTS if s[1]}:
    im = cv2.imread(p); s = max(W_ / im.shape[1], H_ / im.shape[0]) * 1.06              # 6% headroom for the slow push
    im = cv2.resize(im, (round(im.shape[1] * s), round(im.shape[0] * s)), interpolation=cv2.INTER_LANCZOS4)
    y0, x0 = (im.shape[0] - H_) // 2, (im.shape[1] - W_) // 2; cv2.imwrite('bgtmp.png', im[y0:y0 + H_, x0:x0 + W_])
    r = run(['-i', 'bgtmp.png', '-vf', f"format=rgb48le,lut3d={LUT},scale=out_color_matrix=bt2020:out_range=tv,format=yuv420p10le", '-f', 'rawvideo', '-'], capture_output=True).stdout
    PH[p] = [x.copy() for x in planes(r)]
def zoomp(pl, z, k):                                                # slow push-in on the photo, subpixel
    h, w = pl.shape; m = np.float32([[z, 0, w / 2 * (1 - z)], [0, z, h / 2 * (1 - z)]])
    return cv2.warpAffine(pl, m, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
# ---------- frame loop
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
dec = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', 'seg/main.mov', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-'], stdout=subprocess.PIPE)
enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-s', f'{W_}x{H_}', '-r', '30', '-i', '-', '-i', 'seg/main.mov', '-map', '0:v', '-map', '1:a',
                        '-c:v', 'libx265', '-preset', 'medium', '-crf', '10', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['-c:a', 'copy', 'base.mov'], stdin=subprocess.PIPE)
for n in range(NF):
    buf = dec.stdout.read(FB)
    if len(buf) < FB: break
    t = n / FPS; i, photo, s, u = shot(t); P = planes(buf)
    if photo: B = [zoomp(pl, 1.0 + 0.05 * u, k) for k, pl in zip((1, 2, 2), PH[photo])]
    else: B = [cv2.resize(cv2.GaussianBlur(cv2.resize(pl, (pl.shape[1] // 8, pl.shape[0] // 8), interpolation=cv2.INTER_AREA), (0, 0), 4), (pl.shape[1], pl.shape[0]), interpolation=cv2.INTER_LINEAR) for pl in P]
    mk = cv2.imread(f'masks/{n:05d}.png', cv2.IMREAD_GRAYSCALE)
    mk = cv2.GaussianBlur(np.clip((cv2.resize(mk, (W_, H_), interpolation=cv2.INTER_CUBIC).astype(np.float32) - 30) * 1.25, 0, 255), (0, 0), 1.2) / 255
    out = []
    for k, (pl, bg) in enumerate(zip(P, B)):
        kk = 1 if k == 0 else 2; h, w = pl.shape
        m = np.float32([[s, 0, w / 2 * (1 - s)], [0, s, h * (1 - s)]])        # bottom-centred scale
        pp = cv2.warpAffine(pl, m, (w, h), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REPLICATE).astype(np.float32)
        mm = cv2.warpAffine(cv2.resize(mk, (w, h), interpolation=cv2.INTER_AREA), m, (w, h), flags=cv2.INTER_LINEAR)
        out.append(np.clip(bg.astype(np.float32) * (1 - mm) + pp * mm + 0.5, 0, 1023).astype(np.uint16).tobytes())
    enc.stdin.write(b''.join(out))
enc.stdin.close(); enc.wait(); dec.kill(); print('frames done')
# ---------- audio: highpass 70 + loudnorm -14 (section 2) + subtle SFX on the same cues (H15)
SFX = os.environ.get('SFX', '../../sfx/')
cues = [('pop', 0.02, .8), ('pop', F(wt('HOOK', 'doors')), .7), ('pop', F(wt('HOOK', 'money')), .7)] + \
       [('whoosh', a - 0.15, .45) for a, p, _, _ in SHOTS[1:]] + [('pop_hi', FOLLOW, .8)]
inp, fl = ['-i', 'base.mov'], []
for i, (nm, t, g) in enumerate(cues):
    inp += ['-i', f'{SFX}{nm}.wav']; fl.append(f"[{i + 1}:a]aresample=48000,aformat=channel_layouts=stereo,volume={g * 0.25:.3f},adelay={int(max(0, t) * 1000)}|{int(max(0, t) * 1000)}[s{i}]")
mix = (';'.join(fl) + ';[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[v];[v]' + ''.join(f'[s{i}]' for i in range(len(cues))) +
       f'amix=inputs={len(cues) + 1}:normalize=0:duration=first,atrim=0:{T:.3f},alimiter=limit=0.95[a]')
run(inp + ['-filter_complex', mix, '-map', '[a]', '-c:a', 'pcm_s16le', 'mix.wav'])
for name, outf in (('cap', 'more_doors_captions.mp4'), ('clean', 'more_doors_clean.mp4')):
    fc = "[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];[0:v][ov]overlay=format=yuv420p10:eof_action=pass[v]"
    run(['-i', 'base.mov', '-f', 'concat', '-safe', '0', '-i', f'hl/{name}.txt', '-i', 'mix.wav', '-filter_complex', fc, '-map', '[v]', '-map', '2:a',
         '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
        ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', outf])
    print('done', outf, round(T, 2), 's')
