"""Combine manifest + vision + ASR into per-video rows and a CSV.
Usage: python -I merge.py <scratch_dir> <out_csv>
"""
import sys, os, json, re, statistics as st
import pandas as pd
from rapidfuzz import fuzz

S = sys.argv[1]
OUT = sys.argv[2]
KEYS = ["0.0", "0.5", "1.0", "2.0", "3.0"]
MOTION_T = float(os.environ.get("MOTION_T", "3.0"))
FOLLOWER_FLOOR = 100


def zone(y):
    return "top" if y < 0.25 else "upper-mid" if y < 0.5 else "lower-mid" if y < 0.75 else "bottom"


def hzone(x):
    return "left" if x < 0.38 else "center" if x < 0.62 else "right"


def toks(s):
    return [t for t in re.sub(r"[^a-z0-9$% ]", " ", s.lower()).split() if len(t) >= 2 or t.isdigit()]


def is_watermark(text, author):
    tl = text.lower()
    if "tiktok" in tl or "capcut" in tl or "@" in text or "instagram" in tl:
        return True
    a = re.sub(r"[^a-z0-9]", "", (author or "").lower())
    t = re.sub(r"[^a-z0-9]", "", tl)
    return bool(a) and len(t) >= 4 and (t in a or (len(a) >= 5 and a in t))


def speech_match(line_toks, words, t, win=2.0):
    spoken = [toks(w["w"]) for w in words if t - win <= w["s"] <= t + win]
    spoken = [x for s in spoken for x in s]
    if not line_toks or not spoken:
        return 0.0
    hit = sum(1 for lt in line_toks if max(fuzz.ratio(lt, sp) for sp in spoken) >= 80)
    return hit / len(line_toks)


def analyse(r):
    vid = r["video_id"]
    fv = os.path.join(S, "feat", vid + ".json")
    fa = os.path.join(S, "asr", vid + ".json")
    if not os.path.exists(fv):
        return None
    V = json.load(open(fv))
    A = json.load(open(fa)) if os.path.exists(fa) else {"words": []}
    words = A.get("words", [])
    dur = V["duration"] or r.get("meta_duration") or 0
    out = dict(r)
    out["duration_s"] = round(dur, 2)
    scenes = V["scenes"]
    n = max(1, len(scenes))
    out["shots"] = n
    out["cuts_per_sec"] = round((n - 1) / dur, 3) if dur else None
    out["avg_shot_len_s"] = round(dur / n, 2) if dur else None
    out["cuts_first_5s"] = sum(1 for a, b in scenes if 0 < a <= 5.0)
    out["first_cut_s"] = round(scenes[1][0], 2) if len(scenes) > 1 else None

    # --- timeline classification ---
    tl = {float(k): v for k, v in V["timeline"].items()}
    times = sorted(tl)
    # also put key frames (0.5) into the classification pass
    frames = {t: tl[t]["lines"] for t in times}
    bands_at = {t: tl[t]["bands"] for t in times}
    for k in KEYS:
        if k in V["key"]:
            frames.setdefault(float(k), V["key"][k]["lines"])
            bands_at.setdefault(float(k), V["key"][k]["bands"])
    ft = sorted(frames)
    # drop watermark lines
    for t in ft:
        frames[t] = [l for l in frames[t] if not is_watermark(l["text"], r.get("author"))]
    # persistence: how many consecutive 1 s samples contain a fuzzy-equal line
    def same(a, b):
        return fuzz.ratio(a["text"].lower(), b["text"].lower()) >= 80 and abs((a["y0"] + a["y1"]) - (b["y0"] + b["y1"])) < 0.08

    sec = [t for t in ft if float(t).is_integer()]
    for t in ft:
        for l in frames[t]:
            # run length on the 1 s grid around t
            run = 1
            for direction in (1, -1):
                k = round(t) + direction if float(t).is_integer() else (int(t) + (1 if direction > 0 else 0))
                while k in frames and any(same(l, m) for m in frames[k]):
                    run += 1
                    k += direction
            l["run"] = run
            lt = toks(l["text"])
            l["ntok"] = len(lt)
            l["sm"] = speech_match(lt, words, t) if t < 20 else None
            if l["sm"] is not None and l["sm"] >= 0.5 and run <= 3:
                l["kind"] = "caption"
            elif l.get("single") and run < 3:
                l["kind"] = "noise"     # lone low-confidence token that is not a spoken word
            elif run >= 3:
                l["kind"] = "overlay"   # persistent title / hook / banner text
            else:
                l["kind"] = "popup"     # transient non-caption text
    # caption stats (speech-active seconds within first 20 s)
    speech_secs = [t for t in sec if t < 20 and any(t - 0.6 <= w["s"] <= t + 0.6 or w["s"] <= t <= w["e"] for w in words)]
    cap_frames = [t for t in speech_secs if any(l["kind"] == "caption" for l in frames[t])]
    cap_ratio = len(cap_frames) / len(speech_secs) if speech_secs else 0
    out["speech_secs_sampled"] = len(speech_secs)
    out["caption_frame_ratio"] = round(cap_ratio, 2)
    if speech_secs and cap_ratio >= 0.35:
        chunk = [sum(l["ntok"] for l in frames[t] if l["kind"] == "caption") for t in cap_frames]
        ys = [(l["y0"] + l["y1"]) / 2 for t in cap_frames for l in frames[t] if l["kind"] == "caption"]
        nlines = [sum(1 for l in frames[t] if l["kind"] == "caption") for t in cap_frames]
        cw = st.median(chunk)
        out["caption_style"] = "word-by-word" if cw <= 3 else "sentence"
        out["caption_words_per_chunk"] = cw
        out["caption_lines"] = st.median(nlines)
        out["caption_y"] = round(st.median(ys), 2)
        out["caption_zone"] = zone(st.median(ys))
        out["caption_text_height"] = round(st.median([l["h"] for t in cap_frames for l in frames[t] if l["kind"] == "caption"]), 3)
    else:
        out["caption_style"] = "none" if speech_secs else "none (no speech)"
        out["caption_words_per_chunk"] = None
        out["caption_lines"] = None
        out["caption_y"] = None
        out["caption_zone"] = None
        out["caption_text_height"] = None

    # banner bars: uniform band containing non-caption text
    def banner_in(t):
        res = []
        for b in bands_at.get(t, []):
            if b["y1"] - b["y0"] < 0.04:
                continue
            for l in frames[t]:
                yc = (l["y0"] + l["y1"]) / 2
                if l["kind"] != "caption" and b["y0"] - 0.01 <= yc <= b["y1"] + 0.01:
                    res.append(b)
                    break
        return res

    ban_secs = [t for t in sec if banner_in(t)]
    out["banner_coverage"] = round(len(ban_secs) / len(sec), 2) if sec else 0
    out["banner_persistent"] = out["banner_coverage"] >= 0.6
    if ban_secs:
        ys = [(b["y0"] + b["y1"]) / 2 for t in ban_secs for b in banner_in(t)]
        out["banner_zone"] = zone(st.median(ys))
    else:
        out["banner_zone"] = None
    # letterboxed (content in the middle, bars top & bottom)
    lb = 0
    for t in sec:
        bb = bands_at.get(t, [])
        if any(b["y0"] == 0 for b in bb) and any(b["y1"] >= 0.99 for b in bb):
            lb += 1
    out["letterboxed"] = bool(sec) and lb / len(sec) >= 0.6

    # --- key frames ---
    for k in KEYS:
        tag = k.replace(".0", "").replace(".", "_")
        kf = V["key"].get(k)
        if not kf:
            for f in ["face", "face_zone", "motion", "motion_val", "hook_text", "hook_text_zone", "banner", "captions", "caption_zone"]:
                out[f"f{tag}_{f}"] = None
            continue
        t = float(k)
        fc = kf["faces"]
        out[f"f{tag}_face"] = bool(fc)
        out[f"f{tag}_face_zone"] = f"{zone(fc[0]['cy'])}/{hzone(fc[0]['cx'])}" if fc else None
        mv = kf["motion"]
        cut_now = any(t < a <= t + 0.25 for a, b in scenes)
        out[f"f{tag}_motion_val"] = round(mv, 2) if mv is not None else None
        out[f"f{tag}_motion"] = bool(cut_now or (mv is not None and mv >= MOTION_T))
        ls = frames.get(t, [])
        nc = [l for l in ls if l["kind"] != "caption"]
        out[f"f{tag}_hook_text"] = bool(nc)
        out[f"f{tag}_hook_text_zone"] = zone(st.median([(l["y0"] + l["y1"]) / 2 for l in nc])) if nc else None
        bi = banner_in(t)
        out[f"f{tag}_banner"] = bool(bi)
        cp = [l for l in ls if l["kind"] == "caption"]
        out[f"f{tag}_captions"] = bool(cp)
        out[f"f{tag}_caption_zone"] = zone(st.median([(l["y0"] + l["y1"]) / 2 for l in cp])) if cp else None
    # hook text content (non-caption text visible in the first second)
    hl = []
    for t in (0.0, 0.5, 1.0):
        for l in frames.get(t, []):
            if l["kind"] != "caption" and not any(fuzz.ratio(l["text"], h) >= 80 for h in hl):
                hl.append(l["text"])
    out["hook_text_first_1s"] = " | ".join(hl)[:200]
    out["hook_text_words"] = sum(len(toks(h)) for h in hl)
    first_text = [t for t in ft if any(l["kind"] != "caption" for l in frames[t])]
    out["first_onscreen_text_s"] = first_text[0] if first_text else None

    # pop-ups / text changes on the 1 s grid
    events, prev = [], []
    for t in sec:
        cur = [l for l in frames[t] if l["kind"] != "caption"]
        new = [l for l in cur if not any(same(l, p) for p in prev)]
        if new and t > 0:
            events.append(t)
        prev = cur
    out["text_change_events"] = len(events)
    out["text_changes_per_10s"] = round(10 * len(events) / min(dur, 60), 2) if dur else None
    out["text_change_times"] = " ".join(str(int(e)) for e in events)
    out["onscreen_text_coverage"] = round(sum(1 for t in sec if any(l["kind"] != "caption" for l in frames[t])) / len(sec), 2) if sec else 0

    # --- speech ---
    out["asr_language"] = A.get("language")
    w3 = [w for w in words if w["s"] < 3.0]
    out["spoken_first_3s"] = " ".join(w["w"] for w in w3)
    out["spoken_words_first_3s"] = len(w3)
    out["first_word_s"] = words[0]["s"] if words else None
    out["speech_starts_by_0_5s"] = bool(words) and words[0]["s"] <= 0.5
    # words-per-second in first 10 s of speech (pace)
    w10 = [w for w in words if w["s"] < 10]
    out["words_per_sec_first_10s"] = round(len(w10) / min(10, dur), 2) if dur else None
    # longest pause between words in first 10 s
    gaps = [b["s"] - a["e"] for a, b in zip(w10, w10[1:])]
    out["max_pause_first_10s"] = round(max(gaps), 2) if gaps else None
    out["transcribed"] = os.path.exists(fa)
    if not out["transcribed"]:
        # without a transcript, captions can't be told apart from pop-up text
        for k in ["caption_style", "caption_words_per_chunk", "caption_lines", "caption_y", "caption_zone", "caption_text_height",
                  "text_change_events", "text_changes_per_10s", "text_change_times", "onscreen_text_coverage",
                  "spoken_first_3s", "spoken_words_first_3s", "first_word_s", "speech_starts_by_0_5s", "words_per_sec_first_10s", "max_pause_first_10s"]:
            out[k] = None
        out["caption_style"] = "not transcribed"
    return out


def main():
    man = json.load(open(os.path.join(S, "manifest.json")))
    rows = [x for x in (analyse(r) for r in man) if x]
    df = pd.DataFrame(rows)
    df["followers_used"] = df["followers"].fillna(0).clip(lower=FOLLOWER_FLOOR)
    df["virality"] = (df["views"].fillna(0) / df["followers_used"]).round(3)
    df["quartile"] = ""
    for s, g in df.groupby("set"):
        g = g[g["followers"].notna() & g["views"].notna()]
        q1, q3 = g["virality"].quantile([0.25, 0.75])
        df.loc[g.index[g["virality"] >= q3], "quartile"] = "top25"
        df.loc[g.index[g["virality"] <= q1], "quartile"] = "bottom25"
        df.loc[g.index[(g["virality"] > q1) & (g["virality"] < q3)], "quartile"] = "middle"
    df.to_csv(OUT, index=False)
    print(len(df), "rows ->", OUT)


if __name__ == "__main__":
    main()
