import sys, os, glob
os.environ['U2NET_HOME'] = os.path.abspath('models')
from rembg import remove, new_session
from PIL import Image
k, n = int(sys.argv[1]), int(sys.argv[2]); s = new_session('u2net_human_seg')
fs = sorted(glob.glob('sdrf_l4/*.png'))[k::n]
for f in fs:
    o = 'masks_l4/' + os.path.basename(f)
    if os.path.exists(o): continue
    remove(Image.open(f), session=s, only_mask=True).save(o)
