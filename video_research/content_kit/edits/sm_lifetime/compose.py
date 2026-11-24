"""SalesMapper lifetime-trial video (F53). Run after cut.py in the same folder (needs seg/main.mov, seg/sec.json, lockf/ frames from
door_tools/cap_lock3.js, icon.png from salesmapper.ca, sm.html, YUNET model path in env).
Footage: original HLG pixels only re-framed (push-in 1.0->1.1 on the hook, 1.2x bottom-anchored after) by warping Y/U/V planes, no color math (H0).
Overlays: sRGB -> HLG (white at 88%), 100% opaque. Outputs: sm_lifetime_captions.mp4 + sm_lifetime_clean.mp4 (H13, Instagram only)."""
import json, os, subprocess, urllib.parse, wave, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS; W_, H_ = 1080, 1920
sec = json.load(open('seg/sec.json')); T = sec['C4'][1]
def run(a, **k): return subprocess.run(['ffmpeg', '-v', 'error', '-y'] + a, check=True, **k)
# ---------- framing
HOOK_END = sec['HOOK'][1]; FACE = (457, 900)            # hook face centre (YuNet mean)
def xform(t):
    if t < HOOK_END:
        u = t / HOOK_END; s = 1.0 + 0.1 * (u * u * (3 - 2 * u)); return s, FACE[0] * (1 - s), FACE[1] * (1 - s)
    return 1.2, W_ / 2 * (1 - 1.2), H_ * (1 - 1.2)
# ---------- chin per section, measured on the re-framed picture
det = cv2.FaceDetectorYN.create(os.environ.get('YUNET', 'yunet.onnx'), '', (540, 960), 0.7)
def chin(t):
    r = run(['-ss', f'{t:.3f}', '-i', 'seg/main.mov', '-frames:v', '1', '-vf', 'scale=540:960', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-'], capture_output=True).stdout
    _, f = det.detect(np.frombuffer(r, np.uint8).reshape(960, 540, 3))
    if f is None: return None
    s, tx, ty = xform(t); return s * (f[0][1] + f[0][3]) * 2 + ty
CH = {}
for k, (a, b) in sec.items():
    c = [x for x in (chin(t) for t in np.arange(a + 0.02, b - 0.02, 0.1)) if x]; CH[k] = int(max(c)) if c else 1200
print('chin', CH)
top = lambda k: CH[k] + 24
# ---------- word timings (output seconds; re-transcribed from the cut, F46/F52 checked by ear-waveform)
HOOKW = [("There's", 0.0), ('one', .2), ('disgustingly', .36), ('simple', 1.18), ('thing', 1.42), ('I', 1.68), ('do', 1.96), ('to', 2.12), ('convert', 2.24),
         ('doors', 2.46), ('3x', 2.72), ('more', 3.36), ('efficiently', 3.54), ('than', 3.88), ('my', 4.12), ('competition', 4.28), ('and', 4.76), ('you', 5.1),
         ('can', 5.3), ('do', 5.46), ('it', 5.62), ('too.', 5.74)]
E0 = sec['E4'][0]; C0 = sec['C4'][0]
E4W = [("It's", E0), ('an', 10.55), ('absolute', 10.63), ('cheat', 11.07), ('code', 11.39), ('for', 11.67), ('door-to-door', 11.85), ('teams,', 12.19), ('reps', 12.79), ('knock', 12.93)]
C4W = [('They', C0), ('have', 17.47)]
CUE = dict(rev=sec['REV'][0], lock=sec['L4'][0], face=E0, s43=13.19, s50=16.27, free=17.5, comment=20.4, tap=sec['L4'][0] + 72 / 30, drop=sec['L4'][0] + 82 / 30)
# ---------- overlay states: (query dict or ('demo', frame)), start, end
def states(captions):
    S = []
    hook = dict(hl='One disgustingly simple thing', ht='3x more doors converted')
    capy = CH['HOOK'] + 30
    for i, (w, t) in enumerate(HOOKW):
        e = HOOKW[i + 1][1] if i + 1 < len(HOOKW) else HOOK_END
        q = dict(hook); q.update(dict(w=w, cy=capy) if captions else {}); S.append((q, t, e))
    S.append((dict(k='rev', y=top('REV')), CUE['rev'], CUE['lock']))
    n0 = round(CUE['lock'] * FPS)
    for i in range(round(CUE['face'] * FPS) - n0): S.append((('demo', i), (n0 + i) / FPS, (n0 + i + 1) / FPS))
    if captions:
        for i, (w, t) in enumerate(E4W):
            e = E4W[i + 1][1] if i + 1 < len(E4W) else CUE['s43']
            S.append((dict(w=w.replace('door-to-door', 'door-to-door'), cy=top('E4')), max(t, CUE['face']), e))
    S.append((dict(k='stats', n=1, y=top('E4')), CUE['s43'], CUE['s50']))
    S.append((dict(k='stats', n=2, y=top('E4')), CUE['s50'], C0))
    if captions:
        for i, (w, t) in enumerate(C4W):
            S.append((dict(w=w, cy=top('C4')), t, C4W[i + 1][1] if i + 1 < len(C4W) else CUE['free']))
    S.append((dict(k='sub', y=top('C4')), CUE['free'], CUE['comment']))
    S.append((dict(k='sub', y=top('C4'), cta='comment MAP', ctay=top('C4') + 560), CUE['comment'], T))
    return [(q, F(a), F(b)) for q, a, b in S if F(b) > F(a)]
# ---------- render PNGs
os.makedirs('png', exist_ok=True); uniq = {}
for cap in (True, False):
    for q, a, b in states(cap):
        if isinstance(q, dict): uniq[urllib.parse.urlencode(q)] = None
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
for i, qs in enumerate(uniq):
    uniq[qs] = f'png/q{i:03d}.png'
    js += f"await p.goto('file://'+path.resolve('sm.html')+'?{qs}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(60); await p.screenshot({{path:'{uniq[qs]}',omitBackground:true}});\n"
open('png/r.js', 'w').write(js + "await b.close();})();"); subprocess.run(['node', 'png/r.js'], check=True)
# ---------- sRGB -> HLG (BT.2408 style, white at 88% signal per F38; red CTA as wide gamut per F40)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073; E = (np.exp((0.88 - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def hlg(rgb, al, wide=None):
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    l2 = lin @ M.T
    if wide is not None: l2[wide] = lin[wide]
    l2 *= E; e = np.where(l2 <= 1 / 12, np.sqrt(3 * np.clip(l2, 0, None)), a_ * np.log(np.clip(12 * l2 - b_, 1e-9, None)) + c_)
    return (np.dstack([np.clip(e, 0, 1)[..., ::-1], al]) * 65535).round().astype(np.uint16)
os.makedirs('hl', exist_ok=True); HL = {}
for qs, f in uniq.items():
    im = cv2.imread(f, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]
    red = (rgb[..., 0] > .9) & (rgb[..., 1] < .2) & (rgb[..., 2] < .3) if 'cta=' in qs else None
    HL[qs] = f'hl/{os.path.basename(f)}'; cv2.imwrite(HL[qs], hlg(rgb, im[..., 3], red))
# demo: lock-screen phone full height until just after the tap, then the map phone for the pin drop (F53: phones large)
BG = np.array([236, 243, 246]) / 255
for i in range(100):
    fr = cv2.imread(f'lockf/{i:05d}.png')
    crop = fr[33:1118, 183:698] if i < 80 else fr[33:1118, 749:1263]
    h = 1780; w = round(crop.shape[1] * h / crop.shape[0]); ph = cv2.resize(crop, (w, h), interpolation=cv2.INTER_LANCZOS4)
    can = np.empty((H_, W_, 3)); can[:] = BG[::-1]; x0, y0 = (W_ - w) // 2, (H_ - h) // 2
    can[y0:y0 + h, x0:x0 + w] = ph / 255
    cv2.imwrite(f'hl/d{i:03d}.png', hlg(can[..., ::-1], np.ones((H_, W_))))
cv2.imwrite('hl/blank.png', np.zeros((H_, W_, 4), np.uint16))
def ovlist(name, S):
    with open(f'hl/{name}.txt', 'w') as L:
        cur = 0.0
        for q, a, b in S:
            f = f'd{q[1]:03d}.png' if isinstance(q, tuple) else os.path.basename(HL[urllib.parse.urlencode(q)])
            if a > cur + 1e-3: L.write(f"file 'blank.png'\nduration {a - cur:.4f}\n")
            L.write(f"file '{f}'\nduration {b - a:.4f}\n"); cur = b
        L.write(f"file 'blank.png'\nduration {T - cur + 0.5:.4f}\nfile 'blank.png'\n")
ovlist('cap', states(True)); ovlist('clean', states(False))
# ---------- re-frame the footage: warp each 10-bit plane (no colour conversion)
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
dec = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', 'seg/main.mov', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-'], stdout=subprocess.PIPE)
enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-s', f'{W_}x{H_}', '-r', '30', '-i', '-', '-i', 'seg/main.mov', '-map', '0:v', '-map', '1:a',
                        '-c:v', 'libx265', '-preset', 'medium', '-crf', '10', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['-c:a', 'copy', 'zoom.mov'], stdin=subprocess.PIPE)
ys, cs = W_ * H_, W_ * H_ // 4; n = 0
while True:
    buf = dec.stdout.read((ys + 2 * cs) * 2)
    if len(buf) < (ys + 2 * cs) * 2: break
    a = np.frombuffer(buf, np.uint16); s, tx, ty = xform(n / FPS); out = []
    for pl, (w, h), k in ((a[:ys], (W_, H_), 1), (a[ys:ys + cs], (W_ // 2, H_ // 2), 2), (a[ys + cs:], (W_ // 2, H_ // 2), 2)):
        m = np.float32([[s, 0, tx / k], [0, s, ty / k]])
        out.append(cv2.warpAffine(pl.reshape(h, w), m, (w, h), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REPLICATE).tobytes())
    enc.stdin.write(b''.join(out)); n += 1
enc.stdin.close(); enc.wait(); dec.wait(); print('reframed', n, 'frames')
# ---------- subtle SFX (H15), placed on the same cues as the graphics
SFX = os.environ.get('SFX', '../../sfx/')
cues = [('pop', 0.02, .8), ('pop_hi', CUE['rev'], .8), ('whoosh', CUE['lock'] - 0.2, .8), ('tap', CUE['tap'], .9), ('drop', CUE['drop'], .9),
        ('whoosh', CUE['face'] - 0.2, .5), ('pop', CUE['s43'], .8), ('pop', CUE['s50'], .8), ('pop', CUE['free'], .8), ('pop_hi', CUE['comment'], .8)]
inp, fl = ['-i', 'zoom.mov'], []
for i, (nm, t, g) in enumerate(cues):
    inp += ['-i', f'{SFX}{nm}.wav']; fl.append(f"[{i + 1}:a]aresample=48000,aformat=channel_layouts=stereo,volume={g * 0.25:.3f},adelay={int(t * 1000)}|{int(t * 1000)}[s{i}]")
mix = (';'.join(fl) + ';[0:a]loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[v];[v]' + ''.join(f'[s{i}]' for i in range(len(cues))) +
       f'amix=inputs={len(cues) + 1}:normalize=0:duration=first,atrim=0:{T:.3f},alimiter=limit=0.95[a]')
run(inp + ['-filter_complex', mix, '-map', '[a]', '-c:a', 'pcm_s16le', 'mix.wav'])
# ---------- composite
for name, outf in (('cap', 'sm_lifetime_captions.mp4'), ('clean', 'sm_lifetime_clean.mp4')):
    fc = ("[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];[0:v][ov]overlay=format=yuv420p10:eof_action=pass[v]")
    run(['-i', 'zoom.mov', '-f', 'concat', '-safe', '0', '-i', f'hl/{name}.txt', '-i', 'mix.wav', '-filter_complex', fc, '-map', '[v]', '-map', '2:a',
         '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
        ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', outf])
    print('done', outf, round(T, 2), 's')
