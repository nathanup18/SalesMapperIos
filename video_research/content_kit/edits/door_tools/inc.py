"""Income map beat: census-style heat map of real Sunningdale blocks (London ON), map first, then over the Google Maps screenshot.
Dark red = more money, near white = less. Small legend. Highest + lowest called out on the words."""
import cv2, numpy as np, json, subprocess, sys
from PIL import Image, ImageDraw, ImageFont
IN = json.load(open('cues.json'))['income']; FPS = 30
T0, T1 = round(IN['start'] * 30) / 30, round(IN['end'] * 30) / 30
sat = cv2.imread('zm/24.5.png').astype(np.float32)
LBL = {'Silverfox Dr': (175, 214, 0), 'Foxcreek Rd': (270, 474, 0), 'Foxhunt Rd': (215, 339, 0), 'Foxwood Ave': (300, 604, 0), 'Medway Park Dr': (300, 752, 6)}
# road centerlines + blocks traced from the screenshot (half-res coords, x2 below)
ROADS = {'Silverfox Dr': [(0, 228), (300, 228), (330, 212), (365, 182), (410, 140), (470, 92), (540, 45)],
         '': [(55, 0), (55, 92), (320, 95), (345, 108), (370, 128)],
         'Foxcreek Rd': [(122, 487), (430, 487), (445, 470), (445, 260), (465, 215), (495, 200), (540, 196)],
         'Foxhunt Rd': [(122, 352), (300, 352), (318, 370), (318, 487)],
         'Foxwood Ave': [(122, 228), (122, 600), (138, 617), (445, 617)],
         ' ': [(410, 487), (410, 617)], '  ': [(442, 617), (438, 790), (440, 960)],
         'Medway Park Dr': [(0, 738), (150, 746), (300, 768), (437, 790), (540, 790)], '   ': [(118, 745), (118, 960)], '    ': [(6, 230), (6, 738)]}
BL = {'A': ([(0, 0), (340, 0), (320, 95), (0, 95)], 118),
      'B': ([(0, 95), (320, 95), (345, 108), (370, 128), (410, 140), (365, 182), (330, 212), (300, 228), (0, 228)], 131),
      'C': ([(340, 0), (540, 0), (540, 45), (470, 92), (410, 140), (370, 128), (345, 108), (320, 95)], 86),
      'D': ([(410, 140), (470, 92), (540, 45), (540, 196), (495, 200), (465, 215), (445, 260), (445, 240), (365, 182)], 104),
      'E': ([(0, 228), (122, 228), (122, 617), (150, 746), (0, 738)], 92), 'G': ([(122, 228), (300, 228), (318, 219), (318, 352), (122, 352)], 142),
      'H': ([(318, 219), (330, 212), (365, 182), (445, 240), (445, 487), (318, 487)], 121), 'I': ([(122, 352), (318, 352), (318, 487), (122, 487)], 168),
      'J': ([(122, 487), (445, 487), (445, 617), (122, 617)], 151), 'L': ([(445, 260), (465, 215), (495, 200), (540, 196), (540, 790), (437, 790), (442, 617), (445, 487)], 97),
      'M': ([(122, 617), (442, 617), (437, 790), (300, 768), (150, 746)], 137), 'N': ([(0, 738), (118, 745), (118, 960), (0, 960)], 82),
      'O': ([(118, 745), (150, 746), (300, 768), (437, 790), (440, 960), (118, 960)], 89), 'P': ([(437, 790), (540, 790), (540, 960), (440, 960)], 74)}
HI, LO = 'I', 'P'
REDS = np.array([[255, 245, 240], [254, 224, 210], [252, 187, 161], [252, 146, 114], [251, 106, 74], [239, 59, 44], [203, 24, 29], [153, 0, 13], [110, 0, 8]], float)
def red(v):
    u = np.clip((v - 70) / 100, 0, 1) * (len(REDS) - 1); i = min(int(u), len(REDS) - 2); f = u - i
    return REDS[i] * (1 - f) + REDS[i + 1] * f
S2 = lambda pts, k=2: [(x * 2 * k, y * 2 * k) for x, y in pts]
# static layers at 2x then down
SS = 2
base = np.full((1920, 1080, 3), (226, 231, 233), np.float32)
rd = Image.new('RGBA', (1080 * SS, 1920 * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(rd)
for nm, p in ROADS.items(): d.line(S2(p), fill=(190, 186, 178, 255), width=26 * SS, joint='curve')
for nm, p in ROADS.items(): d.line(S2(p), fill=(255, 255, 255, 255), width=20 * SS, joint='curve')
rd = np.asarray(rd.resize((1080, 1920), Image.LANCZOS)).astype(np.float32) / 255
def pmask(pts, w=None):
    m = Image.new('L', (1080 * SS, 1920 * SS), 0); dd = ImageDraw.Draw(m)
    if w: dd.line(S2(pts + pts[:1]), fill=255, width=w * SS, joint='curve')
    else: dd.polygon(S2(pts), fill=255)
    return np.asarray(m.resize((1080, 1920), Image.LANCZOS)).astype(np.float32)[..., None] / 255
PM = {k: pmask(p) for k, (p, v) in BL.items()}
EDGE = np.clip(sum(pmask(p, 3) for p, v in BL.values()), 0, 1)
HIE = {k: pmask(BL[k][0], 9) for k in (HI, LO)}
labl = Image.new('RGBA', (1080 * SS, 1920 * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(labl)
FS = ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-SemiBold.otf', 22 * SS)
for nm, (x, y, ang) in LBL.items():
    t = Image.new('RGBA', (400 * SS, 40 * SS), (0, 0, 0, 0)); ImageDraw.Draw(t).text((200 * SS, 20 * SS), nm, font=FS, fill=(110, 110, 110, 255), anchor='mm')
    t = t.rotate(-ang, resample=Image.BICUBIC); labl.alpha_composite(t, (int(x * 2 * SS - 200 * SS), int(y * 2 * SS - 20 * SS)))
labl = np.asarray(labl.resize((1080, 1920), Image.LANCZOS)).astype(np.float32) / 255
ez = lambda u: (lambda u: 4 * u ** 3 if u < .5 else 1 - (-2 * u + 2) ** 3 / 2)(min(1, max(0, u)))
eo = lambda u: 1 - (1 - min(1, max(0, u))) ** 3
order = sorted(BL, key=lambda k: (np.mean([p[1] for p in BL[k][0]]), np.mean([p[0] for p in BL[k][0]])))
def fill_a(k, t):                                         # blocks fill top -> bottom on "income map"
    i = order.index(k); a = IN['start'] + 0.2 + i * 0.06; return eo((t - a) / 0.3)
SAT0, SAT1 = IN['so'] if 'so' in IN else 25.0, 25.55        # satellite screenshot comes in on "so you can figure out"
def cam(t):                                               # (zoom, cx, cy) in map coords
    z0, z1 = 1.22, 1.0; c0, c1 = (560, 860), (540, 960)
    if t < IN['entire'] - 0.05: u = (t - T0) / (IN['entire'] - 0.05 - T0); z = z0 + 0.06 * u; return z, c0[0], c0[1]
    u = ez((t - IN['entire'] + 0.05) / 0.6); z = (z0 + 0.06) + (z1 - z0 - 0.06) * u
    return z, c0[0] + (c1[0] - c0[0]) * u, c0[1] + (c1[1] - c0[1]) * u
FB = ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf', 34 * SS)
FL = ImageFont.truetype('/usr/share/fonts/opentype/inter/Inter-Bold.otf', 17 * SS)
def centroid(k):
    p = np.array(BL[k][0], float) * 2; return p[:, 0].mean(), p[:, 1].mean()
CALL = [(HI, f'${BL[HI][1]}k · highest', IN['money']), (LO, f'${BL[LO][1]}k · lowest', 27.19)]
def ui(t, z, cx, cy):
    im = Image.new('RGBA', (1080 * SS, 1920 * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    X = lambda x: ((x - cx) * z + 540) * SS; Y = lambda y: ((y - cy) * z + 960) * SS
    # legend: small, top right under the title box
    la = eo((t - IN['census'] + 0.05) / 0.25)
    if la > 0:
        x0, y0, w = 760 * SS, 352 * SS, 270 * SS; A = int(255 * la)
        d.rounded_rectangle([x0 - 14 * SS, y0 - 12 * SS, x0 + w + 14 * SS, y0 + 70 * SS], 12 * SS, fill=(255, 255, 255, int(235 * la)))
        d.text((x0, y0), 'MEDIAN HOUSEHOLD INCOME', font=FL, fill=(60, 60, 60, A))
        for i in range(w):
            c = red(70 + 100 * i / w); d.line([(x0 + i, y0 + 26 * SS), (x0 + i, y0 + 40 * SS)], fill=(int(c[0]), int(c[1]), int(c[2]), A))
        d.text((x0, y0 + 44 * SS), '$70k', font=FL, fill=(60, 60, 60, A)); d.text((x0 + w, y0 + 44 * SS), '$170k+', font=FL, fill=(60, 60, 60, A), anchor='ra')
    for k, txt, c in CALL:
        p = (t - c + 0.05) / 0.27
        if p <= 0: continue
        s = 1 if p >= 1 else 0.6 + 0.4 * eo(p) + 0.08 * np.sin(p * np.pi)
        mx, my = centroid(k); px, py = X(mx), Y(my)
        f = FB.font_variant(size=int(34 * SS * s)); bw = d.textlength(txt, font=f) + 36 * SS; bh = 60 * SS * s
        dark = k == HI; fill = (153, 0, 13, 255) if dark else (255, 255, 255, 255); fg = 'white' if dark else (120, 20, 20)
        bx = min(max(px - bw / 2, 20 * SS), 1060 * SS - bw); by = py - bh / 2
        d.rounded_rectangle([bx + 4 * SS, by + 6 * SS, bx + bw + 4 * SS, by + bh + 6 * SS], 14 * SS, fill=(0, 0, 0, 90))
        d.rounded_rectangle([bx, by, bx + bw, by + bh], 14 * SS, fill=fill)
        d.text((bx + bw / 2, by + bh / 2), txt, font=f, fill=fg, anchor='mm')
    return np.asarray(im.resize((1080, 1920), Image.LANCZOS)).astype(np.float32) / 255
out = sys.argv[1]; only = [float(x) for x in sys.argv[2:]]
n = round((T1 - T0) * FPS)
enc = None if only else subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-s', '1080x1920', '-r', '30', '-i', '-', '-c:v', 'libx264', '-crf', '14', '-pix_fmt', 'yuv420p', out], stdin=subprocess.PIPE)
for i in range(n):
    t = T0 + i / FPS
    if only and not any(abs(t - x) < 0.017 for x in only): continue
    sa = ez((t - SAT0) / (SAT1 - SAT0))
    img = base * (1 - sa) + sat * sa
    fa = 0.9 - 0.38 * sa
    for k, (p, v) in BL.items():
        a = PM[k] * fill_a(k, t) * fa; c = red(v)[::-1]
        img = img * (1 - a) + c * a
    ra = rd[..., 3:] * (1 - sa); img = img * (1 - ra) + rd[..., 2::-1] * 255 * ra
    lab = labl[..., 3:] * (1 - sa); img = img * (1 - lab) + labl[..., 2::-1] * 255 * lab
    ea = EDGE * (0.9 * min(1, (t - T0) / 0.2)); img = img * (1 - ea) + 255 * ea
    for k, c in ((HI, IN['money']), (LO, 27.19)):
        a = HIE[k] * eo((t - c + 0.05) / 0.25); col = np.array([13, 0, 120]) if k == HI else np.array([255, 255, 255])
        img = img * (1 - a) + col * a
    z, cx, cy = cam(t)
    M = np.array([[z, 0, 540 - cx * z], [0, z, 960 - cy * z]])
    img = cv2.warpAffine(img, M, (1080, 1920), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REFLECT)
    o = ui(t, z, cx, cy); al = o[..., 3:]; img = img * (1 - al) + o[..., 2::-1] * 255 * al
    fr = np.clip(img, 0, 255).astype(np.uint8)
    if only: cv2.imwrite(f'inc_{t:.2f}.png', fr)
    else: enc.stdin.write(fr.tobytes())
if enc: enc.stdin.close(); enc.wait()
print('done', n)
