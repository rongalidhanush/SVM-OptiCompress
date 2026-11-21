function [fig,path]=show_six_images(input)
% Display the source and five decoded images together and export the figure.
root=setup();
if nargin==0
    input=fullfile(root,'datasets','sample_images','scene_12.png');
end
img=read_image(input); model=get_model(root);
fig=figure('Visible','off','WindowStyle','normal','Name','Original and five compression methods','NumberTitle','off', ...
    'Color','white','Position',[100 100 1080 650]);
layout=tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
draw_six_images(layout,img,model,1,1);
path=fullfile(root,'results','graphs','six_image_comparison.png');
exportgraphics(fig,path,'Resolution',180);
if ~batchStartupOptionUsed, fig.Visible='on'; end
fprintf('Saved %s\n',path);
end


