function X=block_features(blocks)
if size(blocks,3)==3
    lum=.298936*blocks(:,:,1)+.587043*blocks(:,:,2)+.114021*blocks(:,:,3);
else
    lum=blocks;
end
a=reshape(lum,8,8,[]);
dx=diff(a,1,2); dy=diff(a,1,1);
g=[reshape(dx,56,[]);reshape(dy,56,[])];
bins=min(15,floor(lum/16)); entropy=zeros(1,size(lum,2));
for k=0:15
    p=mean(bins==k,1); entropy=entropy-p.*log2(max(p,eps));
end
T=dct_basis(); freq=T*lum;
[u,v]=ndgrid(0:7); high=u+v>=5;
X=[mean(lum,1);std(lum,0,1);var(lum,0,1);mean(abs(g)>18,1); ...
   mean(g.^2,1);entropy;sum(freq(high(:),:).^2,1)/64]';
end
