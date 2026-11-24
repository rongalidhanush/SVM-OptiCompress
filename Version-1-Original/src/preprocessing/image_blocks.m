function [blocks,grid]=image_blocks(img)
% Columns contain vectorized 8-by-8 blocks, ordered down each block column.
[h,w,c]=size(img);
grid=ceil([h w]/8);
img=img(min(1:8*grid(1),h),min(1:8*grid(2),w),:);
a=reshape(double(img),8,grid(1),8,grid(2),c);
blocks=reshape(permute(a,[1 3 2 4 5]),64,[],c);
end

