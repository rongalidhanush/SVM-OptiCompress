function [map,seconds,review]=compress_image(input,path,method,level,scale,model)
if nargin<6, model=[]; end
timer=tic; img=read_image(input); [b,grid]=image_blocks(img);
n=size(b,2); c=size(b,3);
review=struct('checked',0,'changed',0);
switch string(method)
    case "Fixed"
        classes=2*ones(n,1);
    case "Rules"
        X=block_features(b); classes=2*ones(n,1);
        classes(X(:,2)<12)=1; classes(X(:,4)>.26)=3;
    case "SVM"
        assert(~isempty(model),'Train or load the SVM first.');
        classes=predict(model.classifier,block_features(b));
    case "Selective SVM"
        assert(~isempty(model),'Train or load the SVM first.');
        [classes,indices,review.changed]=selective_quantizers(b,model,.25,level,scale);
        review.checked=numel(indices);
    case "Exhaustive"
        classes=label_blocks(b,32,level,scale);
        review.checked=n;
    otherwise
        error('Unknown compression method.');
end
q=quant_steps(classes,level,scale);
T=dct_basis(); z=round(reshape(T*reshape(b-128,64,[]),64,n,c)./q);
order=zig_order(); z=z(order,:,:);
% Each plane/block record begins with a nonzero count. Each following
% triple gives preceding zero count and signed little-endian coefficient.
payload=zeros(n*c+3*nnz(z),1,'uint8'); pos=1;
for i=1:n*c
    col=z(:,i); idx=find(col); m=numel(idx);
    payload(pos)=m; pos=pos+1;
    values=mod(col(idx),65536);
    payload(pos:3:pos+3*m-1)=diff([0;idx])-1;
    payload(pos+1:3:pos+3*m-1)=mod(values,256);
    payload(pos+2:3:pos+3*m-1)=floor(values/256);
    pos=pos+3*m;
end
folder=fileparts(path); if isempty(folder), folder=pwd; end
tmp=tempname(folder); cleanup=onCleanup(@() discard(tmp));
fid=fopen(tmp,'wb','ieee-le'); assert(fid>=0,'Cannot open output file.');
closer=onCleanup(@() fclose(fid));
fwrite(fid,'SOC1','char'); fwrite(fid,[size(img,1),size(img,2)],'uint32');
fwrite(fid,c,'uint8'); fwrite(fid,[level scale],'double');
fwrite(fid,classes,'uint8'); fwrite(fid,payload,'uint8');
[msg,err]=ferror(fid); assert(err==0,'%s',msg);
clear closer
[ok,msg]=movefile(tmp,path,'f'); assert(ok,'%s',msg);
map=reshape(classes,grid); seconds=toc(timer);
end
function discard(tmp)
if isfile(tmp), delete(tmp); end
end
