import cv2, numpy as np, json
T=['24.0','24.5','25.0','25.5','26.0','26.5','27.0']
ims={t:cv2.imread(f'zm/{t}.png') for t in T}; ims['close']=cv2.imread('close.png')
seq=T+['close']
sift=cv2.SIFT_create(6000)
def match(a,b):  # transform mapping a coords -> b coords
    ga,gb=[cv2.cvtColor(x,cv2.COLOR_BGR2GRAY) for x in (a,b)]
    ka,da=sift.detectAndCompute(ga,None); kb,db=sift.detectAndCompute(gb,None)
    m=cv2.BFMatcher().knnMatch(da,db,k=2); g=[x for x,y in m if x.distance<0.75*y.distance]
    pa=np.float32([ka[x.queryIdx].pt for x in g]); pb=np.float32([kb[x.trainIdx].pt for x in g])
    M,inl=cv2.estimateAffinePartial2D(pa,pb,ransacReprojThreshold=4)
    return M,int(inl.sum()),len(g)
# map every still into close coords: chain backwards
H={'close':np.eye(3)}
for i in range(len(seq)-2,-1,-1):
    a,b=seq[i],seq[i+1]; M,n,g=match(ims[a],ims[b]); s=np.hypot(*M[0,:2])
    print(a,'->',b,'inliers',n,'/',g,'scale',round(s,3))
    H[a]=H[b]@np.vstack([M,[0,0,1]])
json.dump({k:v.tolist() for k,v in H.items()},open('zm/H.json','w'))
