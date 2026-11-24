function draw_six_images(layout,img,model,level,scale)
showPanel(layout,img,'Original');
file=[tempname '.soc']; cleanup=onCleanup(@() discard(file));
for method=["Fixed","Rules","SVM","Selective SVM","Exhaustive"]
    [~,enc]=compress_image(img,file,method,level,scale,model);
    [out,~,dec]=decompress_image(file);
    m=image_metrics(img,out,file,enc,dec);
    showPanel(layout,out,{char(method),sprintf('%d bytes | %.2f dB | SSIM %.3f',m.Bytes,m.PSNR,m.SSIM)});
end
end

function showPanel(layout,img,label)
ax=nexttile(layout);
if size(img,3)==1
    imagesc(ax,img,[0 255]); colormap(ax,gray(256));
else
    image(ax,img);
end
axis(ax,'image','off'); title(ax,label);
end

function discard(file)
if isfile(file), delete(file); end
end

