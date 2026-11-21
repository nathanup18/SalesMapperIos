"""Edit the 5 raw clips into one short: tight cuts, punch-ins, cutaways, labels, captions."""
import json, wave, subprocess, os
import numpy as np

D = os.path.dirname(os.path.abspath(__file__))
SC = os.path.dirname(D)
os.chdir(D)
W = json.load(open('words.json'))
GRADE = "zscale=tin=bt709:t=bt709:min=bt2020nc:m=bt709:pin=bt2020:p=bt709:rin=tv:r=tv,format=yuv420p,eq=contrast=1.06:saturation=1.04:gamma=0.97"

# order + per-clip source window (skip false start in 9722)
ORDER = [("IMG_9714", 0, 99, "hook"), ("IMG_9722", 9.6, 99, "tip1"), ("IMG_9721", 0, 99, "tip2"),
         ("IMG_9724", 0, 99, "tip3"), ("IMG_9725", 0, 99, "cta")]
GAP_MAX, KEEP_AFTER, KEEP_BEFORE, HEAD, TAIL = 0.30, 0.10, 0.08, 0.06, 0.14


def regions(name):
    a = wave.open(name + '.wav'); x = np.frombuffer(a.readframes(a.getnframes()), np.int16).astype(float) / 32768
    sr = a.getframerate(); hop = int(sr * 0.01)
    db = 20 * np.log10(np.array([np.sqrt(np.mean(x[i:i + hop] ** 2)) for i in range(0, len(x) - hop, hop)]) + 1e-9)
    thr = np.percentile(db, 10) + 10
    sp = db > thr; out = []; i = 0
    while i < len(sp):
        if sp[i]:
            j = i
            while j < len(sp) and sp[j]: j += 1
            if j - i >= 5: out.append([i * .01, j * .01])
            i = j
        else: i += 1
    m = []
    for r in out:
        if m and r[0] - m[-1][1] < 0.15: m[-1][1] = r[1]
        else: m.append(r)
    return m, len(x) / sr


segs = []  # (clip, a, b, part)
for name, lo, hi, part in ORDER:
    regs, dur = regions(name)
    ws = [w for w in W[name] if lo <= w['s'] < hi]
    first, last = ws[0]['s'], ws[-1]['e']
    regs = [r for r in regs if r[1] > first - 0.3 and r[0] < last + 0.4 and r[0] >= lo]
    start = max(lo, min(regs[0][0], first + 0.12) - HEAD)
    end = min(dur - 0.02, max(regs[-1][1], last) + TAIL)
    cur = start
    for r0, r1 in zip(regs, regs[1:]):
        gap = r1[0] - r0[1]
        if gap > GAP_MAX:
            segs.append((name, cur, r0[1] + KEEP_AFTER, part)); cur = r1[0] - KEEP_BEFORE
    segs.append((name, cur, end, part))

OVERRIDE_START = {"IMG_9722": 10.10}  # trim breath/dead air before "One"
for k,(n,a0,b0,p) in enumerate(segs):
    if n in OVERRIDE_START and a0 < OVERRIDE_START[n] and (k==0 or segs[k-1][0]!=n):
        segs[k]=(n,OVERRIDE_START[n],b0,p)
# render segments with alternating punch-in
os.makedirs('segs', exist_ok=True)
t = 0.0; timeline = []
with open('segs/list.txt', 'w') as L:
    for i, (name, a, b, part) in enumerate(segs):
        z = 1.0 if i % 2 == 0 else 1.12
        crop = f"crop=iw/{z}:ih/{z}:(iw-ow)/2:(ih-oh)*0.36,scale=1080:1920:flags=lanczos," if z > 1 else ""
        out = f'segs/s{i:02d}.mp4'
        d = b - a
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', f'{name}.MOV', '-t', f'{d:.3f}',
                        '-vf', f'{GRADE},{crop}fps=30,setsar=1', '-af', f'afade=t=in:d=0.012,afade=t=out:st={d - 0.015:.3f}:d=0.015',
                        '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libx264', '-preset', 'medium', '-crf', '16', '-pix_fmt', 'yuv420p',
                        '-c:a', 'aac', '-ar', '48000', '-b:a', '192k', out], check=True)
        real = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out]))
        timeline.append(dict(i=i, clip=name, a=round(a, 3), b=round(b, 3), part=part, out0=round(t, 3), dur=round(real, 3), zoom=z))
        L.write(f"file 's{i:02d}.mp4'\n"); t += real
json.dump(timeline, open('timeline.json', 'w'), indent=1)
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', 'segs/list.txt', '-c', 'copy', 'main.mp4'], check=True)


def to_out(clip, s):
    for seg in timeline:
        if seg['clip'] == clip and seg['a'] <= s < seg['b']:
            return seg['out0'] + (s - seg['a'])
    return None


# words on the output timeline
FIX = {"Renock": "Re-knock", "$1000": "$1,000"}
words = []
for name, lo, hi, part in ORDER:
    for w in W[name]:
        if w['s'] < lo: continue
        o = to_out(name, w['s'] + 0.02)
        if o is not None:
            words.append(dict(w=FIX.get(w['w'], w['w']), s=o, e=o + (w['e'] - w['s']), clip=name, part=part))
json.dump(words, open('out_words.json', 'w'), indent=0)
parts = {}
for seg in timeline:
    p = parts.setdefault(seg['part'], [seg['out0'], seg['out0'] + seg['dur']]); p[1] = seg['out0'] + seg['dur']
json.dump(parts, open('parts.json', 'w'))
print('total', round(t, 2), 's;', len(segs), 'segments')
for k, v in parts.items(): print(k, [round(x, 2) for x in v])
