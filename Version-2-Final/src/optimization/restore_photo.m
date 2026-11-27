function output=restore_photo(img,sigma,iterations)
% Richardson-Lucy deblurring with isotropic Gaussian blur in source pixels.
if nargin<3, iterations=16; end
validateattributes(iterations,{'numeric'},{'scalar','integer','>=',1,'<=',40});
validateattributes(sigma,{'numeric'},{'scalar','real','finite','>=',0.4,'<=',8});
pixels=double(read_image(img)); [h,w,channels]=size(pixels);
pad=ceil(5*sigma);
% Reflect both borders to reduce periodic wraparound artifacts.
fold=@(n) mod((-pad:n+pad-1),2*n);
r=fold(h); c=fold(w);
padded=pixels(1+min(r,2*h-1-r),1+min(c,2*w-1-c),:);
% Estimate brightness only so repeated updates do not amplify color noise.
brightness=padded(:,:,1);
if channels==3
    brightness=.298936*brightness+.587043*padded(:,:,2)+.114021*padded(:,:,3);
end
radius=ceil(4*sigma);
kernel=exp(-((-radius:radius).^2)/(2*sigma^2));
kernel=kernel/sum(kernel);
blur=@(x) conv2(kernel(:),kernel,x,'same');
% Normalize the adjoint update at the padded image boundary.
sensitivity=max(blur(ones(size(brightness))),eps);
estimate=max(brightness,.01);
for step=1:iterations
    ratio=brightness./max(blur(estimate),.01);
    estimate=estimate.*blur(ratio)./sensitivity;
end
change=estimate-brightness;
output=uint8(pixels+change(pad+(1:h),pad+(1:w)));
end
