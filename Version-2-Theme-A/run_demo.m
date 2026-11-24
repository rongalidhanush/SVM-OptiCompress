function run_demo()
root=setup(); model=get_model(root); out=fullfile(root,'results');
files=dir(fullfile(root,'datasets','testing','*.png')); allRates=table(); matches=table();
for i=1:numel(files)
    img=read_image(fullfile(files(i).folder,files(i).name)); [~,name]=fileparts(files(i).name);
    path=fullfile(out,'compressed',[name '.soc']);
    [~,enc]=compress_image(img,path,'Selective SVM',1,1,model); [recon,~,dec]=decompress_image(path);
    imwrite(recon,fullfile(out,'reconstructed',[name '.png'])); disp(image_metrics(img,recon,path,enc,dec));
    fig=figure('Visible','off','Position',[100 100 1050 740]); guard=onCleanup(@() close(fig));
    tiledlayout(fig,2,2); ax=gobjects(1,4);
    for j=1:4, ax(j)=nexttile; end
    [rates,pairs]=compare_methods(img,model,ax); rates.Image(:)=string(name); pairs.Image(:)=string(name);
    allRates=[allRates;rates]; matches=[matches;pairs]; %#ok<AGROW>
    exportgraphics(fig,fullfile(out,'graphs',[name '.png'])); clear guard
end
writetable(allRates,fullfile(out,'metrics','rate_curves.csv'));
writetable(matches,fullfile(out,'metrics','nearest_rates.csv'));
fig=figure('Visible','off','Position',[100 100 1100 460]); guard=onCleanup(@() close(fig));
tiledlayout(fig,1,2); r=svm_qp_demo(model,nexttile);
[~,explained]=pca_demo(img,nexttile); exportgraphics(fig,fullfile(out,'graphs','mathematics.png'));
save(fullfile(out,'metrics','mathematics.mat'),'r','explained');
fprintf('QP objective %.4f, %d support vectors, KKT stationarity %.3g\n',r.objective,r.supportCount,r.stationarity);
end
