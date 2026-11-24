function [img,map,seconds]=decompress_image(path)
timer=tic; fid=fopen(path,'rb','ieee-le'); assert(fid>=0,'Cannot open compressed file.');
closer=onCleanup(@() fclose(fid));
assert(isequal(char(fread(fid,4,'*char')'),'SOC1'),'Invalid SOC1 signature.');
hw=fread(fid,2,'uint32')'; c=fread(fid,1,'uint8'); settings=fread(fid,2,'double');
assert(numel(hw)==2 && all(hw>0) && isscalar(c) && ismember(c,[1 3]) && numel(settings)==2,'Invalid header.');
grid=ceil(hw/8); n=prod(grid);
start=ftell(fid); fseek(fid,0,'eof'); remaining=ftell(fid)-start; fseek(fid,start,'bof');
assert(n*(1+c)<=remaining && remaining<=n*(1+193*c),'Invalid payload size.');
classes=fread(fid,n,'uint8'); assert(all(ismember(classes,1:3)),'Invalid class.');
q=quant_steps(classes,settings(1),settings(2));
data=fread(fid,Inf,'*uint8'); pos=1; order=zig_order();
% Reconstruct one block column strip at a time in the final byte image.
img=zeros(8*grid(1),8*grid(2),c,'uint8'); T=dct_basis();
for plane=1:c
    for j=1:grid(2)
        strip=zeros(64,grid(1));
        for i=1:grid(1)
            assert(pos<=numel(data),'Truncated block.');
            m=double(data(pos)); pos=pos+1;
            assert(m<=64 && pos+3*m-1<=numel(data),'Invalid coefficient count.');
            idx=cumsum(1+double(data(pos:3:pos+3*m-1)));
            assert(isempty(idx)||idx(end)<=64,'Invalid zero run.');
            value=double(data(pos+1:3:pos+3*m-1))+256*double(data(pos+2:3:pos+3*m-1));
            value(value>=32768)=value(value>=32768)-65536;
            strip(order(idx),i)=value; pos=pos+3*m;
        end
        ids=(j-1)*grid(1)+(1:grid(1));
        a=reshape(T'*(strip.*q(:,ids))+128,8,8,[]);
        img(:,8*j-7:8*j,plane)=uint8(reshape(permute(a,[1 3 2]),[],8));
    end
end
assert(pos==numel(data)+1,'Trailing bytes in stream.');
img=img(1:hw(1),1:hw(2),:); map=reshape(classes,grid); seconds=toc(timer);
end
