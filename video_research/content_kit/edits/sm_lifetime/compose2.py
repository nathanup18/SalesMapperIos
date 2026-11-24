"""SalesMapper lifetime-trial video v2 (F56): tools-video style. Full-screen real app visuals from salesmapper.ca (knock.mp4, shift demo
via door_tools/cap_lock3.js, img/4-stats.jpg) with Nathan cut out in a lower corner (rembg u2net_human_seg masks, original HDR pixels),
black hook header + white tool label with red subtitle (door_tools/text.html look), one-word captions on face shots.
Run after cut.py. Needs: seg/main.mov, seg/sec.json, lockf/ (cap_lock3.js lockf -0.46 100), masks/ (segm.py), knock.mp4, stats.jpg,
icon.png, sm.html, env YUNET (face model), LUT (door_tools/sdr2hlg_bright.cube), SFX (content_kit/sfx/)."""
import json, os, subprocess, urllib.parse, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS; W_, H_ = 1080, 1920
sec = json.load(open('seg/sec.json')); T = sec['C4'][1]; NF = round(T * FPS)
def run(a, **k): return subprocess.run(['ffmpeg', '-v', 'error', '-y'] + a, check=True, **k)
L0 = sec['L4'][0]; TAP = L0 + 72 / FPS; DROP = L0 + 82 / FPS
A0, LOCK0, FACE1 = sec['REV'][0], F(TAP - 0.9), sec['E4'][0]       # F54: tap lands 0.9 s after the demo appears
ST0, C0 = F(13.19 - 0.05), sec['C4'][0]
HOOK_END = sec['HOOK'][1]
def mode(t):
    if A0 <= t < LOCK0 or ST0 <= t < C0: return 'app'
    if LOCK0 <= t < FACE1: return 'lock'
    return 'face'
FACE = (457, 900)
def xform(t):                                                       # hook push-in 1.0->1.1, then alternate 100% / 120% per face shot (H14)
    if t < HOOK_END:
        u = t / HOOK_END; s = 1.0 + 0.1 * (u * u * (3 - 2 * u)); return s, FACE[0] * (1 - s), FACE[1] * (1 - s)
    if FACE1 <= t < ST0: return 1.0, 0.0, 0.0
    return 1.2, W_ / 2 * (1 - 1.2), H_ * (1 - 1.2)
# ---------- chin per face shot (on the re-framed picture)
det = cv2.FaceDetectorYN.create(os.environ.get('YUNET', 'yunet.onnx'), '', (540, 960), 0.7)
def chin(t):
    r = run(['-ss', f'{t:.3f}', '-i', 'seg/main.mov', '-frames:v', '1', '-vf', 'scale=540:960', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-'], capture_output=True).stdout
    _, f = det.detect(np.frombuffer(r, np.uint8).reshape(960, 540, 3))
    if f is None: return None
    s, tx, ty = xform(t); return s * (f[0][1] + f[0][3]) * 2 + ty
def maxchin(a, b): c = [x for x in (chin(t) for t in np.arange(a + 0.02, b - 0.02, 0.1)) if x]; return int(max(c)) if c else 1200
CH = dict(HOOK=maxchin(0, HOOK_END), E4=maxchin(FACE1, ST0), C4=maxchin(C0, T)); print('chin', CH)
# ---------- overlay states
HOOKW = [("There's", 0.0), ('one', .2), ('disgustingly', .36), ('simple', 1.18), ('thing', 1.42), ('I', 1.68), ('do', 1.96), ('to', 2.12), ('convert', 2.24),
         ('doors', 2.46), ('3x', 2.72), ('more', 3.36), ('efficiently', 3.54), ('than', 3.88), ('my', 4.12), ('competition', 4.28), ('and', 4.76), ('you', 5.1),
         ('can', 5.3), ('do', 5.46), ('it', 5.62), ('too.', 5.74)]
E4W = [("It's", FACE1), ('an', 10.55), ('absolute', 10.63), ('cheat', 11.07), ('code', 11.39), ('for', 11.67), ('door-to-door', 11.85), ('teams,', 12.19), ('reps', 12.79), ('knock', 12.93)]
C4W = [('They', C0), ('have', 17.47)]
FREE, COMMENT = 17.5, 20.4
HD = dict(hdt='One disgustingly simple thing', hds='(converts 3x more doors)')
def words(S, W, end, cy, base={}):
    for i, (w, t) in enumerate(W):
        q = dict(base); q.update(w=w, cy=cy); S.append((q, t, W[i + 1][1] if i + 1 < len(W) else end))
def states(cap):
    S = []
    if cap: words(S, HOOKW, HOOK_END, CH['HOOK'] + 30, HD)
    else: S.append((dict(HD), 0, HOOK_END))
    S.append((dict(lt='SalesMapper', ld='door-to-door canvassing app'), A0, LOCK0))
    if cap: words(S, E4W, ST0, CH['E4'] + 30)
    S.append((dict(lt='SalesMapper', ld='43% more doors · 50% more sales', k='stats', n=1, top=1, y=380), 13.19, 16.27))
    S.append((dict(lt='SalesMapper', ld='43% more doors · 50% more sales', k='stats', n=2, top=1, y=380), 16.27, C0))
    S.append((dict(lt='SalesMapper', ld='43% more doors · 50% more sales'), ST0, 13.19))
    if cap: words(S, C4W, FREE, CH['C4'] + 30)
    S.append((dict(k='sub', y=CH['C4'] + 24), FREE, COMMENT))
    S.append((dict(k='sub', y=CH['C4'] + 24, cta='comment MAP', ctay=CH['C4'] + 584), COMMENT, T))
    S = sorted([(q, F(a), F(b)) for q, a, b in S if F(b) > F(a)], key=lambda x: x[1]); return S
os.makedirs('png2', exist_ok=True); uniq = {}
for cap in (True, False):
    for q, a, b in states(cap): uniq[urllib.parse.urlencode(q)] = None
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
for i, qs in enumerate(uniq):
    uniq[qs] = f'png2/q{i:03d}.png'
    js += f"await p.goto('file://'+path.resolve('sm.html')+'?{qs}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(60); await p.screenshot({{path:'{uniq[qs]}',omitBackground:true}});\n"
open('png2/r.js', 'w').write(js + "await b.close();})();"); subprocess.run(['node', 'png2/r.js'], check=True)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073; E = (np.exp((0.88 - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def hlg(rgb, al, wide=None):
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4); l2 = lin @ M.T
    if wide is not None: l2[wide] = lin[wide]
    l2 *= E; e = np.where(l2 <= 1 / 12, np.sqrt(3 * np.clip(l2, 0, None)), a_ * np.log(np.clip(12 * l2 - b_, 1e-9, None)) + c_)
    return (np.dstack([np.clip(e, 0, 1)[..., ::-1], al]) * 65535).round().astype(np.uint16)
os.makedirs('hl2', exist_ok=True); HL = {}
for qs, f in uniq.items():
    im = cv2.imread(f, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]
    red = ((rgb[..., 0] > .85) & (rgb[..., 1] < .2) & (rgb[..., 2] < .3)) if ('cta=' in qs or 'lt=' in qs) else None
    HL[qs] = f'hl2/{os.path.basename(f)}'; cv2.imwrite(HL[qs], hlg(rgb, im[..., 3], red))
cv2.imwrite('hl2/blank.png', np.zeros((H_, W_, 4), np.uint16))
def ovlist(name, S):
    with open(f'hl2/{name}.txt', 'w') as L:
        cur = 0.0
        for q, a, b in S:
            a = max(a, cur)
            if b <= a: continue
            if a > cur + 1e-3: L.write(f"file 'blank.png'\nduration {a - cur:.4f}\n")
            L.write(f"file '{os.path.basename(HL[urllib.parse.urlencode(q)])}'\nduration {b - a:.4f}\n"); cur = b
        L.write(f"file 'blank.png'\nduration {T - cur + 0.5:.4f}\nfile 'blank.png'\n")
ovlist('cap', states(True)); ovlist('clean', states(False))
# ---------- SDR backdrops for app/lock frames (real salesmapper.ca visuals), then SDR -> HLG with the 0.88-white LUT (F50)
cap_ = cv2.VideoCapture('knock.mp4'); KN = []
while True:
    ok, fr = cap_.read()
    if not ok: break
    KN.append(fr)
kfps = len(KN) / 4.733
def app_frame(fr):                                                   # door_tools app(): full height, blurred fill, no dimming
    h = H_; w = round(fr.shape[1] * h / fr.shape[0]); ph = cv2.resize(fr, (w, h), interpolation=cv2.INTER_LANCZOS4)
    bg = cv2.GaussianBlur(cv2.resize(fr, (W_, H_)), (0, 0), 30); x0 = (W_ - w) // 2; bg[:, x0:x0 + w] = ph; return bg
ST = cv2.imread('stats.jpg'); BGC = np.array([246, 243, 236], np.uint8)
def stats_frame(t):
    u = (t - ST0) / (C0 - ST0); s0 = H_ / ST.shape[0]; s = s0 * (1 + 0.08 * (u * u * (3 - 2 * u)))
    px, py = ST.shape[1] * 0.5, ST.shape[0] * 0.30                  # drift toward the Revenue / Sales / Doors block
    ty = min(0, max(H_ - ST.shape[0] * s, H_ * 0.40 - py * s))
    m = np.float32([[s, 0, W_ / 2 - px * s], [0, s, ty]])
    return cv2.warpAffine(ST, m, (W_, H_), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_CONSTANT, borderValue=BGC.tolist())
LBG = np.array([246, 243, 236])
def lock_frame(t):
    i = min(99, max(0, round((t - L0) * FPS))); fr = cv2.imread(f'lockf/{i:05d}.png')
    crop = fr[33:1118, 183:698] if i < 80 else fr[33:1118, 749:1263]
    h = 1780; w = round(crop.shape[1] * h / crop.shape[0]); ph = cv2.resize(crop, (w, h), interpolation=cv2.INTER_LANCZOS4)
    can = np.empty((H_, W_, 3), np.uint8); can[:] = LBG; x0, y0 = (W_ - w) // 2, (H_ - h) // 2; can[y0:y0 + h, x0:x0 + w] = ph; return can
os.makedirs('bgf', exist_ok=True); bgidx = []
for n in range(NF):
    t = n / FPS; md = mode(t)
    if md == 'face': continue
    if md == 'lock': fr = lock_frame(t)
    elif t < LOCK0: fr = app_frame(KN[min(len(KN) - 1, int((0.3 + (t - A0) * 4.3 / (LOCK0 - A0)) * kfps))])
    else: fr = stats_frame(t)
    cv2.imwrite(f'bgf/{len(bgidx):05d}.png', fr); bgidx.append(n)
LUT = os.environ.get('LUT', 'sdr2hlg_bright.cube')
bgdec = subprocess.Popen(['ffmpeg', '-v', 'error', '-framerate', '30', '-i', 'bgf/%05d.png', '-vf',
                          f"format=rgb48le,lut3d={LUT},scale=out_color_matrix=bt2020:out_range=tv,format=yuv420p10le",
                          '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-'], stdout=subprocess.PIPE)
# ---------- frame loop: face shots warped (no colour math), app shots = backdrop + Nathan cut out from his original HDR pixels
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
dec = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', 'seg/main.mov', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-'], stdout=subprocess.PIPE)
enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-s', f'{W_}x{H_}', '-r', '30', '-i', '-', '-i', 'seg/main.mov', '-map', '0:v', '-map', '1:a',
                        '-c:v', 'libx265', '-preset', 'medium', '-crf', '10', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['-c:a', 'copy', 'zoom2.mov'], stdin=subprocess.PIPE)
YS, CS = W_ * H_, W_ * H_ // 4; FB = (YS + 2 * CS) * 2
SC, PW, PH = 0.55, 594, 1056; PY = H_ - PH + 60
def planes(buf):
    a = np.frombuffer(buf, np.uint16); return [a[:YS].reshape(H_, W_), a[YS:YS + CS].reshape(H_ // 2, W_ // 2), a[YS + CS:].reshape(H_ // 2, W_ // 2)]
def paste(dst, src, al, x, y, k):                                    # alpha-blend src into dst at (x, y) with clipping
    x, y = x // k, y // k; h, w = src.shape; x0, y0 = max(0, x), max(0, y); x1, y1 = min(dst.shape[1], x + w), min(dst.shape[0], y + h)
    if x1 <= x0 or y1 <= y0: return
    s = src[y0 - y:y1 - y, x0 - x:x1 - x].astype(np.float32); m = al[y0 - y:y1 - y, x0 - x:x1 - x]
    d = dst[y0:y1, x0:x1].astype(np.float32); dst[y0:y1, x0:x1] = np.clip(d * (1 - m) + s * m + 0.5, 0, 1023).astype(np.uint16)
for n in range(NF):
    buf = dec.stdout.read(FB)
    if len(buf) < FB: break
    t = n / FPS; md = mode(t); P = planes(buf)
    if md == 'face':
        s, tx, ty = xform(t); out = []
        for pl, k in zip(P, (1, 2, 2)):
            h, w = pl.shape; m = np.float32([[s, 0, tx / k], [0, s, ty / k]])
            out.append(cv2.warpAffine(pl, m, (w, h), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REPLICATE).tobytes())
        enc.stdin.write(b''.join(out)); continue
    B = [p.copy() for p in planes(bgdec.stdout.read(FB))]
    if md == 'app':
        mk = cv2.imread(f'masks/{n:05d}.png', cv2.IMREAD_GRAYSCALE)
        mk = cv2.GaussianBlur(np.clip((cv2.resize(mk, (W_, H_), interpolation=cv2.INTER_CUBIC).astype(np.float32) - 30) * 1.25, 0, 255), (0, 0), 1.2) / 255
        X0 = 536 if t < LOCK0 else -50                                # alternates corner per section (door_tools xexpr)
        for k, (pl, nb) in enumerate(zip(P, B)):
            kk = 1 if k == 0 else 2; w, h = PW // kk, PH // kk
            p = cv2.resize(pl, (w, h), interpolation=cv2.INTER_AREA); m = cv2.resize(mk, (w, h), interpolation=cv2.INTER_AREA)
            sh = cv2.GaussianBlur(m, (0, 0), 22 / kk) * 0.5                 # soft shadow
            paste(nb, np.full_like(p, 64 if k == 0 else 512), sh, X0 + 14, PY + 18, kk)
            paste(nb, p, m, X0, PY, kk)
    enc.stdin.write(b''.join(x.tobytes() for x in B))
enc.stdin.close(); enc.wait(); dec.wait(); bgdec.wait(); print('frames done')
# ---------- SFX (H15) + audio chain (highpass 70, loudnorm -14)
SFX = os.environ.get('SFX', '../../sfx/')
cues = [('pop', 0.02, .8), ('whoosh', A0 - 0.2, .8), ('pop_hi', A0, .7), ('tap', TAP, .9), ('drop', DROP, .9), ('whoosh', FACE1 - 0.2, .5),
        ('whoosh', ST0 - 0.2, .8), ('pop', 13.19, .8), ('pop', 16.27, .8), ('whoosh', C0 - 0.2, .5), ('pop', FREE, .8), ('pop_hi', COMMENT, .8)]
inp, fl = ['-i', 'zoom2.mov'], []
for i, (nm, t, g) in enumerate(cues):
    inp += ['-i', f'{SFX}{nm}.wav']; fl.append(f"[{i + 1}:a]aresample=48000,aformat=channel_layouts=stereo,volume={g * 0.25:.3f},adelay={int(t * 1000)}|{int(t * 1000)}[s{i}]")
mix = (';'.join(fl) + ';[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[v];[v]' + ''.join(f'[s{i}]' for i in range(len(cues))) +
       f'amix=inputs={len(cues) + 1}:normalize=0:duration=first,atrim=0:{T:.3f},alimiter=limit=0.95[a]')
run(inp + ['-filter_complex', mix, '-map', '[a]', '-c:a', 'pcm_s16le', 'mix2.wav'])
for name, outf in (('cap', 'sm_lifetime_v2_captions.mp4'), ('clean', 'sm_lifetime_v2_clean.mp4')):
    fc = "[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];[0:v][ov]overlay=format=yuv420p10:eof_action=pass[v]"
    run(['-i', 'zoom2.mov', '-f', 'concat', '-safe', '0', '-i', f'hl2/{name}.txt', '-i', 'mix2.wav', '-filter_complex', fc, '-map', '[v]', '-map', '2:a',
         '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
        ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', outf])
    print('done', outf, round(T, 2), 's')
