import sys, os, glob
os.environ['U2NET_HOME'] = sys.argv[3]
from rembg import remove, new_session
from PIL import Image
k, n = int(sys.argv[1]), int(sys.argv[2]); s = new_session('u2net_human_seg')
want = set(range(int(6.0 * 30), int(8.6 * 30))) | set(range(int(13.1 * 30), int(17.2 * 30)))
for f in sorted(glob.glob('sdrf/*.png'))[k::n]:
    i = int(os.path.basename(f)[:5]); o = 'masks/' + os.path.basename(f)
    if i not in want or os.path.exists(o): continue
    remove(Image.open(f), session=s, only_mask=True).save(o)
