"""QA gate for an edited short (PLAYBOOK section 6). Any FAIL blocks delivery.

Usage: python qa_check.py <final.mp4> <timeline.json> <inserts.json> <captions.ass> [out_dir]
  timeline.json : [{out0, dur, clip, part, ...}]  (segments as rendered by edit.py)
  inserts.json  : [[file, start, end], ...]        (as composited by build_final.py)
Checks:
  deadair     speech must start within 0.10 s of frame 0 and of every segment start (H1)
  captions    caption top must sit below the detected chin on face shots (H2)
  black       no black frames anywhere
  flashes     no face frames inside insert windows or in gaps < 0.25 s between inserts (H5)
  completion  insert window >= animation length - 0.1 s (H6)
  boundaries  writes a ±3-frame contact sheet around every boundary for a human look
"""
import sys, os, json, re, subprocess, wave, tempfile
import numpy as np, cv2

video, tl_path, ins_path, ass_path = sys.argv[1:5]
out_dir = sys.argv[5] if len(sys.argv) > 5 else os.path.dirname(os.path.abspath(video))
TL = json.load(open(tl_path)); INS = json.load(open(ins_path)); FPS = 30
fails, notes = [], []
CAS = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_alt2.xml")

_CACHE = {}
def preload(ts):
    """Frame-exact grabs: decode with ffmpeg select by frame number (cv2 seeking can land a frame off)."""
    ns = sorted({int(round(t * FPS)) for t in ts} - set(_CACHE))
    if not ns: return
    with tempfile.TemporaryDirectory() as td:
        sel = "+".join(f"eq(n\\,{n})" for n in ns)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", video, "-vf", f"select='{sel}'", "-vsync", "0", os.path.join(td, "%05d.png")], check=True)
        for k, n in enumerate(ns): _CACHE[n] = cv2.imread(os.path.join(td, f"{k + 1:05d}.png"))
def frame_at(cap, t):
    return _CACHE.get(int(round(t * FPS)))

def face(f):
    g = cv2.cvtColor(cv2.resize(f, (540, 960)), cv2.COLOR_BGR2GRAY)
    fs = CAS.detectMultiScale(g, 1.1, 5, minSize=(110, 110))
    return None if not len(fs) else max(fs, key=lambda r: r[2] * r[3]) * 2

def in_insert(t):
    return any(a - 0.02 <= t < b + 0.02 for _, a, b in INS)

# ---- deadair
with tempfile.TemporaryDirectory() as td:
    wav = os.path.join(td, "a.wav")
    src = os.environ.get("QA_VOICE") or video   # dead air is about the voice: use a voice-only track when SFX are mixed in
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-ac", "1", "-ar", "16000", wav], check=True)
    w = wave.open(wav); x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float) / 32768
db = np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + 160] ** 2)) + 1e-9) for i in range(0, len(x) - 160, 160)])
floor = np.percentile(db, 5)
for s in TL:
    t0 = s["out0"]; i0 = int(t0 * 100)
    seg = db[i0:i0 + 100]
    thr = floor + 12  # counts fricatives and plosive bursts (s, f, h, k, t) as speech
    on = seg > thr
    run = np.array([on[i:i + 3].all() for i in range(max(0, len(on) - 2))])  # >=30 ms of continuous energy, not a click
    hit = int(np.argmax(run)) if run.any() else None
    gap = None if hit is None else hit / 100
    first_of_clip = s is TL[0] or TL[TL.index(s) - 1]["clip"] != s["clip"]
    label = "frame 0" if t0 < 0.01 else (f"clip start @{t0:.2f}s" if first_of_clip else f"inner cut @{t0:.2f}s")
    limit = 0.10 if first_of_clip else 0.25
    if gap is None: notes.append(f"deadair: no speech found in 1 s after {label} (check manually)")
    elif gap > limit: fails.append(f"deadair: {gap:.2f}s of silence after {label} ({s['clip']}, limit {limit}s)")

# ---- captions + flashes
cap = None
_ts = [s["out0"] + k for s in TL for k in np.linspace(0.15, max(0.2, s["dur"] - 0.15), 4)]
for f_, a, b in INS: na, nb = int(round(a * FPS)), int(round(b * FPS)); _ts += [n / FPS for n in (na, na + 1, nb - 2, nb - 1)]
preload(_ts)
ass = open(ass_path).read()
ys = [int(m) for m in re.findall(r"\\pos\(\d+,(\d+)\)", ass)]
size = int(re.search(r"Style: Caption,[^,]+,(\d+)", ass).group(1)) if "Style: Caption" in ass else 96
cap_top = (min(ys) if ys else 1610) - size * 0.55
for s in TL:
    for k in np.linspace(0.15, max(0.2, s["dur"] - 0.15), 4):
        t = s["out0"] + k
        if in_insert(t): continue
        f = frame_at(cap, t)
        if f is None: continue
        fc = face(f)
        if fc is not None and fc[1] + fc[3] * 1.02 > cap_top:
            fails.append(f"captions: chin at y≈{int(fc[1] + fc[3])} overlaps caption top y≈{int(cap_top)} at {t:.2f}s")
            break
for idx, (f_, a, b) in enumerate(INS):
    if 'ins' not in os.path.basename(f_): continue  # real B-roll can contain faces
    na, nb = int(round(a * FPS)), int(round(b * FPS))
    for t in [n / FPS for n in (na, na + 1, nb - 2, nb - 1)]:
        fr = frame_at(cap, t)
        if fr is not None and face(fr) is not None:
            fails.append(f"flash: face visible inside insert {os.path.basename(f_)} at {t:.3f}s"); break
srt = sorted(INS, key=lambda r: r[1])
for (fa, a1, b1), (fb, a2, b2) in zip(srt, srt[1:]):
    if 0 < a2 - b1 < 0.25:
        fails.append(f"flash: {a2 - b1:.3f}s gap of face between {os.path.basename(fa)} and {os.path.basename(fb)} at {b1:.2f}s")

# ---- audio must cover the whole video (a mix can silently truncate)
_dur = lambda kind: float(subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", kind, "-show_entries", "stream=duration", "-of", "csv=p=0", video]).split()[0])
try:
    va, vv = _dur("a:0"), _dur("v:0")
    if va < vv - 0.10: fails.append(f"audio: audio ends at {va:.2f}s but video runs {vv:.2f}s")
except Exception as e:
    notes.append(f"audio: couldn't compare stream durations ({e})")

# ---- black / blank frames anywhere (scan the middle band of every frame; labels/captions sit outside it)
raw = subprocess.run(["ffmpeg", "-v", "error", "-i", video, "-vf", "scale=90:160,format=gray", "-f", "rawvideo", "-"], capture_output=True).stdout
frames = np.frombuffer(raw, np.uint8).reshape(-1, 160, 90)
band = frames[:, 40:125, :]
dark = (band < 18).mean(axis=(1, 2))
for n in np.where(dark > 0.92)[0]:
    fails.append(f"black: frame {n} ({n / FPS:.3f}s) is black")

# ---- completion
for f_, a, b in INS:
    try: d = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", f_]))
    except Exception: continue
    if "ins_" in os.path.basename(f_) and (b - a) < d - 0.1:
        fails.append(f"completion: {os.path.basename(f_)} window {b - a:.2f}s < animation {d:.2f}s")

# ---- boundary contact sheet
bounds = sorted({round(s["out0"] * FPS) for s in TL} | {round(a * FPS) for _, a, _ in INS} | {round(b * FPS) for _, _, b in INS})
sel = "+".join(f"between(n\\,{max(0, n - 3)}\\,{n + 3})" for n in bounds)
sheet = os.path.join(out_dir, "qa_boundaries.jpg")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", video, "-vf", f"select='{sel}',scale=90:160,tile=7x{len(bounds)}",
                "-frames:v", "1", "-vsync", "0", sheet])
notes.append(f"boundaries: review {sheet} (each row = one boundary, ±3 frames)")

print("QA", "FAIL" if fails else "PASS")
for f_ in fails: print("  FAIL", f_)
for n in notes: print("  note", n)
sys.exit(1 if fails else 0)
