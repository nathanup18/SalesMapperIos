import sys, os, glob
os.environ['U2NET_HOME'] = sys.argv[3]
from rembg import remove, new_session
from PIL import Image
k, n = int(sys.argv[1]), int(sys.argv[2]); s = new_session('u2net_human_seg')
for f in sorted(glob.glob('sdrf/*.png'))[k::n]:
    o = 'masks/' + os.path.basename(f)
    if not os.path.exists(o): remove(Image.open(f), session=s, only_mask=True).save(o)
