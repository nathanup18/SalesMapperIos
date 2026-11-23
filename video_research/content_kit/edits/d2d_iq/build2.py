"""D2D IQ v2: zoom 1.2x bottom-anchored (face moves up), header + one-word serif captions (hook/outro), brighter HLG overlays, cards lower."""
import json, subprocess, os, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS
tl = json.load(open('seg/timeline.json')); T = tl[-1]['out0'] + tl[-1]['dur']
win = json.load(open('seg/cards.json'))
HOOK = [("Let's", .03), ("see", .34), ("if", .48), ("you", .60), ("actually", .74), ("know", 1.0), ("door-to-door", 1.26), ("sales.", 1.74)]
OUT = [("If", 14.93), ("you", 15.03), ("know", 15.13), ("all", 15.23), ("those,", 15.41), ("you're", 15.6), ("definitely", 15.77), ("in", 16.11), ("business.", 16.41),
       ("So", 16.85), ("go", 16.95), ("out", 17.13), ("there", 17.27), ("and", 17.39), ("make", 17.47), ("some", 17.57), ("money", 17.71), ("and", 17.95),
       ("follow for more", 18.17)]   # his red pop-up: one box, held to the end
states = []   # (png, start, end)
def caps(words, end, header):
    for i, (w, s) in enumerate(words):
        e = words[i + 1][1] if i + 1 < len(words) else end
        states.append((('h', w) if header else ('', w), F(s), F(e)))
caps(HOOK, tl[1]['out0'], True)
for k, a, b in win: states.append((('card', k), a, b))
caps(OUT, T, False)
# render caption PNGs
import urllib.parse
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
os.makedirs('cap', exist_ok=True); n = 0; files = []
for (kind, x), a, b in states:
    if kind == 'card': files.append(f'cards/card_{x}.png'); continue
    f = f'cap/c{n:02d}.png'; n += 1; files.append(f); red = '&r=1' if x == 'follow for more' else ''
    js += f"await p.goto('file://'+path.resolve('cards/overlay.html')+'?h={kind}&w={urllib.parse.quote(x)}{red}&n={n}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(60); await p.screenshot({{path:'{f}',omitBackground:true}});\n"
js += "await b.close();})();"; open('cap/r.js', 'w').write(js); subprocess.run(['node', 'cap/r.js'], check=True)
# sRGB overlay -> HLG, white at 88% HLG signal (brighter than the 75% reference, per Nathan)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073; SIG = 0.88
E_REF = (np.exp((SIG - c_) / a_) + b_) / 12
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def to_hlg(png, out):
    im = cv2.imread(png, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]; al = im[..., 3]
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4) @ M.T * E_REF
    e = np.where(lin <= 1 / 12, np.sqrt(3 * np.clip(lin, 0, None)), a_ * np.log(np.clip(12 * lin - b_, 1e-9, None)) + c_)
    cv2.imwrite(out, (np.dstack([np.clip(e, 0, 1)[..., ::-1], al]) * 65535).round().astype(np.uint16))
os.makedirs('hlg2', exist_ok=True); cv2.imwrite('hlg2/blank.png', np.zeros((1920, 1080, 4), np.uint16))
with open('hlg2/list.txt', 'w') as L:
    cur = 0.0
    for i, ((_, _), a, b) in enumerate(states):
        o = f'hlg2/s{i:02d}.png'; to_hlg(files[i], o); a = max(a, cur)
        if b <= a: continue
        if a > cur + 1e-3: L.write(f"file 'blank.png'\nduration {a - cur:.4f}\n")
        L.write(f"file 's{i:02d}.png'\nduration {b - a:.4f}\n"); cur = b
    L.write(f"file 'blank.png'\nduration {T - cur + 0.5:.4f}\nfile 'blank.png'\n")
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
fc = ("[0:v]scale=1296:2304:flags=lanczos,crop=1080:1920:108:384[z];"          # 1.2x zoom, bottom-anchored: face moves up, picture values untouched
      "[1:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[ov];[z][ov]overlay=format=yuv420p10:eof_action=pass[v]")
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', 'seg/main.mov', '-f', 'concat', '-safe', '0', '-i', 'hlg2/list.txt', '-filter_complex', fc, '-map', '[v]', '-map', '0:a',
                '-c:v', 'libx265', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
               ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', 'd2d_IQ_v3.mp4'], check=True)
print('done', round(T, 2), 's,', len(states), 'overlay states')
