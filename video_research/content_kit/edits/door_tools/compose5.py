"""4 tools video: full-screen visuals (stock/animated/app, SDR -> HLG via LUT) + Nathan in a moving corner box (original HDR) + labels/captions (HLG)."""
import json, subprocess, os, urllib.parse, numpy as np, cv2
FPS = 30; F = lambda x: round(x * FPS) / FPS
B = '../broll/'; tl = json.load(open('seg/timeline.json')); sec = json.load(open('seg/sec.json')); C = json.load(open('cues.json')); W = json.load(open('words.json'))
T = tl[-1]['out0'] + tl[-1]['dur']
VAR = 'ig'                                            # Instagram only from v4 (no TikTok version)                     # ig | tt (TikTok: everything shifted clear of the right rail / top tabs)
def run(a): subprocess.run(['ffmpeg', '-v', 'error', '-y'] + a, check=True)
S = {'hook': (0, sec['S1'][0]), 's1': (sec['S1'][0], sec['I2'][0]), 's2': (sec['I2'][0], sec['I3'][0]), 's3': (sec['I3'][0], sec['I4'][0]), 's4': (sec['I4'][0], sec['C4'][0]), 'cta': (sec['C4'][0], T)}
HL = 'hl_ig'
# ---- 3. composite in HDR: bg (SDR->HLG LUT), Nathan cut out (original HDR pixels + segmentation mask), soft shadow, text
SC, PW, PH = 0.55, 594, 1056; Y = 1920 - PH + 60                       # head and shoulders rising from the bottom edge
XR, XL = 536, -50
xs = [(S['hook'][1], XR), (S['s1'][1], XL), (S['s2'][1], XR), (S['s3'][1], XL), (S['s4'][1], XR)]
def xexpr(dx=0):
    e = str(XL + dx)
    for t, x in reversed(xs): e = f"if(lt(t\\,{t:.3f})\\,{x + dx}\\,{e})"
    return e
X = 'colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:range=limited:log-level=error'
HDR = ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc', '-color_range', 'tv']
fc = (f"[0:v]scale=in_color_matrix=bt709:in_range=tv,format=rgb48le,split[s1][s2];[s1]lut3d=sdr2hlg.cube[n];[s2]trim=end={F(S['hook'][1]):.4f},lut3d=sdr2hlg_bright.cube[h];[n][h]overlay=eof_action=pass,scale=out_color_matrix=bt2020:out_range=tv,format=yuv420p10le[bg];"
      "[2:v]format=gray,scale=1080:1920:flags=bicubic,tmix=frames=3,lut=y='clip((val-30)*1.25\\,0\\,255)',gblur=sigma=1.2,split=2[m1][m2];"
      f"[1:v]format=yuva420p10le[nv];[nv][m1]alphamerge,scale={PW}:{PH}:flags=lanczos[person];"
      f"[m2]scale={PW}:{PH},gblur=sigma=22,lut=y='val*0.5'[sm];color=c=black:s={PW}x{PH}:r=30,format=yuva420p[blk];[blk][sm]alphamerge[shadow];"
      f"[bg][shadow]overlay=x='{xexpr(14)}':y={Y + 18}:eval=frame:format=yuv420p10[b0];"
      f"[b0][person]overlay=x='{xexpr()}':y={Y}:eval=frame:format=yuv420p10[b1];"
      "[3:v]fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt2020,format=yuva444p10le[tx];[b1][tx]overlay=format=yuv420p10:eof_action=pass[v]")
outf = 'tools_v5_instagram.mp4'
run(['-i', 'bg/bg_sdr.mp4', '-i', 'seg/main.mov', '-framerate', '30', '-i', 'masks/%05d.png', '-f', 'concat', '-safe', '0', '-i', f'{HL}/list.txt', '-filter_complex', fc, '-map', '[v]', '-map', '1:a',
     '-c:v', 'libx265', '-preset', 'medium', '-crf', '15', '-pix_fmt', 'yuv420p10le', '-x265-params', X] + HDR +
    ['-tag:v', 'hvc1', '-c:a', 'aac', '-b:a', '256k', '-t', f'{T:.3f}', '-movflags', '+faststart', outf])
print('done', outf, round(T, 2), 's', 'ok')
