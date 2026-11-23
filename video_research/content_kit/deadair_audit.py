"""Dead-air audit: every silent run >= MIN s in a video's voice track (speech = >=30 ms above floor+12 dB, plosive-aware like qa_check)."""
import sys, subprocess, wave, numpy as np
src = sys.argv[1]; MIN = float(sys.argv[2]) if len(sys.argv) > 2 else 0.15
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', src, '-ac', '1', '-ar', '16000', '/tmp/_a.wav'], check=True)
w = wave.open('/tmp/_a.wav'); x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32768
db = np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + 160] ** 2)) + 1e-9) for i in range(0, len(x) - 160, 160)])
on = db > np.percentile(db, 5) + 12
sp = np.array([on[max(0, i - 1):i + 2].sum() >= 2 for i in range(len(on))])   # smooth single-frame flicker
runs, i = [], 0
while i < len(sp):
    if not sp[i]:
        j = i
        while j < len(sp) and not sp[j]: j += 1
        if (j - i) / 100 >= MIN: runs.append((i / 100, j / 100))
        i = j
    else: i += 1
first = next(k for k in range(len(sp)) if sp[k]) / 100
print(f'first speech at {first:.2f}s | gaps >= {MIN}s: {len(runs)} | total dead air {sum(b - a for a, b in runs):.2f}s | length {len(x) / 16000:.1f}s')
for a, b in runs: print(f'  {a:6.2f}-{b:6.2f}  {b - a:.2f}s')
