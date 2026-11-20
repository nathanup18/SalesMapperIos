"""Search Pixabay for commercial-use B-roll and download the best rendition.
Usage: PIXABAY_KEY=... python -I broll.py <out_dir>
Skips AI-generated clips, keeps 4-30 s clips, records credits in credits.csv.
"""
import os, sys, json, csv, shutil, urllib.request, urllib.parse
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) video-template-builder"}
def get(u): return urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=120)

KEY = os.environ["PIXABAY_KEY"]
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
QUERIES = {
    "door-knock": ["knocking door", "doorbell", "front door"],
    "walk-up": ["walking sidewalk", "man walking neighborhood", "walking to house"],
    "neighborhood": ["suburban street", "neighborhood houses", "residential street aerial", "suburb aerial"],
    "house-exterior": ["house exterior", "family home", "porch"],
    "work": ["salesman", "handshake", "phone map", "using smartphone street"],
    "trades": ["solar panels roof", "pest control", "roofing"],
}
PER_QUERY = 3
seen, rows = set(), []
for group, qs in QUERIES.items():
    for q in qs:
        url = "https://pixabay.com/api/videos/?" + urllib.parse.urlencode(
            {"key": KEY, "q": q, "per_page": 20, "safesearch": "true", "order": "popular", "video_type": "film"})
        hits = json.loads(get(url).read())["hits"]
        n = 0
        for h in hits:
            if n >= PER_QUERY:
                break
            tags = h.get("tags", "").lower()
            if h["id"] in seen or "ai generated" in tags or "animation" in tags or not (4 <= h["duration"] <= 30):
                continue
            v = h["videos"].get("large") or h["videos"].get("medium")
            if not v or not v.get("url") or v["width"] < 1280:
                continue
            seen.add(h["id"]); n += 1
            fn = f"{group}_{q.replace(' ', '-')}_{h['id']}.mp4"
            path = os.path.join(OUT, fn)
            if not os.path.exists(path):
                with get(v["url"]) as r, open(path, "wb") as f: shutil.copyfileobj(r, f)
            rows.append({"file": fn, "group": group, "query": q, "pixabay_page": h["pageURL"], "creator": h.get("user"),
                         "duration_s": h["duration"], "width": v["width"], "height": v["height"], "tags": h["tags"]})
            print(fn, v["width"], v["height"], h["duration"], flush=True)
with open(os.path.join(OUT, "credits.csv"), "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader(); w.writerows(rows)
print(len(rows), "clips")
