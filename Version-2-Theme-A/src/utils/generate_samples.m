function generate_samples(root)
% Analytic scenes, generated independently for each split.
previous = rng; restore = onCleanup(@() rng(previous));
for i = 1:12
    if i<=8, split='training'; elseif i<=11, split='testing'; else, split='sample_images'; end
    path=fullfile(root,'datasets',split,sprintf('scene_%02d.png',i));
    if isfile(path), continue; end
    rng(1900+i);
    h=85+3*i; w=109+2*i;
    [x,y]=meshgrid((0:w-1)/w,(0:h-1)/h);
    base=80+75*x+30*cos(2*pi*y+i);
    pattern=sin((4+i)*pi*x+3*y).*cos(14*pi*y+i);
    field=base+45*pattern.*(x>0.22)+28*randn(h,w).*(x>0.62);
    field((x-.32).^2+(y-.47).^2<.035)=128;
    field(y>.76 & x<.6)=70+90*mod(floor(24*x(y>.76 & x<.6)),2);
    img=uint8(field);
    if mod(i,2)==0
        img=cat(3,img,uint8(field+25*sin(8*x+i)),uint8(field+28*cos(7*y)));
    end
    imwrite(img,path);
end
end
