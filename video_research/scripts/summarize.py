"""Group comparison table from the per-video CSV.
Usage: python -I summarize.py <csv> <out_md_table> <out_json>
"""
import sys, json
import pandas as pd, numpy as np
from scipy.stats import mannwhitneyu, fisher_exact

df = pd.read_csv(sys.argv[1])
NUM = [("duration_s", "Length (s)"), ("cuts_per_sec", "Cuts per second"), ("avg_shot_len_s", "Avg shot length (s)"),
       ("cuts_first_5s", "Cuts in first 5 s"), ("first_cut_s", "First cut at (s)"),
       ("first_word_s", "First spoken word at (s)"), ("spoken_words_first_3s", "Spoken words in first 3 s"),
       ("words_per_sec_first_10s", "Words/sec, first 10 s"), ("max_pause_first_10s", "Longest pause, first 10 s (s)"),
       ("hook_text_words", "Hook text words (first 1 s)"), ("first_onscreen_text_s", "First on-screen text at (s)"),
       ("text_changes_per_10s", "Text pop-ups per 10 s"), ("onscreen_text_coverage", "Share of seconds with on-screen text"),
       ("caption_words_per_chunk", "Caption words per chunk (when captioned)"), ("caption_y", "Caption height on screen (0=top)"),
       ("f0_motion_val", "Motion at 0 s (pixel diff)")]
BOOL = [("f0_face", "Face at 0 s"), ("f1_face", "Face at 1 s"), ("f0_motion", "Motion/cut at 0 s"),
        ("f0_hook_text", "Text on screen at 0 s"), ("f1_hook_text", "Text on screen at 1 s"),
        ("f0_banner", "Banner bar at 0 s"), ("banner_persistent", "Persistent banner bar (60%+ of video)"),
        ("has_captions", "Burned-in captions"), ("wbw", "Word-by-word captions (1-3 words)"),
        ("sentence", "Sentence captions (4+ words)"), ("speech_starts_by_0_5s", "Speaking by 0.5 s"),
        ("letterboxed", "Letterboxed (bars top and bottom)")]

T = df["transcribed"].astype(str) == "True"
df["has_captions"] = df["caption_style"].isin(["word-by-word", "sentence"])
df["wbw"] = df["caption_style"] == "word-by-word"
df["sentence"] = df["caption_style"] == "sentence"
for c, _ in BOOL:
    df[c] = df[c].map(lambda v: str(v).lower() == "true" if not isinstance(v, (bool, np.bool_)) else bool(v))
for c in ["has_captions", "wbw", "sentence", "speech_starts_by_0_5s"]:
    df[c] = df[c].where(T)

groups = {}
for s in ["niche", "general"]:
    for q in ["top25", "bottom25"]:
        groups[f"{s} {q}"] = df[(df.set == s) & (df.quartile == q)]
    groups[f"{s} all"] = df[df.set == s]


def fmt_num(x):
    return "" if pd.isna(x) else (f"{x:.2f}" if abs(x) < 10 else f"{x:.1f}")


rows, res = [], {}
cols = ["niche top25", "niche bottom25", "p(niche)", "general top25", "general bottom25", "p(gen)", "niche all", "general all", "p(niche vs gen)"]
for c, label in NUM:
    r = [label]
    res[c] = {}
    for g in cols:
        if g.startswith("p("):
            a, b = {"p(niche)": ("niche top25", "niche bottom25"), "p(gen)": ("general top25", "general bottom25"),
                    "p(niche vs gen)": ("niche all", "general all")}[g]
            x, y = groups[a][c].dropna(), groups[b][c].dropna()
            p = mannwhitneyu(x, y).pvalue if len(x) > 3 and len(y) > 3 else np.nan
            r.append(fmt_num(p)); res[c][g] = p
        else:
            v = groups[g][c].median()
            r.append(fmt_num(v)); res[c][g] = v
    rows.append(r)
for c, label in BOOL:
    r = [label + " (%)"]
    res[c] = {}
    for g in cols:
        if g.startswith("p("):
            a, b = {"p(niche)": ("niche top25", "niche bottom25"), "p(gen)": ("general top25", "general bottom25"),
                    "p(niche vs gen)": ("niche all", "general all")}[g]
            x, y = groups[a][c].dropna().astype(bool), groups[b][c].dropna().astype(bool)
            p = fisher_exact([[x.sum(), len(x) - x.sum()], [y.sum(), len(y) - y.sum()]]).pvalue
            r.append(fmt_num(p)); res[c][g] = p
        else:
            v = 100 * groups[g][c].dropna().astype(float).mean()
            r.append(f"{v:.0f}"); res[c][g] = v
    rows.append(r)

# modal positions
for c, label in [("caption_zone", "Caption zone (mode)"), ("f0_hook_text_zone", "Hook text zone at 0 s (mode)"),
                 ("banner_zone", "Banner zone (mode)"), ("f0_face_zone", "Face zone at 0 s (mode)")]:
    r = [label]
    for g in cols:
        if g.startswith("p("):
            r.append("")
        else:
            vc = groups[g][c].dropna().value_counts()
            r.append(f"{vc.index[0]} ({100*vc.iloc[0]/vc.sum():.0f}%)" if len(vc) else "")
    rows.append(r)

ns = ["n"] + [("" if g.startswith("p(") else str(len(groups[g]))) for g in cols]
table = pd.DataFrame([ns] + rows, columns=["Metric"] + cols)
open(sys.argv[2], "w").write(table.to_markdown(index=False))
json.dump({k: {g: (None if (v is None or (isinstance(v, float) and np.isnan(v))) else float(v)) for g, v in d.items()} for k, d in res.items()},
          open(sys.argv[3], "w"), indent=1)
print(table.to_string(index=False))
# virality cut-offs
for s in ["niche", "general"]:
    g = df[df.set == s]
    print(s, "virality q25/q50/q75:", g.virality.quantile([.25, .5, .75]).round(2).tolist(),
          "views median top/bottom:", groups[f"{s} top25"].views.median(), groups[f"{s} bottom25"].views.median())
