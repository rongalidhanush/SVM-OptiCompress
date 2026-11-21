function [labels,detail]=label_blocks(blocks,lambda,level,scale)
% Cost in squared intensity units plus lambda times bits per spatial pixel.
if nargin<2, lambda=32; end
if nargin<3, level=1; end
if nargin<4, scale=1; end
validateattributes(lambda,{'numeric'},{'real','scalar','finite','nonnegative'});
T=dct_basis(); [~,n,c]=size(blocks);
F=reshape(T*reshape(blocks-128,64,[]),64,n,c);
mse=zeros(n,3); bytes=zeros(n,3);
for k=1:3
    q=quant_steps(k,level,scale);
    z=round(F./q);
    % Orthonormal DCT preserves the pre-rounding squared pixel error.
    mse(:,k)=reshape(mean(mean((F-z.*q).^2,1),3),[],1);
    bytes(:,k)=1+c+3*reshape(sum(sum(z~=0,1),3),[],1);
end
cost=mse+lambda*(8*bytes/64);
[~,labels]=min(cost,[],2);
detail=struct('mse',mse,'bytes',bytes,'psnr',10*log10(255^2./mse),'cost',cost);
end
