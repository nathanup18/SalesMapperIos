"""Last check before any file goes to Nathan. Works on every edit type (tips videos,
IQ term-card videos, plain splices), with no timeline needed. Any FAIL blocks delivery.

Usage: python delivery_check.py <final.mp4> [source_clip.MOV] [--no-audio-ok]

Checks:
  decode   full decode of video and audio: zero decoder errors (F43: a shipped file had ~3,000 AAC errors)
  hdr      output is still HLG / bt2020 / 10-bit (H9)
  sync     audio and video durations within 0.1 s (F25)
  luma     with a source clip: mean 10-bit luma of frame 1.0 s within 1% of the source (H0)
"""
import sys, json, subprocess

args = [a for a in sys.argv[1:] if not a.startswith("--")]
no_audio_ok = "--no-audio-ok" in sys.argv
video = args[0]
source = args[1] if len(args) > 1 else None
fails = []


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


# decode: -v error prints one line per decoder error
r = run(["ffmpeg", "-v", "error", "-i", video, "-f", "null", "-"])
errs = [l for l in r.stderr.splitlines() if l.strip()]
if errs:
    fails.append(f"decode: {len(errs)} decoder errors, first: {errs[0][:120]}")

probe = json.loads(run(["ffprobe", "-v", "error", "-show_streams", "-of", "json", video]).stdout)
vs = [s for s in probe["streams"] if s["codec_type"] == "video"]
aus = [s for s in probe["streams"] if s["codec_type"] == "audio"]
v = vs[0]

# hdr
if v.get("color_transfer") != "arib-std-b67" or v.get("color_primaries") != "bt2020" \
        or "10" not in v.get("pix_fmt", ""):
    fails.append(f"hdr: transfer={v.get('color_transfer')} primaries={v.get('color_primaries')} "
                 f"pix_fmt={v.get('pix_fmt')} (want arib-std-b67 / bt2020 / 10-bit)")

# sync
if aus:
    dv, da = float(v.get("duration", 0)), float(aus[0].get("duration", 0))
    if abs(dv - da) > 0.1:
        fails.append(f"sync: video {dv:.2f} s vs audio {da:.2f} s")
elif not no_audio_ok:
    fails.append("sync: no audio stream (pass --no-audio-ok if Nathan will mute it)")


if source:
    def luma_bytes(path, t=1.0):
        import numpy as np
        p = subprocess.run(["ffmpeg", "-v", "error", "-ss", str(t), "-i", path, "-frames:v", "1",
                            "-vf", "scale=270:480,format=gray10le", "-f", "rawvideo", "-"],
                           capture_output=True)
        return float(np.frombuffer(p.stdout, dtype="<u2").mean())
    lo, ls = luma_bytes(video), luma_bytes(source)
    if ls and abs(lo - ls) / ls > 0.01:
        fails.append(f"luma: output {lo:.0f} vs source {ls:.0f} (>1%); picture changed (H0)")

print("DELIVERY", "FAIL" if fails else "PASS", video)
for f in fails:
    print("  FAIL", f)
sys.exit(1 if fails else 0)
