"""Day-one rep / manager scene (Higgsfield Kling 3.0 footage). H1 cuts, H10 hook card, H12 captions, H13 two versions."""
import json, os, subprocess, wave
import numpy as np
os.chdir(os.path.dirname(os.path.abspath(__file__)))
FPS = 30; F = lambda x: round(x * FPS) / FPS; out = 'build'; os.makedirs(out, exist_ok=True)
SEGS = [(0.45, 1.75), (2.60, 4.95), (5.30, 7.72), (8.22, 8.65), (8.95, 9.95), (11.00, 12.15), (12.80, 14.45)]
HOLD = 1.6   # freeze on the final wide shot under the follow card
WORDS = [("Forty", .58, 1.02), ("doors,", 1.02, 1.38), ("Forty", 2.7, 2.95), ("no's.", 2.95, 3.24), ("I", 3.68, 3.72), ("don't", 3.72, 3.88), ("think", 3.88, 3.98),
         ("I'm", 3.98, 4.16), ("built", 4.16, 4.32), ("for", 4.32, 4.52), ("this.", 4.52, 4.76), ("My", 5.38, 5.46), ("first", 5.46, 5.68), ("day", 5.68, 5.9),
         ("I", 5.9, 6.02), ("got", 6.02, 6.14), ("forty-three.", 6.14, 6.58), ("You", 7.04, 7.16), ("beat", 7.16, 7.38), ("me.", 7.38, 7.58), ("So", 8.27, 8.5),
         ("what", 9.05, 9.36), ("do", 9.36, 9.44), ("I", 9.44, 9.54), ("do?", 9.54, 9.74), ("Same", 11.1, 11.3), ("thing", 11.3, 11.5), ("tomorrow.", 11.5, 11.92),
         ("The", 12.9, 12.98), ("yeses", 12.98, 13.32), ("are", 13.32, 13.44), ("behind", 13.44, 13.7), ("the", 13.7, 13.9), ("no's.", 13.9, 14.18)]
tl = []; t = 0.0
with open(f'{out}/list.txt', 'w') as L:
    for i, (a, b) in enumerate(SEGS):
        d = F(b - a); last = i == len(SEGS) - 1; f = f'{out}/s{i}.mkv'
        vf = 'scale=1080:1920:flags=lanczos,fps=30,setsar=1' + (f',tpad=stop_mode=clone:stop_duration={HOLD}' if last else '')
        af = f'afade=t=in:d=0.012,afade=t=out:st={d - 0.015:.3f}:d=0.015' if not last else f'atrim=0:{min(d + 0.55, 15.0 - a):.3f},afade=t=out:st={d:.3f}:d=0.5,apad'
        D = d + (HOLD if last else 0)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-i', 'scene.mp4', '-t', f'{D:.4f}' if not last else f'{15.04 - a:.4f}', '-vf', vf, '-af', af,
                        '-c:v', 'libx264', '-crf', '15', '-pix_fmt', 'yuv420p', '-c:a', 'pcm_s16le', '-ar', '48000', '-ac', '1', '-t', f'{D:.4f}', f], check=True)
        tl.append(dict(clip='scene', part=i, a=a, b=a + d, out0=round(t, 4), dur=d)); L.write(f"file 's{i}.mkv'\n"); t += D
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', f'{out}/list.txt', '-c', 'copy', f'{out}/main.mkv'], check=True)
json.dump(tl, open(f'{out}/timeline.json', 'w'), indent=1); json.dump([], open(f'{out}/inserts.json', 'w'))
def to_out(s):
    for x in tl:
        if x['a'] - 0.06 <= s < x['b']: return x['out0'] + max(0, s - x['a'])
words = [dict(w=w, s=round(to_out(s), 3), e=round(to_out(s) + e - s, 3)) for w, s, e in WORDS]
# captions: TikTok Sans Black, 2 words, green active word (same look as the talking-head edits)
def ts(x): return f"{int(x // 3600)}:{int(x % 3600 // 60):02d}:{x % 60:05.2f}"
hdr = open('../raw3/captions3.ass').read().split('[Events]')[0].replace('Nunito Sans Black,104', 'TikTok Sans Black,96')
chunks, cur = [], []
for w in words:
    if cur and (len(cur) == 2 or w['s'] - cur[-1]['e'] > 0.35 or cur[-1]['w'].endswith(('.', ',', '?'))): chunks.append(cur); cur = []
    cur.append(w)
chunks.append(cur); ev = []
for ci, ch in enumerate(chunks):
    nxt = chunks[ci + 1][0]['s'] if ci + 1 < len(chunks) else ch[-1]['e'] + 0.3
    for j, w in enumerate(ch):
        s0 = w['s']; e0 = ch[j + 1]['s'] if j + 1 < len(ch) else min(nxt, ch[-1]['e'] + 0.35)
        txt = " ".join(("{\\c&H59C734&}" + x['w'].upper() + "{\\c&HFFFFFF&}") if k == j else x['w'].upper() for k, x in enumerate(ch))
        ev.append(f"Dialogue: 0,{ts(s0)},{ts(max(e0, s0 + 0.08))},Caption,,0,0,0,,{{\\an5\\pos(540,1640)}}{txt}")
open(f'{out}/captions.ass', 'w').write(hdr + "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n" + "\n".join(ev) + "\n")
hook_end = F([w for w in words if w['w'] == 'this.'][0]['e'] + 0.4); cta0 = F(t - HOLD)
# subtle pop as the headline lands
w_ = wave.open('../raw3/sfx/pop.wav'); pop = np.frombuffer(w_.readframes(w_.getnframes()), np.int16).astype(float) / 32768 * .11
trk = np.zeros(int((t + 1) * 48000)); trk[:len(pop)] += pop; i = int(cta0 * 48000); trk[i:i + len(pop)] += pop * .8
with wave.open(f'{out}/sfx.wav', 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(48000); w.writeframes((np.clip(trk, -1, 1) * 32767).astype(np.int16).tobytes())
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv', '-af', 'highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000', f'{out}/voice.wav'], check=True)
for kind in ['captions', 'clean']:
    cap = f',ass={out}/captions.ass:fontsdir=/root/.fonts' if kind == 'captions' else ''
    fc = (f"[0:v][1:v]overlay=0:0:enable='lt(t,{hook_end:.3f})'[a];[a][2:v]overlay=0:0:enable='gte(t,{cta0:.3f})'{cap}[v];"
          f"[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[vo];[3:a]aresample=48000[fx];[vo][fx]amix=inputs=2:normalize=0:duration=longest,atrim=0:{t:.4f},alimiter=limit=0.95[au]")
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{out}/main.mkv', '-i', 'hook.png', '-i', '../raw3/ov/cta.png', '-i', f'{out}/sfx.wav', '-filter_complex', fc,
                    '-map', '[v]', '-map', '[au]', '-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p', '-r', '30', '-c:a', 'aac', '-b:a', '192k',
                    '-movflags', '+faststart', f'd2d_day_one_{kind}.mp4'], check=True)
print('done', round(t, 2), 's; hook until', hook_end, 'cta from', cta0)
