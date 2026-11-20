"""Per-video visual features: scene cuts, key-frame checks, 1 s OCR timeline.
Usage: python -I vision.py <video.mp4> <out.json>
"""
import sys, os, json, re
os.environ.setdefault("OMP_THREAD_LIMIT", "1")
import cv2, numpy as np, pytesseract
from scenedetect import detect, AdaptiveDetector

KEY_TIMES = [0.0, 0.5, 1.0, 2.0, 3.0]
MAX_TIMELINE = 60
CASCADE = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_alt2.xml")


def read_at(cap, t, fps):
    cap.set(cv2.CAP_PROP_POS_FRAMES, int(round(t * fps)))
    ok, f = cap.read()
    return f if ok else None


def faces(img):
    h, w = img.shape[:2]
    s = 480 / w
    g = cv2.cvtColor(cv2.resize(img, None, fx=s, fy=s), cv2.COLOR_BGR2GRAY)
    g = cv2.equalizeHist(g)
    found = CASCADE.detectMultiScale(g, 1.1, 5, minSize=(int(480 * 0.09),) * 2)
    out = []
    for (x, y, fw, fh) in found:
        out.append({"cx": (x + fw / 2) / 480, "cy": (y + fh / 2) / (h * s),
                    "area": fw * fh / (480 * h * s)})
    return sorted(out, key=lambda f: -f["area"])


def motion(a, b):
    if a is None or b is None:
        return None
    sa = cv2.cvtColor(cv2.resize(a, (72, 128)), cv2.COLOR_BGR2GRAY).astype(float)
    sb = cv2.cvtColor(cv2.resize(b, (72, 128)), cv2.COLOR_BGR2GRAY).astype(float)
    return float(np.abs(sa - sb).mean())


def bands(img):
    """Full-width uniform horizontal bands with a sharp edge (banner bars / letterbox)."""
    sm = cv2.resize(img, (90, 160)).astype(int)
    med = np.median(sm, axis=1)
    frac = ((np.abs(sm - med[:, None, :]).sum(2)) < 45).mean(1)
    uni = frac > 0.80  # text inside the bar lowers uniformity, so be lenient
    out, y = [], 0
    while y < 160:
        if uni[y]:
            y0 = y
            while y < 160 and uni[y]:
                y += 1
            y1 = y
            if y1 - y0 >= 6:
                col = np.median(med[y0:y1], axis=0)
                edges = []
                if y0 > 0:
                    edges.append(np.abs(sm[y0 - 1] - col).sum(1).mean())
                if y1 < 160:
                    edges.append(np.abs(sm[min(y1, 159)] - col).sum(1).mean())
                sharp = (not edges) or max(edges) > 50
                if sharp and (y1 - y0) < 0.6 * 160:
                    out.append({"y0": y0 / 160, "y1": y1 / 160,
                                "lum": float(col.mean())})
        else:
            y += 1
    return out


WORD_RE = re.compile(r"[A-Za-z0-9$%']")


def ocr_lines(img):
    h, w = img.shape[:2]
    s = 720 / w
    im = cv2.resize(img, None, fx=s, fy=s)
    H = im.shape[0]
    hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV)
    gray = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY)
    white = (((hsv[..., 2] > 195) & (hsv[..., 1] < 60)).astype(np.uint8) * 255)
    bright_col = (((hsv[..., 2] > 170) & (hsv[..., 1] > 120)).astype(np.uint8) * 255)  # yellow/green highlight words
    _, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    variants = [255 - white, 255 - bright_col, otsu]
    lines = []
    for vi, v in enumerate(variants):
        d = pytesseract.image_to_data(v, config="--psm 11", output_type=pytesseract.Output.DICT)
        groups = {}
        for i, txt in enumerate(d["text"]):
            txt = txt.strip()
            conf = float(d["conf"][i])
            if conf < 60 or len(txt) < 2 or len(WORD_RE.findall(txt)) < max(2, len(txt) * 0.6):
                continue
            if d["height"][i] < H * 0.014:
                continue
            k = (d["block_num"][i], d["par_num"][i], d["line_num"][i])
            groups.setdefault(k, []).append((txt, d["left"][i], d["top"][i], d["width"][i], d["height"][i], conf))
        for ws in groups.values():
            x0 = min(a[1] for a in ws); y0 = min(a[2] for a in ws)
            x1 = max(a[1] + a[3] for a in ws); y1 = max(a[2] + a[4] for a in ws)
            text = " ".join(a[0] for a in ws)
            alpha = sum(ch.isalpha() for ch in text)
            if alpha < 2:
                continue
            # single short tokens are kept but flagged; merge.py keeps them only if they match speech
            lines.append({"text": text, "x0": x0 / 720, "y0": y0 / H, "x1": x1 / 720, "y1": y1 / H,
                          "h": float(np.mean([a[4] for a in ws]) / H), "conf": float(np.mean([a[5] for a in ws])),
                          "v": vi, "single": len(ws) == 1 and (len(text) < 4 or ws[0][5] < 80)})
    # de-duplicate across variants by vertical overlap + text
    lines.sort(key=lambda l: -l["conf"])
    keep = []
    for l in lines:
        dup = False
        for k in keep:
            ov = min(l["y1"], k["y1"]) - max(l["y0"], k["y0"])
            if ov > 0.5 * min(l["y1"] - l["y0"], k["y1"] - k["y0"]) and (
                    min(l["x1"], k["x1"]) - max(l["x0"], k["x0"]) > 0):
                dup = True
                break
        if not dup:
            keep.append(l)
    return keep


def main(path, out):
    cap = cv2.VideoCapture(path)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    n = cap.get(cv2.CAP_PROP_FRAME_COUNT)
    dur = n / fps if n > 0 else 0
    W = cap.get(cv2.CAP_PROP_FRAME_WIDTH); H = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
    res = {"duration": dur, "fps": fps, "w": W, "h": H}
    try:
        sl = detect(path, AdaptiveDetector(min_scene_len=8))
        res["scenes"] = [(a.seconds, b.seconds) for a, b in sl] or [(0, dur)]
    except Exception as e:
        res["scenes"] = [(0, dur)]; res["scene_err"] = str(e)
    key = {}
    for t in KEY_TIMES:
        if t >= dur:
            continue
        f = read_at(cap, t, fps); f2 = read_at(cap, t + 0.2, fps)
        if f is None:
            continue
        key[str(t)] = {"faces": faces(f), "motion": motion(f, f2), "lines": ocr_lines(f), "bands": bands(f)}
        os.makedirs(os.path.dirname(out) + "/frames", exist_ok=True)
        cv2.imwrite(os.path.dirname(out) + "/frames/%s_%s.jpg" % (os.path.basename(out)[:-5], t),
                    cv2.resize(f, (270, int(270 * f.shape[0] / f.shape[1]))))
    res["key"] = key
    tl = {}
    t = 0
    while t < min(dur, MAX_TIMELINE):
        if str(float(t)) in key:
            tl[str(t)] = {"lines": key[str(float(t))]["lines"], "bands": key[str(float(t))]["bands"]}
        else:
            f = read_at(cap, t, fps)
            if f is not None:
                tl[str(t)] = {"lines": ocr_lines(f), "bands": bands(f)}
        t += 1
    res["timeline"] = tl
    json.dump(res, open(out, "w"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
