"""D2D IQ v2: zoom 1.2x bottom-anchored (face moves up), header + one-word serif captions (hook/outro), brighter HLG overlays, cards lower."""
import json, subprocess, os, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS
tl = json.load(open('seg/timeline.json')); T = tl[-1]['out0'] + tl[-1]['dur']
win = json.load(open('seg/cards.json'))
W = json.load(open('words.json'))
def to_out(c, t):
    for x in tl:
        if x['clip'] == c and x['a'] - 0.05 <= t < x['b']: return x['out0'] + max(0, t - x['a'])
    nxt = [x['out0'] for x in tl if x['clip'] == c and x['a'] > t]; return nxt[0] if nxt else None
SEC = json.load(open('seg/sec.json')); TSPAN = json.load(open('seg/titles.json')); TERMS = {t['key']: t['title'] for t in json.load(open('terms.json'))}
def words(alias, fn, lo=0, hi=99):
    out = []
    for w in W[fn]:
        if not (lo <= w['s'] < hi): continue
        t = to_out(alias, w['s'])
        if t is None: continue
        if out and t <= out[-1][1] + 0.06: t = out[-1][1] + 0.12     # same-instant Whisper stamps: space them, don't drop
        out.append((w['w'], t))
    if out: out[0] = (out[0][0], max(SEC[alias][0] + 0.02, min(out[0][1], SEC[alias][0] + 0.15)))
    return out
states = []; TITLE = {}
def caps(ws, end, header=False, title=''):
    for i, (w, s0) in enumerate(ws):
        e = ws[i + 1][1] if i + 1 < len(ws) else end
        TITLE[len(states)] = title; states.append((('h' if header else '', w), F(s0), F(e)))
caps(words('HOOK', 'IMG_9881', 4.0), SEC['HOOK'][1], header=True)
for k, a, b in win:
    states.append((('card', k), a, b))
    for al, fn, lo, hi in [("E1", "IMG_9884", 0, 99), ("E2", "IMG_9888", 0, 99), ("E3", "IMG_9891", 0, 99), ("E4", "IMG_9894", 8.6, 12.7)]:
        if al in TSPAN[k] and False: pass
EX = {"label": ("E1", "IMG_9884", 0, 99), "permit": ("E2", "IMG_9888", 0, 99), "cosign": ("E3", "IMG_9891", 0, 99), "rival": ("E4", "IMG_9894", 8.6, 12.7)}
for k, (al, fn, lo, hi) in EX.items(): caps(words(al, fn, lo, hi), SEC[al][1], title=TERMS[k])
ow = words('L6', 'IMG_9899', 4.6)
ci = next(i for i, (w, _) in enumerate(ow) if w.lower().startswith("thousands"))
caps(ow[:ci], ow[ci][1], title=TERMS['follow']); TITLE[len(states)] = TERMS['follow']; states.append((('', 'follow for more'), F(ow[ci][1]), F(T)))   # red box from "thousands" to the end
order = sorted(range(len(states)), key=lambda i: states[i][1]); TITLE2 = {j: TITLE.get(i, '') for j, i in enumerate(order)}; states = [states[i] for i in order]
# render caption PNGs
import urllib.parse
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
CAP = os.environ.get('CAP', 'cap'); OVL = os.environ.get('OVL', 'overlay.html'); os.makedirs(CAP, exist_ok=True); n = 0; files = []
for si, ((kind, x), a, b) in enumerate(states):
    if kind == 'card': files.append(f"cards/{os.environ.get('PFX','card_')}{x}.png"); continue
    f = f'{CAP}/c{n:02d}.png'; n += 1; files.append(f); red = '&r=1' if x == 'follow for more' else ''
    ttl = urllib.parse.quote(TITLE.get(si, '')) if False else ''
    js += f"await p.goto('file://'+path.resolve('cards/{OVL}')+'?h={kind}&w={urllib.parse.quote(x)}{red}&t={urllib.parse.quote(TITLE2[si])}&n={n}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(60); await p.screenshot({{path:'{f}',omitBackground:true}});\n"
js += "await b.close();})();"; open(f'{CAP}/r.js', 'w').write(js); subprocess.run(['node', f'{CAP}/r.js'], check=True)
# sRGB overlay -> HLG, white at 88% HLG signal (brighter than the 75% reference, per Nathan)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073; SIG = 0.88
E_REF = (np.exp((SIG - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def to_hlg(png, out, wide=False):
    im = cv2.imread(png, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]; al = im[..., 3]
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4) @ (np.eye(3) if wide else M).T * E_REF   # wide: treat as BT.2020 primaries = more vivid
    e = np.where(lin <= 1 / 12, np.sqrt(3 * np.clip(lin, 0, None)), a_ * np.log(np.clip(12 * lin - b_, 1e-9, None)) + c_)
    cv2.imwrite(out, (np.dstack([np.clip(e, 0, 1)[..., ::-1], al]) * 65535).round().astype(np.uint16))
HL = os.environ.get('HL', 'hlg2'); os.makedirs(HL, exist_ok=True); cv2.imwrite(f'{HL}/blank.png', np.zeros((1920, 1080, 4), np.uint16))
with open(f'{HL}/list.txt', 'w') as L:
    cur = 0.0
    for i, ((_, _), a, b) in enumerate(states):
        o = f'{HL}/s{i:02d}.png'; to_hlg(files[i], o, wide=states[i][0][1] == 'follow for more'); a = max(a, cur)
        if b <= a: continue
        if a > cur + 1e-3: L.write(f"file 'blank.png'\nduration {a - cur:.4f}\n")
        L.write(f"file 's{i:02d}.png'\nduration {b - a:.4f}\n"); cur = b
    L.write(f"file 'blank.png'\nduration {T - cur + 0.5:.4f}\nfile 'blank.png'\n")
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
fc = ("[0:v]scale=1296:2304:flags=lanczos,crop=1080:1920:108:384[z];"          # 1.2x zoom, bottom-anchored: face moves up, picture values untouched
      "[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];[z][ov]overlay=format=yuv420p10:eof_action=pass[v]")
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', 'seg/main.mov', '-f', 'concat', '-safe', '0', '-i', f'{HL}/list.txt', '-filter_complex', fc, '-map', '[v]', '-map', '0:a',
                '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
               ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', os.environ.get('OUTF', 'unethical_closes_instagram.mp4')], check=True)
print('done', round(T, 2), 's,', len(states), 'overlay states')
