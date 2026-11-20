import json, os, sys, urllib.request, concurrent.futures as cf
T=os.environ['APIFY_TOKEN']
NICHE_Q={"door to door sales","d2d sales","door knocking","solar sales tips","pest control sales"}
up=json.load(open('runs/tt_topup.json'))
json.dump(up,open('runs/tt_topup.json','w'))
def dl(x):
    p=f"videos/tt_{x['id']}.mp4"
    if os.path.exists(p) or not x.get('mediaUrls'): return
    u=x['mediaUrls'][0]; open(p,'wb').write(urllib.request.urlopen(u+('&' if '?' in u else '?')+'token='+T,timeout=120).read())

rows={}
def add_tt(x,setname,src):
    if x.get('createTimeISO','')<'2026-05-20' or x.get('isSlideshow') or x['id'] in rows: return
    rows[x['id']]=dict(video_id='tt_'+x['id'],set=setname,platform='tiktok',source=src,url=x.get('webVideoUrl'),
        author=x['authorMeta'].get('name'),followers=x['authorMeta'].get('fans'),views=x.get('playCount'),
        likes=x.get('diggCount'),comments=x.get('commentCount'),shares=x.get('shareCount'),posted=x['createTimeISO'][:10],
        meta_duration=x.get('videoMeta',{}).get('duration'),caption_text=(x.get('text') or '')[:200])
for s in ['niche','general']:
    for x in json.load(open(f'runs/tt_{s}.json')): add_tt(x,s,'#'+(x.get('input') or ''))
for x in up: add_tt(x,'niche' if x.get('searchQuery') in NICHE_Q else 'general','search:'+str(x.get('searchQuery')))
fol={p.get('username'):p.get('followersCount') for p in json.load(open('runs/ig_profiles.json'))}
tags={x['shortCode']:x.get('hashtags') for x in json.load(open('runs/ig_tag.json'))}
for x in json.load(open('runs/ig_reels.json')):
    rows['ig'+x['shortCode']]=dict(video_id='ig_'+x['shortCode'],set='niche',platform='instagram',source='#hashtag',url=x['url'],
        author=x['ownerUsername'],followers=fol.get(x['ownerUsername']),views=x.get('videoPlayCount'),likes=x.get('likesCount'),
        comments=x.get('commentsCount'),shares=None,posted=x['timestamp'][:10],meta_duration=x.get('videoDuration'),caption_text=(x.get('caption') or '')[:200])
rows=[r for r in rows.values() if os.path.exists('videos/%s.mp4'%r['video_id'])]
json.dump(rows,open('manifest.json','w'),indent=0)
from collections import Counter; print(len(rows), Counter((r['set'],r['platform']) for r in rows), 'missing followers', sum(1 for r in rows if not r['followers']))
