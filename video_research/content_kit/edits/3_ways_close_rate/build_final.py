"""Composite main.mp4 + inserts + labels + captions3.ass -> final. Usage: python build_final.py out.mp4"""
import json, subprocess, sys
words=json.load(open('out_words.json')); P=json.load(open('parts.json'))
def at(word,part,which='s',nth=0): return [w for w in words if w['w'].lower().strip('.,')==word and w['part']==part][nth][which]
M='../mockup/out/'
ins=[(M+'ins_questions.mp4',at('asking','tip1')-0.05,at('pitch','tip1','e')+0.12),
     (M+'ins_reknock.mp4',P['tip2'][0],at('area','tip2','e')+0.10),                       # starts on the cut, no face flash
     ('../broll_v/handshake-outdoor_pixabay-318026.mp4',at('partnered','tip3')-0.05,at('businesses','tip3','e')+0.10),
     (M+'ins_referrals.mp4',at('where','tip3')-0.05,at('when','tip3')-0.07),             # full 2.25 s loop
     (M+'ins_giftcard.mp4',at('hand','tip3')-0.05,at('businesses','tip3','e',1)+0.10),
     (M+'ins_reciprocity.mp4',at('giving','tip3')-0.05,at('back','tip3','e')+0.10)]
for f,a,b in ins: print(f.split('/')[-1], round(a,3), round(b,3), round(b-a,2))
args=['ffmpeg','-v','error','-y','-i','main.mp4']+sum([['-i',f] for f,a,b in ins],[])+sum([['-i',f'ov/{k}.png'] for k in ['hook','tip1','tip2','tip3','cta']],[])
fc=['[0:v]setsar=1[b0]'];last='b0'
for i,(f,a,b) in enumerate(ins,1):
    d=b-a; fc.append(f'[{i}:v]fps=30,scale=1080:1920,setsar=1,trim=0:{d:.3f},tpad=stop_mode=clone:stop_duration=2,trim=0:{d:.3f},setpts=PTS-STARTPTS+{a:.3f}/TB[c{i}]')
    fc.append(f"[{last}][c{i}]overlay=eof_action=pass:enable='between(t,{a:.3f},{b:.3f})'[b{i}]");last=f'b{i}'
for j,k in enumerate(['hook','tip1','tip2','tip3','cta']):
    a,b=P[k]; fc.append(f"[{last}][{len(ins)+1+j}:v]overlay=0:0:enable='between(t,{a:.3f},{b:.3f})'[t{j}]");last=f't{j}'
fc+=[f'[{last}]ass=captions3.ass:fontsdir=/root/.fonts[v]','[0:a]highpass=f=70,loudnorm=I=-14:TP=-1.5:LRA=11[a]']
subprocess.run(args+['-filter_complex',';'.join(fc),'-map','[v]','-map','[a]','-c:v','libx264','-preset','slow','-crf','17','-pix_fmt','yuv420p','-r','30','-c:a','aac','-b:a','192k','-ar','48000','-movflags','+faststart',sys.argv[1]],check=True)
