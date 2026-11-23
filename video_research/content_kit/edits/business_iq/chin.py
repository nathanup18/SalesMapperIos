"""Chin tracking for card placement (F45): YuNet face box bottom ~= chin in the 1.2x zoomed frame.
Card top = lowest chin during that card's window + 20 px. Writes seg/tops.json, read by render.js.
Needs the YuNet model: YUNET=path/to/face_detection_yunet_2023mar.onnx (media.githubusercontent.com, opencv_zoo)."""
import cv2, subprocess, json, os, numpy as np
d = cv2.FaceDetectorYN.create(os.environ.get('YUNET', 'yunet.onnx'), '', (540, 960), 0.7)
def chin(t):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f'{t:.3f}', '-i', 'seg/main.mov', '-frames:v', '1', '-vf',
                        'scale=1296:2304:flags=bilinear,crop=1080:1920:108:384,scale=540:960', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-'], capture_output=True).stdout
    _, f = d.detect(np.frombuffer(r, np.uint8).reshape(960, 540, 3))
    return None if f is None else int((f[0][1] + f[0][3]) * 2)
tops = {}
for k, a, b in json.load(open('seg/cards.json')):
    c = [x for x in (chin(t) for t in np.arange(a, b, 0.1)) if x]
    tops[k] = min(1222, max(c) + 20) if c else 1222
    print(f'{k:8s} chin max {max(c) if c else None}  top {tops[k]}')
json.dump(tops, open('seg/tops.json', 'w'), indent=1)
