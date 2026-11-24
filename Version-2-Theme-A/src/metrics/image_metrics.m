function m=image_metrics(a,b,path,enc,dec)
assert(isequal(size(a),size(b)),'Image dimensions differ.');
f=dir(path); pixels=size(a,1)*size(a,2);
mse=mean((double(a(:))-double(b(:))).^2);
scores=zeros(1,size(a,3));
for k=1:numel(scores)
    if exist('ssim','file')==2 && min(size(a,[1 2]))>=11
        scores(k)=ssim(b(:,:,k),a(:,:,k),'DynamicRange',255);
    else
        scores(k)=local_ssim(double(a(:,:,k)),double(b(:,:,k)));
    end
end
m=table(mse,10*log10(255^2/mse),mean(scores),8*f.bytes/pixels,numel(a)/f.bytes, ...
    f.bytes,enc,dec,'VariableNames',{'MSE','PSNR','SSIM','BPP','Ratio','Bytes','Encode_s','Decode_s'});
end
function score=local_ssim(x,y)
% Gaussian-window SSIM with symmetric edge extension (supports tiny images).
t=-5:5; g=exp(-t.^2/(2*1.5^2)); g=g/sum(g); w=g'*g;
rows=mirror(size(x,1)); cols=mirror(size(x,2));
x=x(rows,cols); y=y(rows,cols);
mx=conv2(x,w,'valid'); my=conv2(y,w,'valid');
vx=max(0,conv2(x.^2,w,'valid')-mx.^2); vy=max(0,conv2(y.^2,w,'valid')-my.^2);
xy=conv2(x.*y,w,'valid')-mx.*my;
s=((2*mx.*my+6.5025).*(2*xy+58.5225))./((mx.^2+my.^2+6.5025).*(vx+vy+58.5225));
score=mean(s(:));
end
function ids=mirror(n)
p=mod(-5:n+4,2*n); ids=1+min(p,2*n-1-p);
end
