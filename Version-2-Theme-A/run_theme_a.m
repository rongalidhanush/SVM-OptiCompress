function out=run_theme_a(imageInput,level,scale,kClusters,lambda)
% Analyze one uploaded photo end-to-end. If called without an image, prompt
% the user to choose one. All fitted data and outputs come from that image.
root=setup();
if nargin<1 || isempty(imageInput)
    [name,folder]=uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff','Image files'}, ...
        'Choose the image for a complete Theme A analysis');
    if isequal(name,0), out=""; return; end
    imageInput=fullfile(folder,name);
end
if nargin<2 || isempty(level), level=1; end
if nargin<3 || isempty(scale), scale=1; end
if nargin<4 || isempty(kClusters), kClusters=3; end
if nargin<5 || isempty(lambda), lambda=32; end
validateattributes(level,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(scale,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(lambda,{'numeric'},{'scalar','real','finite','nonnegative'});

if ischar(imageInput) || isstring(imageInput)
    sourcePath=char(imageInput); assert(isfile(sourcePath),'Selected image does not exist.');
    img=read_image(sourcePath); [~,stem,ext]=fileparts(sourcePath);
else
    sourcePath=''; img=read_image(imageInput); stem='uploaded_image'; ext='.png';
end
data=image_block_dataset(img,lambda,level,scale);
assert(numel(data.Labels)>=2 && nnz(data.TrainMask)>=2 && any(data.TestMask), ...
    'This photo needs at least two 8-by-8 blocks for the within-image train/test analysis.');

safeStem=regexprep(stem,'[^A-Za-z0-9_-]','_');
runName=sprintf('%s_%s',datestr(now,'yyyymmdd_HHMMSS'),safeStem);
out=fullfile(root,'results','theme_a','user_runs',runName);
if ~isfolder(out), mkdir(out); end

% Preserve this exact input and record that every experiment below is local
% to it. The held-out split is stratified over its block-cost labels.
if ~isempty(sourcePath), copyfile(sourcePath,fullfile(out,['input_image' ext]));
else, imwrite(img,fullfile(out,'input_image.png')); end
metadata=table(string(sourcePath),string(stem),string(datetime('now')), ...
    size(img,2),size(img,1),size(img,3),level,scale,lambda,kClusters, ...
    'VariableNames',{'SourcePath','ImageName','RunTime','Width','Height','Channels','CompressionLevel','CompressionScale','RatePenalty','RequestedClusters'});
writetable(metadata,fullfile(out,'run_metadata.csv'));

% Save features and labels for every 8-by-8 block in this photo.
featureNames={'Mean','Std','Variance','EdgeDensity','GradientEnergy','Entropy','FrequencyEnergy'};
featureTable=array2table(data.Features,'VariableNames',featureNames);
featureTable.BlockIndex=(1:numel(data.Labels))';
featureTable.BlockRow=data.BlockRow; featureTable.BlockColumn=data.BlockCol;
featureTable.QuantizationClass=data.Labels;
featureTable.Split=repmat("train",numel(data.Labels),1); featureTable.Split(data.TestMask)="heldout";
writetable(featureTable,fullfile(out,'block_features.csv'));

% PCA is fitted and evaluated on separate blocks from the uploaded image.
X=data.Features; train=data.TrainMask; test=data.TestMask;
mu=mean(X(train,:),1); sd=std(X(train,:),0,1); sd(sd==0)=1;
Z=(X-mu)./sd; Ztrain=Z(train,:); Ztest=Z(test,:);
[V,eigenvalues]=eig(cov(Ztrain),'vector'); [eigenvalues,order]=sort(max(0,eigenvalues),'descend'); V=V(:,order);
pcaError=zeros(7,1);
for n=1:7
    projected=Ztest*V(:,1:n)*V(:,1:n)';
    pcaError(n)=norm(Ztest-projected,'fro')/max(norm(Ztest,'fro'),eps);
end
pcaTable=table((1:7)',100*cumsum(eigenvalues)/max(sum(eigenvalues),eps),pcaError, ...
    'VariableNames',{'Components','TrainingVariancePercent','HeldOutRelativeError'});
writetable(pcaTable,fullfile(out,'pca.csv'));
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
tiledlayout(fig,1,2,'Padding','compact');
nexttile; plot(1:7,pcaTable.TrainingVariancePercent,'-o'); xlabel('Components'); ylabel('Training variance (%)'); grid on;
nexttile; semilogy(1:7,max(pcaError,1e-15),'-o'); xlabel('Components'); ylabel('Held-out feature error'); grid on;
sgtitle(sprintf('PCA fitted on blocks from %s',stem),'Interpreter','none');
exportgraphics(fig,fullfile(out,'pca_results.png')); clear guard;

% Train the multi-class codec SVM on this photo and reserve held-out blocks.
[model,~]=train_image_model(img,lambda,level,scale);
save(fullfile(out,'image_svm_model.mat'),'model');
binary=image_binary_split(data);
if binary.Available
    [w,bias,gaps]=scratch_svm(binary.TrainX,binary.TrainY);
    lib=fitcsvm(binary.TrainX,binary.TrainY,'KernelFunction','linear', ...
        'BoxConstraint',1,'Standardize',false);
    predScratch=2*((binary.TestX*w+bias)>=0)-1;
    predLibrary=predict(lib,binary.TestX);
    if isempty(binary.TestY), accScratch=NaN; accLibrary=NaN;
    else, accScratch=mean(predScratch==binary.TestY); accLibrary=mean(predLibrary==binary.TestY); end
    objective=@(v,b) .5*(v'*v)+sum(max(0,1-binary.TrainY.*(binary.TrainX*v+b)));
    svmTable=table(["Scratch dual";"MATLAB fitcsvm"], ...
        [objective(w,bias);objective(lib.Beta,lib.Bias)],[accScratch;accLibrary], ...
        repmat("trained from this image",2,1), ...
        'VariableNames',{'Method','PrimalObjective','HeldOutAccuracy','Status'});
    writematrix([binary.TrainX binary.TrainY],fullfile(out,'svm_train.csv'));
    writematrix([binary.TestX binary.TestY],fullfile(out,'svm_test.csv'));
    writematrix(gaps,fullfile(out,'svm_kkt_history.csv'));
    writetable(table(["negative/non-positive class";"positive class"], ...
        [nnz(binary.TestY<0);nnz(binary.TestY>0)],'VariableNames',{'HeldOutClass','Count'}), ...
        fullfile(out,'svm_test_class_counts.csv'));
qp=solve_image_qp(binary);
    save(fullfile(out,'binary_svm_solution.mat'),'w','bias','lib','qp','binary');
else
    svmTable=table("Not applicable",NaN,NaN,string(binary.Reason), ...
        'VariableNames',{'Method','PrimalObjective','HeldOutAccuracy','Status'});
    writematrix(NaN,fullfile(out,'svm_kkt_history.csv'));
    fid=fopen(fullfile(out,'svm_status.txt'),'w'); cleanup=onCleanup(@() fclose(fid));
    fprintf(fid,'%s\n',binary.Reason); clear cleanup;
    qp=solve_image_qp(binary);
end
writetable(svmTable,fullfile(out,'svm.csv'));
qpSummary=rmfield(qp,intersect(fieldnames(qp),{'Weights','Bias','Slacks'}));
writetable(struct2table(qpSummary),fullfile(out,'quadprog.csv'));
write_svm_figures(binary,qp,out,stem);
classValues=(1:3)';
writetable(table(classValues,arrayfun(@(c)nnz(data.Labels==c),classValues), ...
    arrayfun(@(c)nnz(data.Labels(data.TrainMask)==c),classValues), ...
    arrayfun(@(c)nnz(data.Labels(data.TestMask)==c),classValues), ...
    'VariableNames',{'QuantizationClass','AllBlocks','TrainingBlocks','HeldOutBlocks'}), ...
    fullfile(out,'class_distribution.csv'));

% Clustering, transition probabilities and rate-distortion costs for every
% block are computed from the same uploaded image.
[clusterMap,clusterProfile,clusterCost]=cluster_blocks(img,kClusters);
writetable(clusterProfile,fullfile(out,'cluster_profile.csv'));
writematrix(clusterMap,fullfile(out,'cluster_map.csv'));
[transitionProbability,transitionCounts]=spatial_transitions(clusterMap);
writematrix(transitionProbability,fullfile(out,'spatial_transition_probabilities.csv'));
writematrix(transitionCounts,fullfile(out,'spatial_transition_counts.csv'));
write_cluster_figures(clusterMap,transitionProbability,out,stem);
save_block_cost_outputs(data,out,lambda,level,scale);
writetable(table(clusterCost,height(clusterProfile),numel(data.Labels), ...
    'VariableNames',{'WithinClusterSumSquares','NumberOfClusters','NumberOfBlocks'}), ...
    fullfile(out,'clustering_summary.csv'));

% CG works on this photo's red/grayscale channel; large images are sampled
% only for the sparse linear solve to bound memory use.
save_cg_outputs(img,out);
save_codec_outputs(img,model,out,level,scale);

% Rate-distortion curves use five operating points per codec on this photo.
levels=[.55 1 2 4.5 7];
[rateTable,matchedTable]=compare_methods(img,model,[],levels,scale);
writetable(rateTable,fullfile(out,'rate_curves.csv'));
writetable(matchedTable,fullfile(out,'matched_rates.csv'));
write_rate_figure(rateTable,out,stem);
fprintf('Image-specific Theme A results saved to: %s\n',out);
end

function write_svm_figures(binary,qp,out,name)
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
if isfile(fullfile(out,'svm_kkt_history.csv')) && binary.Available
    gaps=readmatrix(fullfile(out,'svm_kkt_history.csv'));
    semilogy(0:numel(gaps)-1,max(gaps,eps)); xlabel('Pair updates'); ylabel('KKT violation'); grid on;
    title(sprintf('Image-derived SVM convergence: %s',name),'Interpreter','none');
else
    axis off; text(.05,.5,'Binary SVM not applicable: this image does not contain two usable classes.','Units','normalized');
end
exportgraphics(fig,fullfile(out,'svm_convergence.png')); clear guard;
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
if binary.Available && isfield(qp,'Weights') && ~isempty(binary.TestY)
    margins=binary.TestY.*(binary.TestX*qp.Weights+qp.Bias);
    margins=sort(margins);
    plot(1:numel(margins),margins,'.','MarkerSize',9); hold on;
    yline(1,'k--','Target margin'); yline(0,'k:'); hold off; grid on;
    xlabel('Held-out blocks (sorted by margin)'); ylabel('Signed functional margin');
    title(sprintf('Image-derived QP margins: %s',name),'Interpreter','none');
else
    axis off; text(.05,.5,'QP margins unavailable because the image split lacks two classes.','Units','normalized');
end
exportgraphics(fig,fullfile(out,'svm_qp_margins.png')); clear guard;
end

function save_block_cost_outputs(data,out,lambda,level,scale)
[chosen,detail]=label_blocks(data.Blocks,lambda,level,scale); n=numel(chosen);
bits=8*detail.bytes/64;
T=table((1:n)',data.BlockRow,data.BlockCol,chosen, ...
    detail.mse(:,1),detail.mse(:,2),detail.mse(:,3), ...
    detail.bytes(:,1),detail.bytes(:,2),detail.bytes(:,3), ...
    bits(:,1),bits(:,2),bits(:,3),detail.cost(:,1),detail.cost(:,2),detail.cost(:,3), ...
    'VariableNames',{'BlockIndex','BlockRow','BlockColumn','ChosenClass', ...
    'StrongMSE','ModerateMSE','LightMSE','StrongBytes','ModerateBytes','LightBytes', ...
    'StrongBPP','ModerateBPP','LightBPP','StrongCost','ModerateCost','LightCost'});
writetable(T,fullfile(out,'block_costs.csv'));
grid=reshape(chosen,data.Grid); writematrix(grid,fullfile(out,'block_cost_map.csv'));
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
imagesc(grid,[1 3]); axis image; colorbar; colormap([.12 .36 .68;.97 .72 .25;.78 .23 .27]);
title('Chosen rate-distortion class per image block'); xlabel('Block column'); ylabel('Block row');
exportgraphics(fig,fullfile(out,'block_cost_map.png')); clear guard;
end

function write_cluster_figures(groups,prob,out,name)
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
tiledlayout(fig,1,2,'Padding','compact');
nexttile; imagesc(groups); axis image; colorbar; title('Block cluster map','Interpreter','none');
xlabel('Block column'); ylabel('Block row');
nexttile; imagesc(prob,[0 1]); axis image; colorbar; xticks(1:size(prob,1)); yticks(1:size(prob,1));
xlabel('Right-neighbor cluster'); ylabel('Current cluster'); title('Spatial transition probability');
sgtitle(sprintf('Clustering and transitions: %s',name),'Interpreter','none');
exportgraphics(fig,fullfile(out,'clustering_transitions.png')); clear guard;
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
imagesc(prob,[0 1]); axis image; colorbar; xticks(1:size(prob,1)); yticks(1:size(prob,1));
xlabel('Right-neighbor cluster'); ylabel('Current cluster'); title('Spatial transition probabilities');
exportgraphics(fig,fullfile(out,'spatial_transitions.png')); clear guard;
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
imagesc(groups); axis image; colorbar; title('Cluster assignment for each 8-by-8 block','Interpreter','none');
exportgraphics(fig,fullfile(out,'cluster_map.png')); clear guard;
end

function save_cg_outputs(img,out)
originalSize=size(img); cgImage=img; factor=min(1,800/max(size(img,1),size(img,2)));
if factor<1
    r=round(linspace(1,size(img,1),max(1,round(size(img,1)*factor))));
    c=round(linspace(1,size(img,2),max(1,round(size(img,2)*factor))));
    cgImage=img(r,c,:); imwrite(cgImage,fullfile(out,'cg_input_resized.png'));
end
f=double(cgImage(:,:,1)); [h,w]=size(f); Dh=diff(speye(h)); Dw=diff(speye(w));
M=speye(h*w)+8*(kron(speye(w),Dh'*Dh)+kron(Dw'*Dw,speye(h)));
rhs=f(:); x=zeros(size(rhs)); residual=rhs; direction=residual; rr=residual'*residual; history=1;
for it=1:500
    Md=M*direction; alpha=rr/(direction'*Md); x=x+alpha*direction; residual=residual-alpha*Md;
    next=residual'*residual; history(end+1)=sqrt(next)/max(norm(rhs),eps); %#ok<AGROW>
    if history(end)<1e-8, break; end
    direction=residual+(next/rr)*direction; rr=next;
end
[reference,flag,~,pcgIterations,pcgHistory]=pcg(M,rhs,1e-8,500);
relres=norm(M*x-rhs)/max(norm(rhs),eps); delta=norm(x-reference)/max(norm(reference),eps);
cgTable=table(h*w,nnz(M),it,pcgIterations,relres,delta, ...
    originalSize(2),originalSize(1),w,h,factor, ...
    'VariableNames',{'Unknowns','Nonzeros','CustomCGIterations','PcgIterations', ...
    'RelativeResidual','DifferenceFromPcg','OriginalWidth','OriginalHeight','CGWidth','CGHeight','CGScale'});
writetable(cgTable,fullfile(out,'cg.csv')); writematrix(history(:),fullfile(out,'cg_residual.csv'));
imwrite(uint8(min(255,max(0,reshape(x,h,w)))),fullfile(out,'cg_smoothed_channel.png'));
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
semilogy(0:numel(history)-1,history,'-',0:numel(pcgHistory)-1,pcgHistory,'--');
xlabel('Iteration'); ylabel('Relative residual'); legend('Custom CG','MATLAB pcg'); grid on;
title('Smoothing solve from uploaded image'); exportgraphics(fig,fullfile(out,'cg_convergence.png')); clear guard;
end

function save_codec_outputs(img,model,out,level,scale)
methods=["Fixed","Rules","SVM","Selective SVM","Exhaustive"];
tmp=[tempname '.soc']; cleaner=onCleanup(@() remove_stream(tmp));
rows=table(); reconstructions=cell(numel(methods)+1,1); labels=strings(numel(methods)+1,1);
reconstructions{1}=img; labels(1)="Original";
for i=1:numel(methods)
    [~,enc,review]=compress_image(img,tmp,methods(i),level,scale,model);
    [rec,~,dec]=decompress_image(tmp); metric=image_metrics(img,rec,tmp,enc,dec);
    row=table(methods(i),level,scale,metric.Bytes,metric.BPP,metric.PSNR,metric.SSIM,metric.MSE,enc,dec, ...
        'VariableNames',{'Method','Level','Scale','Bytes','BPP','PSNR','SSIM','MSE','Encode_s','Decode_s'});
    row.Reviewed=review.checked; row.DecisionsChanged=review.changed; rows=[rows;row]; %#ok<AGROW>
    reconstructions{i+1}=rec; labels(i+1)=methods(i);
    imwrite(rec,fullfile(out,sprintf('reconstruction_%s.png',lower(regexprep(methods(i),'[^A-Za-z0-9]','_')))));
end
writetable(rows,fullfile(out,'compression_metrics.csv'));
fig=figure('Visible','off','Color','w','Position',[100 100 1200 720]); guard=onCleanup(@() close(fig));
tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for i=1:numel(reconstructions)
    ax=nexttile;
    if size(reconstructions{i},3)==1, imagesc(ax,reconstructions{i},[0 255]); colormap(ax,gray(256)); else, image(ax,reconstructions{i}); end
    axis(ax,'image','off');
    if i==1, title(ax,'Uploaded original'); else
        title(ax,sprintf('%s | %d B | %.2f dB | SSIM %.3f',labels(i),rows.Bytes(i-1),rows.PSNR(i-1),rows.SSIM(i-1)), ...
            'Interpreter','none','FontSize',9);
    end
end
exportgraphics(fig,fullfile(out,'compression_comparison.png'),'Resolution',180); clear guard;
end

function write_rate_figure(T,out,name)
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig)); hold on;
for method=unique(T.Method,'stable')'
    R=sortrows(T(T.Method==method,:),'BPP'); plot(R.BPP,R.PSNR,'-o','DisplayName',char(method));
end
hold off; xlabel('Bits per pixel'); ylabel('PSNR (dB)'); legend('Location','best'); grid on;
title(sprintf('Rate-distortion curves for %s',name),'Interpreter','none');
exportgraphics(fig,fullfile(out,'rate_distortion.png')); clear guard;
end

function [w,b,gaps]=scratch_svm(X,y)
C=1; a=zeros(size(y)); w=zeros(size(X,2),1); gaps=zeros(200001,1);
for t=1:numel(gaps)
    score=y-X*w;
    up=(y==1 & a<C-1e-10)|(y==-1 & a>1e-10);
    down=(y==1 & a>1e-10)|(y==-1 & a<C-1e-10);
    lo=score; lo(~up)=-Inf; hi=score; hi(~down)=Inf;
    [v,i]=max(lo); [u,j]=min(hi); gaps(t)=max(0,v-u);
    if gaps(t)<1e-5, break; end
    di=C-a(i); if y(i)<0, di=a(i); end
    dj=a(j); if y(j)<0, dj=C-a(j); end
    delta=X(i,:)'-X(j,:)'; step=min([di,dj,(v-u)/max(eps,delta'*delta)]);
    a(i)=a(i)+y(i)*step; a(j)=a(j)-y(j)*step; w=w+step*delta;
end
gaps=gaps(1:t); b=(v+u)/2;
end

function remove_stream(path)
if isfile(path), delete(path); end
end
