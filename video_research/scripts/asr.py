"""Whisper transcription of the first 20 s of each video, with word timestamps.
Usage: python -I asr.py <out_dir> <video1.mp4> [video2.mp4 ...]
"""
import sys, os, json, subprocess, tempfile
import torch
torch.set_num_threads(int(os.environ.get("ASR_THREADS", "2")))
import whisper

out_dir = sys.argv[1]
model = whisper.load_model(os.environ.get("ASR_MODEL","small"))
for p in sys.argv[2:]:
    vid = os.path.basename(p)[:-4]
    out = os.path.join(out_dir, vid + ".json")
    if os.path.exists(out):
        continue
    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, "a.wav")
        r = subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", p, "-t", "20", "-ac", "1", "-ar", "16000", wav])
        if r.returncode or not os.path.exists(wav):
            json.dump({"error": "no audio", "words": []}, open(out, "w")); continue
        res = model.transcribe(wav, word_timestamps=True, fp16=False, condition_on_previous_text=False)
    words = [{"w": w["word"].strip(), "s": round(w["start"], 2), "e": round(w["end"], 2), "p": round(w.get("probability", 0), 2)}
             for seg in res["segments"] for w in seg.get("words", [])
             if seg.get("no_speech_prob", 0) < 0.6]
    json.dump({"language": res.get("language"), "words": words}, open(out, "w"))
    print(vid, len(words), flush=True)
