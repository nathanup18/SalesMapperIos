"""Street View beat: one smooth zoom built from registered Google Maps stills, then pool / deck / driveway on their words."""
import cv2, numpy as np, json, subprocess, sys
from PIL import Image, ImageDraw, ImageFont
C = json.load(open('cues.json'))['scan']; Hs = json.load(open('zm/H.json'))
FPS = 30; T0, T1 = round(C['start'] * 30) / 30, round(C['end'] * 30) / 30
ORDER = ['24.5', '25.0', '25.5', '26.0', 'close']
ims = {k: cv2.imread('close.png' if k == 'close' else f'zm/{k}.png').astype(np.float32) for k in ORDER}
H = {k: np.array(Hs[k]) for k in ORDER}
def fmask(k):
    m = np.zeros((1920, 1080), np.float32)
    if k == 'close': m[:] = 1; return m
    y1 = 1920 if k == ORDER[0] else 1700                     # drop the Maps logo/scale strip of the in-between stills
    m[8:y1 - 8, 8:1072] = 1
    return cv2.GaussianBlur(m, (0, 0), 25)
masks = {k: fmask(k) for k in ORDER}
# camera = (left, top, w) in close-frame coords, h = w*16/9
def view_of(k):
    p = H[k] @ np.array([[0, 1080], [0, 0], [1, 1]], float); return (p[0, 0], p[1, 0], p[0, 1] - p[0, 0])
V0 = view_of('24.5')
VPOOL = (115, 334, 760); VDECK = (185, 553, 600); VDRV = (170, 676, 700); VFULL = (0, 0, 1080)
ez = lambda u: 4 * u ** 3 if u < .5 else 1 - (-2 * u + 2) ** 3 / 2
def lerpv(a, b, u):
    u = ez(min(1, max(0, u))); w = a[2] * (b[2] / a[2]) ** u
    if abs(a[2] - b[2]) > 50:                                # zoom toward a fixed point: no drift, no wobble
        f = (a[2] - w) / (a[2] - b[2]); return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, w)
    return (a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u, w)
K = [(T0, V0), (C['pool'] - 0.09, VPOOL), (C['deck'] - 0.28, VPOOL), (C['deck'], VDECK), (C['drive'] - 0.28, VDECK), (C['drive'], VDRV), (C['saves'] - 0.1, VDRV), (C['saves'] + 1.2, VFULL)]
def cam(t):
    for (ta, va), (tb, vb) in zip(K, K[1:]):
        if t < tb: return lerpv(va, vb, (t - ta) / (tb - ta))
    return K[-1][1]
FB = ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf', 64)
G = (52, 199, 89, 255)
MK = [('ring', (608, 1216, 44), 'POOL', C['pool']), ('ring', (784, 1212, 44), 'POOL', C['pool'] + 0.12),
      ('rect', (563, 1262, 652, 1347), 'DECK', C['deck']), ('rect', (622, 1532, 704, 1684), 'DRIVEWAY', C['drive'])]
def pop(t, c):
    p = (t - c + 0.05) / 0.27
    if p <= 0: return 0
    return 1 if p >= 1 else 0.5 + 0.5 * (1 - (1 - p) ** 3) + 0.1 * np.sin(p * np.pi)
def overlay(t, v):
    L, Tp, w = v; s = 1080 / w; SS = 2
    im = Image.new('RGBA', (1080 * SS, 1920 * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    X = lambda x: (x - L) * s * SS; Y = lambda y: (y - Tp) * s * SS
    for kind, g, name, c in MK:
        k = pop(t, c)
        if not k: continue
        if kind == 'ring':
            cx, cy, r = X(g[0]), Y(g[1]), g[2] * s * SS * k
            d.ellipse([cx - r - 3 * SS, cy - r - 3 * SS, cx + r + 3 * SS, cy + r + 3 * SS], outline=(0, 0, 0, 90), width=10 * SS)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=G, width=6 * SS); ax, ay = cx - r, cy - r
        else:
            cx, cy = (X(g[0]) + X(g[2])) / 2, (Y(g[1]) + Y(g[3])) / 2; hw, hh = (X(g[2]) - X(g[0])) / 2 * k, (Y(g[3]) - Y(g[1])) / 2 * k
            d.rounded_rectangle([cx - hw - 3 * SS, cy - hh - 3 * SS, cx + hw + 3 * SS, cy + hh + 3 * SS], 16 * SS, outline=(0, 0, 0, 90), width=10 * SS)
            d.rounded_rectangle([cx - hw, cy - hh, cx + hw, cy + hh], 14 * SS, outline=G, width=6 * SS); ax, ay = cx - hw, cy - hh
        txt = f'{name} ✓'; f = FB.font_variant(size=int(32 * SS * min(1, k)))
        bw = d.textlength(txt, font=f) + 32 * SS; bh = 48 * SS * min(1, k)
        if name == 'DECK': bx, by = cx + hw + 14 * SS, cy - bh / 2          # deck sits under the pool: chip goes to its right
        else: bx, by = ax, ay - bh - 10 * SS
        d.rounded_rectangle([bx, by, bx + bw, by + bh], 10 * SS, fill=G)
        d.text((bx + 16 * SS, by + bh / 2), txt, font=f, fill='white', anchor='lm')
    a = np.asarray(im.resize((1080, 1920), Image.LANCZOS)).astype(np.float32) / 255
    return a
out = sys.argv[1] if len(sys.argv) > 1 else 'sv.mp4'
n = round((T1 - T0) * FPS)
enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-s', '1080x1920', '-r', '30', '-i', '-', '-c:v', 'libx264', '-crf', '14', '-pix_fmt', 'yuv420p', out], stdin=subprocess.PIPE)
only = [float(x) for x in sys.argv[2:]]
for i in range(n):
    t = T0 + i / FPS
    if only and not any(abs(t - x) < 0.017 for x in only): continue
    L, Tp, w = v = cam(t); s = 1080 / w
    A = np.array([[s, 0, -L * s], [0, s, -Tp * s], [0, 0, 1]])
    acc = np.zeros((1920, 1080, 3), np.float32)
    for k in ORDER:
        M = (A @ H[k])[:2]
        img = cv2.warpAffine(ims[k], M, (1080, 1920), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REFLECT)
        m = cv2.warpAffine(masks[k], M, (1080, 1920), flags=cv2.INTER_LINEAR)[..., None]
        acc = img if k == ORDER[0] else acc * (1 - m) + img * m
    o = overlay(t, v); al = o[..., 3:]
    acc = acc * (1 - al) + o[..., 2::-1] * 255 * al
    fr = np.clip(acc, 0, 255).astype(np.uint8)
    if only: cv2.imwrite(f'sv_{t:.2f}.png', fr)
    else: enc.stdin.write(fr.tobytes())
enc.stdin.close(); enc.wait(); print('done', n)
