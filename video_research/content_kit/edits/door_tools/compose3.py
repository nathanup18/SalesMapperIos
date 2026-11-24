"""4 tools video: full-screen visuals (stock/animated/app, SDR -> HLG via LUT) + Nathan in a moving corner box (original HDR) + labels/captions (HLG)."""
import json, subprocess, os, urllib.parse, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS
B = '../broll/'; tl = json.load(open('seg/timeline.json')); sec = json.load(open('seg/sec.json')); C = json.load(open('cues.json')); W = json.load(open('words.json'))
T = tl[-1]['out0'] + tl[-1]['dur']
VAR = os.environ.get('VAR', 'ig')                     # ig | tt (TikTok: everything shifted clear of the right rail / top tabs)
def run(a): subprocess.run(['ffmpeg', '-v', 'error', '-y'] + a, check=True)
# ---- 1. background: fast cuts of software (Nathan's Google Maps recording, built screens, real SalesMapper clips)
os.makedirs('bg', exist_ok=True); os.makedirs('sc', exist_ok=True)
SC_ = C['scan']; PR = C['prop']; IN = C['income']; SM = C['sm']
S = {'hook': (0, sec['S1'][0]), 's1': (sec['S1'][0], sec['I2'][0]), 's2': (sec['I2'][0], sec['I3'][0]), 's3': (sec['I3'][0], sec['I4'][0]), 's4': (sec['I4'][0], sec['C4'][0]), 'cta': (sec['C4'][0], T)}
MAPC = 'crop=996:1770:0:560,scale=1080:1920:flags=lanczos'
def rend(q, d, out, alpha=False):
    subprocess.run(['node', 'rend.js', q, f'{d:.4f}', out] + (['1'] if alpha else []), check=True, capture_output=True)
shots = []   # (out_file, start, end)
def piece(name, a, b, src=None, ss=0, se=None, vf='', ov=None, ovq=None, screen=None):
    d = F(b) - F(a); out = f'bg/{len(shots):02d}_{name}.mp4'
    if screen:
        rend(screen, d, out)
    else:
        se = se if se is not None else ss + d
        sp = (se - ss) / d
        chain = f"trim=start={ss}:end={se},setpts=(PTS-STARTPTS)/{sp:.4f},{vf}fps=30,format=yuv420p"
        if ov:
            rend(ovq, d, f'sc/ov_{len(shots)}.mov', alpha=True)
            run(['-i', src, '-i', f'sc/ov_{len(shots)}.mov', '-filter_complex', f"[0:v]{chain}[b];[b][1:v]overlay=0:0:format=auto,format=yuv420p", '-t', f'{d:.4f}', '-an', '-c:v', 'libx264', '-crf', '16', out])
        else:
            run(['-i', src, '-vf', chain, '-t', f'{d:.4f}', '-an', '-c:v', 'libx264', '-crf', '16', out])
    shots.append(out)
APP = "scale=-2:1920,split[a][b];[b]scale=1080:1920,boxblur=30,eq=brightness=-0.15[bb];[bb][a]overlay=(W-w)/2:0,"
def app(name, a, b, src, ss, se):
    d = F(b) - F(a); out = f'bg/{len(shots):02d}_{name}.mp4'; sp = (se - ss) / d
    run(['-i', src, '-filter_complex', f"[0:v]trim=start={ss}:end={se},setpts=(PTS-STARTPTS)/{sp:.4f},scale=-2:1920,split[a][b];[b]scale=1080:1920,boxblur=30,eq=brightness=-0.15[bb];[bb][a]overlay=(W-w)/2:0,fps=30,format=yuv420p", '-t', f'{d:.4f}', '-an', '-c:v', 'libx264', '-crf', '16', out]); shots.append(out)
piece('split', 0, S['hook'][1], 'split.mp4', 0, S['hook'][1])
piece('maps_zoom', S['s1'][0], SC_['nbhd'], 'maps_rec.mp4', 1.0, 9.0, MAPC + ',')
piece('maps_zone', SC_['nbhd'], SC_['balc'] - 0.03, 'maps_rec.mp4', 13.0, 15.5, MAPC + ',', ov=True, ovq='s=zone')
piece('maps_scan', SC_['balc'] - 0.03, SC_['saves'], 'maps_rec.mp4', 26.5, 28.6, MAPC + ',', ov=True, ovq=f"s=scan&t0={F(SC_['balc'] - 0.03)}&c={urllib.parse.quote(json.dumps(SC_))}")
piece('maps_push', SC_['saves'], S['s1'][1], 'maps_rec.mp4', 16.0, 24.0, MAPC + ',')
piece('leads', S['s2'][0], sec['E2'][0], screen='s=leads')
piece('filters', sec['E2'][0], PR['know'], screen='s=filters')
piece('owner', PR['know'], PR['mort'], screen='s=owner')
piece('mortgage', PR['mort'], PR['good'], screen='s=mortgage')
piece('opp', PR['good'], S['s2'][1], screen='s=opp')
piece('inc_city', S['s3'][0], IN['simple'], screen='s=inc_city')
piece('inc_nbhd', IN['simple'], IN['census'], screen='s=inc_nbhd')
piece('inc_table', IN['census'], IN['entire'], screen='s=inc_table')
piece('inc_over', IN['entire'], IN['money'], 'maps_rec.mp4', 10.5, 13.0, MAPC + ',', ov=True, ovq='s=inc_over')
piece('inc_hot', IN['money'], S['s3'][1], 'maps_rec.mp4', 13.0, 15.0, MAPC + ',', ov=True, ovq='s=inc_hot')
app('sm_knock', S['s4'][0], SM['cheat'], 'knock.mp4', 0.0, 4.7)
app('sm_shift', SM['cheat'], SM['knock'], 'shift.mp4', 0.5, 4.0)
piece('sm_fill', SM['knock'], SM['sales'], 'sm_fill.mp4', 0.8, 5.0)
piece('sm_stats', SM['sales'], S['s4'][1], 'sm_stats.mp4', 0.0, 2.6)
piece('cta', S['cta'][0], T, 'sm_fill.mp4', 4.5, 9.4)
open('bg/list.txt', 'w').write(''.join(f"file '{os.path.basename(x)}'\n" for x in shots))
run(['-f', 'concat', '-safe', '0', '-i', 'bg/list.txt', '-c:v', 'libx264', '-crf', '15', '-pix_fmt', 'yuv420p', 'bg/bg_sdr.mp4'])
# ---- 2. text states
LAB = {'s1': ('1. Google Street View', 'scan for pools, decks + driveways'), 's2': ('2. PropStream', '165+ filters on every home'),
       's3': ('3. Income Map', 'census income, block by block'), 's4': ('4. SalesMapper', '43% more doors · 50% more sales'), 'cta': ('4. SalesMapper', 'free lifetime trial')}
FIX = {'4,': '4', 'Prop': 'PropStream', 'Stream.': '', 'Sales': 'SalesMapper', 'Mapper.': '', 'comment,': 'comment', 'map,': 'MAP'}
def to_out(c, t):
    for x in tl:
        if x['clip'] == c and x['a'] - 0.05 <= t < x['b']: return x['out0'] + max(0, t - x['a'])
words = []
for al, fn, lo in [('HOOK', 'IMG_9921', 0), ('S1', 'IMG_9922', 0), ('I2', 'IMG_9923', 1.5), ('E2', 'IMG_9926', 0), ('I3', 'IMG_9927', 0), ('E3', 'IMG_9929', 0), ('I4', 'IMG_9931', 0), ('E4', 'IMG_9936', 0), ('C4', 'IMG_9937', 0)]:
    for w in W[fn]:
        if w['s'] < lo - 0.1: continue
        t = to_out(al, w['s'])
        if t is None: continue
        txt = FIX.get(w['w'], w['w'])
        if not txt: continue
        if words and t <= words[-1][1] + 0.06: t = words[-1][1] + 0.12
        words.append((txt, F(t)))
words[0] = (words[0][0], 0.0)
red0 = F(C['cta']['comment'])
words = [w for w in words if w[1] < red0] + [('comment MAP', red0)]
def section(t):
    for k, (a, b) in S.items():
        if a - 1e-3 <= t < b - 1e-3: return k
states = []
for i, (w, t0) in enumerate(words):
    t1 = words[i + 1][1] if i + 1 < len(words) else T
    k = section(t0); q = {'w': w}
    if k == 'hook': q.update(ht='10/10 door-to-door tools', hs='(that make you more $)')
    else: q.update(lt=LAB[k][0], ld=LAB[k][1])
    if w == 'comment MAP': q['r'] = '1'
    states.append((q, t0, t1))
# split states at section boundaries so labels switch exactly on the cut
out = []
for q, a, b in states:
    cuts = [x for x, _ in S.values() if a < x < b]
    pts = [a] + cuts + [b]
    for x, y in zip(pts, pts[1:]):
        k = section(x); q2 = dict(q)
        if k != 'hook': q2.pop('ht', None); q2.pop('hs', None); q2.update(lt=LAB[k][0], ld=LAB[k][1])
        out.append((q2, F(x), F(y)))
states = out
page = 'text.html' if VAR == 'ig' else 'text_tt.html'
CAP = f'cap_{VAR}'; os.makedirs(CAP, exist_ok=True)
js = "const { chromium } = require('playwright'); const path=require('path'); (async()=>{const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});\n"
for i, (q, a, b) in enumerate(states):
    js += f"await p.goto('file://'+path.resolve('{page}')+'?{urllib.parse.urlencode(q)}&n={i}'); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(40); await p.screenshot({{path:'{CAP}/{i:03d}.png',omitBackground:true}});\n"
js += "await b.close();})();"; open(f'{CAP}/r.js', 'w').write(js); subprocess.run(['node', f'{CAP}/r.js'], check=True)
a_, b_, c_ = 0.17883277, 0.28466892, 0.55991073
M = np.array([[0.6274, 0.3293, 0.0433], [0.0691, 0.9195, 0.0114], [0.0164, 0.0880, 0.8956]])
def to_hlg(png, out, sig=0.88, wide=False):
    E = (np.exp((sig - c_) / a_) + b_) / 12
    im = cv2.imread(png, cv2.IMREAD_UNCHANGED).astype(np.float64) / 255; rgb = im[..., 2::-1]; al = im[..., 3]
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4) @ (np.eye(3) if wide else M).T * E
    e = np.where(lin <= 1 / 12, np.sqrt(3 * np.clip(lin, 0, None)), a_ * np.log(np.clip(12 * lin - b_, 1e-9, None)) + c_)
    cv2.imwrite(out, (np.dstack([np.clip(e, 0, 1)[..., ::-1], al]) * 65535).round().astype(np.uint16))
HL = f'hl_{VAR}'; os.makedirs(HL, exist_ok=True)
with open(f'{HL}/list.txt', 'w') as L:
    for i, (q, a, b) in enumerate(states):
        to_hlg(f'{CAP}/{i:03d}.png', f'{HL}/{i:03d}.png', wide='r' in q)
        L.write(f"file '{i:03d}.png'\nduration {b - a:.4f}\n")
    L.write(f"file '{len(states) - 1:03d}.png'\n")
# ---- 3. composite in HDR: bg (SDR->HLG LUT), Nathan cut out (original HDR pixels + segmentation mask), soft shadow, text
SC, PW, PH = 0.55, 594, 1056; Y = 1920 - PH + 60                       # head and shoulders rising from the bottom edge
XR, XL = 536, -50
xs = [(S['hook'][1], XR), (S['s1'][1], XL), (S['s2'][1], XR), (S['s3'][1], XL), (S['s4'][1], XR)]
def xexpr(dx=0):
    e = str(XL + dx)
    for t, x in reversed(xs): e = f"if(lt(t\\,{t:.3f})\\,{x + dx}\\,{e})"
    return e
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
fc = ("[0:v]scale=in_color_matrix=bt709:in_range=tv,format=rgb48le,lut3d=sdr2hlg.cube,scale=out_color_matrix=bt2020:out_range=tv,format=yuv420p10le[bg];"
      "[2:v]format=gray,scale=1080:1920:flags=bicubic,tmix=frames=3,lut=y='clip((val-30)*1.25\\,0\\,255)',gblur=sigma=1.2,split=2[m1][m2];"
      f"[1:v]format=yuva420p10le[nv];[nv][m1]alphamerge,scale={PW}:{PH}:flags=lanczos[person];"
      f"[m2]scale={PW}:{PH},gblur=sigma=22,lut=y='val*0.5'[sm];color=c=black:s={PW}x{PH}:r=30,format=yuva420p[blk];[blk][sm]alphamerge[shadow];"
      f"[bg][shadow]overlay=x='{xexpr(14)}':y={Y + 18}:eval=frame:format=yuv420p10[b0];"
      f"[b0][person]overlay=x='{xexpr()}':y={Y}:eval=frame:format=yuv420p10[b1];"
      "[3:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[tx];[b1][tx]overlay=format=yuv420p10:eof_action=pass[v]")
outf = 'tools_v3_instagram.mp4' if VAR == 'ig' else 'tools_v3_tiktok.mp4'
run(['-i', 'bg/bg_sdr.mp4', '-i', 'seg/main.mov', '-framerate', '30', '-i', 'masks/%05d.png', '-f', 'concat', '-safe', '0', '-i', f'{HL}/list.txt', '-filter_complex', fc, '-map', '[v]', '-map', '1:a',
     '-c:v', 'libx265', '-preset', 'medium', '-crf', '15', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
    ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', outf])
print('done', outf, round(T, 2), 's', len(states), 'text states')
