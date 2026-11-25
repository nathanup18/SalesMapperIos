"""Short 7 signs: hook + sign names + close, cut in one filter graph (video and audio trimmed together, so they can't drift)."""
import subprocess, json, wave, numpy as np
FPS = 30; F = lambda x: round(x * FPS) / FPS
SEG = [('HOOK', 'IMG_9985', 7.58, 12.55), ('S1', 'IMG_9986', 3.95, 5.05), ('S2', 'IMG_9987', 4.63, 6.00), ('S3', 'IMG_9988', 3.29, 4.55),
       ('S4', 'IMG_9989', 3.63, 6.55), ('S5', 'IMG_9990', 3.49, 4.32), ('S6', 'IMG_9991', 5.07, 6.40), ('S7', 'IMG_9992', 4.79, 6.06), ('CLOSE', 'IMG_9993', 8.67, 13.0)]
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
ENC = ['-c:v', 'libx265', '-preset', 'fast', '-crf', '12', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR + ['-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '2']
def build(inputs, ranges, out):
    """ranges: list of (input_index, start, end); one graph, trims video+audio on identical frame-rounded bounds."""
    fc = []
    for i, (k, a, b) in enumerate(ranges):
        a, b = F(a), F(b)
        fc.append(f"[{k}:v]trim=start={a}:end={b},setpts=PTS-STARTPTS,fps=30[v{i}];[{k}:a]atrim=start={a}:end={b},asetpts=PTS-STARTPTS,aresample=48000,"
                  f"afade=t=in:d=0.006,afade=t=out:st={b - a - 0.01:.3f}:d=0.01[a{i}]")
    fc.append(''.join(f'[v{i}][a{i}]' for i in range(len(ranges))) + f'concat=n={len(ranges)}:v=1:a=1[v][a]')
    args = []
    for f in inputs: args += ['-i', f]
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + args + ['-filter_complex', ';'.join(fc), '-map', '[v]', '-map', '[a]'] + ENC + [out], check=True)
# pass 1: the chosen phrases
build([f'raw/{c}.MOV' for _, c, _, _ in SEG], [(i, a, b) for i, (_, _, a, b) in enumerate(SEG)], 'q/pass1.mov')
bounds, t = {}, 0
for k, c, a, b in SEG: d = F(b) - F(a); bounds[k] = [t, t + d]; t += d
# pass 2: cut every pause >= 0.12 s (energy), keep 0.04 s each side
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', 'q/pass1.mov', '-ac', '1', '-ar', '16000', 'q/p1.wav'], check=True)
w = wave.open('q/p1.wav'); x = np.frombuffer(w.readframes(w.getnframes()), np.int16) / 32768; T = len(x) / 16000
db = np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + 160] ** 2)) + 1e-9) for i in range(0, len(x) - 160, 160)])
on = db > np.percentile(db, 5) + 12; on = np.array([on[max(0, i - 1):i + 2].sum() >= 2 for i in range(len(on))])
cuts, i = [], 0
while i < len(on):
    if not on[i]:
        j = i
        while j < len(on) and not on[j]: j += 1
        a, b = i / 100, j / 100
        if b - a >= 0.12: cuts.append((a + 0.04 if a > 0.02 else 0.0, b - 0.04))
        i = j
    else: i += 1
keep, cur = [], 0.0
for a, b in cuts:
    if a - cur >= 0.06: keep.append((cur, a))
    cur = b
if T - cur > 0.06: keep.append((cur, T))
keep = [(F(a), F(b)) for a, b in keep if F(b) > F(a)]
build(['q/pass1.mov'], [(0, a, b) for a, b in keep], 'q/main.mov')
def m(y):
    o = 0
    for a, b in keep:
        if y < a: return o
        if y <= b: return o + y - a
        o += b - a
    return o
sec = {k: [F(m(a)), F(m(b))] for k, (a, b) in bounds.items()}
json.dump(sec, open('q/sec.json', 'w')); print(len(cuts), 'pauses cut; length', round(sum(b - a for a, b in keep), 2)); print(sec)
