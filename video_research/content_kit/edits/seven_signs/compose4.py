"""7 signs Reel v1: hook = Nathan cut out (75%) over a soft blur of his own room with 3 photos above his head; signs = Nathan cut out (60%, alternating corners)
over the sign photo; close = original framing. TikTok classic text for headers and one-word captions. Original HDR pixels for Nathan, graphics into HLG."""
import json, subprocess, urllib.parse, numpy as np, cv2, os
FPS = 30; F = lambda x: round(x * FPS) / FPS; W_, H_ = 1080, 1920
sec = json.load(open('seg5/sec.json')); tmap = json.load(open('seg2/tmap.json')); TM3 = json.load(open('seg3/tmap.json')); TM4 = json.load(open('seg4/tmap.json')); TM5 = json.load(open('seg5/tmap.json')); T = sec['CLOSE'][1]; NF = round(T * FPS)
CH = json.load(open('chin.json'))
ORDER = ['HOOK', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'CLOSE']
def sect(t):
    for k in ORDER:
        if sec[k][0] - 1e-3 <= t < sec[k][1] - 1e-3: return k
    return 'CLOSE'
LAY = {'HOOK': (0.70, None)}; side = 1
for k in ORDER[1:8]: LAY[k] = (0.60, 'R' if side else 'L'); side ^= 1
def place(k):
    s, sd = LAY[k]; pw, ph = round(W_ * s), round(H_ * s); py = H_ - ph
    px = (W_ - pw) // 2 if sd is None else (W_ - pw + 90 if sd == 'R' else -90)
    return s, pw, ph, px, py
# ---- captions (first-pass words mapped through the tightening cuts)
def mp(tm, x):
    if x is None: return None
    for s in tm:
        if s['a'] - 1e-3 <= x <= s['b'] + 1e-3: return s['out0'] + max(0, x - s['a'])
    return None
def m(x): return mp(TM4, mp(TM3, mp(tmap, x)))
def inv(tm, y):                                            # output time -> input time of one tightening pass
    for s in tm:
        if s['out0'] - 1e-6 <= y < s['out0'] + (s['b'] - s['a']) + 1e-6: return s['a'] + (y - s['out0'])
    return tm[-1]['b']
def mask_idx(n): return round(inv(TM3, inv(TM4, inv(TM5, n / FPS))) * FPS) + 1
words = []
for w in json.load(open('outwords5.json')):
    t = w['s']; txt = w['w']
    if t is None: continue
    if txt.startswith('-') and words: words[-1] = (words[-1][0] + txt, words[-1][1]); continue
    txt = txt.replace('...', '').strip()
    if txt.lower().startswith('three'): txt = '3,'
    if words and t <= words[-1][1] + 0.06: t = words[-1][1] + 0.1
    words.append((txt, F(t)))
words[0] = (words[0][0], 0.0)
HEAD = {'HOOK': ('7 signs a house will say YES before you even knock', '(most reps walk right past #6)'),
        'S1': ('1. Fresh landscaping', ''), 'S2': ("2. Kids' bikes out", ''), 'S3': ('3. Two newer cars', ''), 'S4': ('4. A contractor sign', ''),
        'S5': ('5. Doorbell camera', ''), 'S6': ('6. Something worn out', ''), 'S7': ('7. Garage door open', ''), 'CLOSE': ('Which one did I miss?', '')}
def capy(k):
    if k == 'HOOK': s, pw, ph, px, py = place(k); return int(py + CH[k] * s) + 20
    if k == 'CLOSE': return CH[k] + 20
    return 760
FOLLOW = [t for w, t in words if w.lower().startswith('follow')][-1]
states = []
for i, (w, t0) in enumerate(words):
    t1 = words[i + 1][1] if i + 1 < len(words) else T
    cuts = [sec[k][0] for k in ORDER if t0 < sec[k][0] < t1]; pts = [t0] + cuts + [t1]
    for a, b in zip(pts, pts[1:]):
        k = sect(a); h, hs = HEAD[k]; q = dict(w=w, cy=capy(k), h=h)
        if k == 'CLOSE' and a >= FOLLOW - 1e-3: q = dict(red='1', cy=capy(k), h=h)
        if hs: q['hs'] = hs
        if k == 'HOOK': q['row'] = '1'
        states.append((q, F(a), F(b)))
os.makedirs('cap3', exist_ok=True); os.makedirs('hl3', exist_ok=True)
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
for i, (q, a, b) in enumerate(states):
    js += f"await p.goto('file://'+path.resolve('ov3.html')+'?{urllib.parse.urlencode(q)}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(40); await p.screenshot({{path:'cap3/{i:03d}.png',omitBackground:true}});\n"
open('cap3/r.js', 'w').write(js + "await b.close();})();"); subprocess.run(['node', 'cap3/r.js'], check=True)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073; E = (np.exp((0.88 - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
with open('hl3/list.txt', 'w') as L:
    for i, (q, a, b) in enumerate(states):
        im = cv2.imread(f'cap3/{i:03d}.png', cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]
        lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4) @ (np.eye(3) if 'red' in q else M).T * E
        e = np.where(lin <= 1 / 12, np.sqrt(3 * np.clip(lin, 0, None)), a_ * np.log(np.clip(12 * lin - b_, 1e-9, None)) + c_)
        cv2.imwrite(f'hl3/{i:03d}.png', (np.dstack([np.clip(e, 0, 1)[..., ::-1], im[..., 3]]) * 65535).round().astype(np.uint16))
        L.write(f"file '{i:03d}.png'\nduration {b - a:.4f}\n")
    L.write(f"file '{len(states) - 1:03d}.png'\n")
# ---- sign photos -> full-frame HLG yuv420p10 (0.88-white LUT, F50)
def photo_yuv(p):
    im = cv2.imread(p); h, w = im.shape[:2]; s = max(W_ / w, H_ / h); im = cv2.resize(im, (round(w * s), round(h * s)), interpolation=cv2.INTER_CUBIC)
    y0 = (im.shape[0] - H_) // 2; x0 = (im.shape[1] - W_) // 2; im = im[y0:y0 + H_, x0:x0 + W_]; cv2.imwrite('_p.png', im)
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', '_p.png', '-vf', 'format=rgb48le,lut3d=sdr2hlg_bright.cube,scale=out_color_matrix=bt2020:out_range=tv,format=yuv420p10le',
                        '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-'], capture_output=True, check=True).stdout
    a = np.frombuffer(r, np.uint16); YS, CS = W_ * H_, W_ * H_ // 4
    return [a[:YS].reshape(H_, W_), a[YS:YS + CS].reshape(H_ // 2, W_ // 2), a[YS + CS:].reshape(H_ // 2, W_ // 2)]
BG = {f'S{i}': photo_yuv(f'p{i}.png') for i in range(1, 8)}
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
dec = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', 'seg5/main.mov', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-'], stdout=subprocess.PIPE)
enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'yuv420p10le', '-s', f'{W_}x{H_}', '-r', '30', '-i', '-', '-c:v', 'libx265', '-preset', 'medium', '-crf', '10',
                        '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['base5.mov'], stdin=subprocess.PIPE, stderr=open('enc.log', 'w'))
YS, CS = W_ * H_, W_ * H_ // 4; FB = (YS + 2 * CS) * 2
def paste(dst, src, al, x, y):
    h, w = src.shape; x0, y0 = max(0, x), max(0, y); x1, y1 = min(dst.shape[1], x + w), min(dst.shape[0], y + h)
    if x1 <= x0 or y1 <= y0: return
    s = src[y0 - y:y1 - y, x0 - x:x1 - x].astype(np.float32); m_ = al[y0 - y:y1 - y, x0 - x:x1 - x]
    d = dst[y0:y1, x0:x1].astype(np.float32); dst[y0:y1, x0:x1] = np.clip(d * (1 - m_) + s * m_ + 0.5, 0, 1023).astype(np.uint16)
prev = None
for n in range(NF):
    buf = dec.stdout.read(FB)
    if len(buf) < FB: break
    t = n / FPS; k = sect(t)
    if k == 'CLOSE': enc.stdin.write(buf); continue
    a = np.frombuffer(buf, np.uint16); P = [a[:YS].reshape(H_, W_), a[YS:YS + CS].reshape(H_ // 2, W_ // 2), a[YS + CS:].reshape(H_ // 2, W_ // 2)]
    if k == 'HOOK': B = [cv2.resize(cv2.GaussianBlur(cv2.resize(p, (p.shape[1] // 8, p.shape[0] // 8), interpolation=cv2.INTER_AREA), (0, 0), 5), (p.shape[1], p.shape[0]), interpolation=cv2.INTER_LINEAR) for p in P]
    else: B = [p.copy() for p in BG[k]]
    mk = cv2.imread(f'masks/{min(1370, mask_idx(n)):05d}.png', cv2.IMREAD_GRAYSCALE).astype(np.float32)
    mk = cv2.resize(mk, (W_, H_), interpolation=cv2.INTER_CUBIC)
    if prev is not None: mk = 0.5 * mk + 0.5 * prev
    prev = mk.copy(); mk = cv2.GaussianBlur(np.clip((mk - 30) * 1.25, 0, 255), (0, 0), 1.2) / 255
    s, pw, ph, px, py = place(k)
    for j, (pl, nb) in enumerate(zip(P, B)):
        kk = 1 if j == 0 else 2; w, h = pw // kk, ph // kk
        p = cv2.resize(pl, (w, h), interpolation=cv2.INTER_AREA); mm = cv2.resize(mk, (w, h), interpolation=cv2.INTER_AREA)
        if k != 'HOOK':
            sh = cv2.GaussianBlur(mm, (0, 0), 22 / kk) * 0.5; paste(nb, np.full_like(p, 64 if j == 0 else 512), sh, (px + 14) // kk, (py + 18) // kk)
        paste(nb, p, mm, px // kk, py // kk)
    enc.stdin.write(b''.join(x.tobytes() for x in B))
    if n % 150 == 0: print('frame', n, flush=True)
enc.stdin.close(); enc.wait(); dec.kill()
fc = "[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];[0:v][ov]overlay=format=yuv420p10:eof_action=pass[v]"
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', 'base5.mov', '-f', 'concat', '-safe', '0', '-i', 'hl3/list.txt', '-i', 'seg5/main.mov', '-filter_complex', fc, '-map', '[v]', '-map', '2:a',
                '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
               ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', 'seven_signs_v3.mp4'], check=True)
print('done', round(T, 2), 's', len(states), 'states')
