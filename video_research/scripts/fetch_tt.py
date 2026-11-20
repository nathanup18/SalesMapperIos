import json, sys, os, urllib.request, concurrent.futures as cf
T=os.environ['APIFY_TOKEN']; S=sys.argv[1]
def get(u): return urllib.request.urlopen(u, timeout=120).read()
rows=[]
for setname, ds in [('niche','CD0HdhLl87KBpHoqd'),('general','hIChM9xdXilNlKfPe')]:
    items=json.loads(get(f'https://api.apify.com/v2/datasets/{ds}/items?token={T}&clean=1'))
    json.dump(items, open(f'{S}/runs/tt_{setname}.json','w'))
    for x in items: rows.append((setname,x))
os.makedirs(f'{S}/videos', exist_ok=True)
def dl(r):
    setname,x=r; mu=x.get('mediaUrls') or []
    if not mu: return None
    p=f"{S}/videos/tt_{x['id']}.mp4"
    if os.path.exists(p) and os.path.getsize(p)>1000: return p
    try:
        sep='&' if '?' in mu[0] else '?'
        open(p,'wb').write(get(mu[0]+f'{sep}token={T}')); return p
    except Exception as e: print('fail',x['id'],e); return None
with cf.ThreadPoolExecutor(8) as ex: res=list(ex.map(dl,rows))
print(sum(1 for r in res if r), 'downloaded of', len(rows))
