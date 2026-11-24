function out=run_theme_a(testImagePath)
% Theme A experiments. With no input, reproduce the packaged MATLAB-image benchmark.
% With a path, use that image as a scene-level held-out test image and save a
% complete run under results/theme_a/user_runs without replacing the benchmark.
root=setup();
referenceNames=["street1.jpg","ngc6543a.jpg"];
referencePaths=[fullfile(matlabroot,'toolbox','matlab','demos',referenceNames(1)), ...
    fullfile(matlabroot,'toolbox','matlab','demos',referenceNames(2))];
isUserRun=nargin>0 && strlength(string(testImagePath))>0;
if isUserRun
    testImagePath=char(testImagePath);
    assert(isfile(testImagePath),'Selected test image does not exist: %s',testImagePath);
    [~,stem,ext]=fileparts(testImagePath);
    safeStem=regexprep(stem,'[^A-Za-z0-9_-]','_');
    runName=sprintf('%s_%s',datestr(now,'yyyymmdd_HHMMSS'),safeStem);
    out=fullfile(root,'results','theme_a','user_runs',runName);
    if ~isfolder(out), mkdir(out); end
    testPath=string(testImagePath);
    testName=string([stem ext]);
else
    out=fullfile(root,'results','theme_a');
    testPath=fullfile(matlabroot,'toolbox','matlab','matlab_images','png','peppers.png');
    testName="peppers.png";
end
if ~isfolder(out), mkdir(out); end
paths=[referencePaths,testPath]; names=[referenceNames,testName];
X=[]; labels=[]; scene=[]; block=[];
for i=1:numel(paths)
    img=read_image(paths(i)); b=image_blocks(img); count=size(b,2);
    X=[X;block_features(b)]; labels=[labels;label_blocks(b)]; %#ok<AGROW>
    scene=[scene;repmat(i,count,1)]; block=[block;(1:count)']; %#ok<AGROW>
end
tbl=array2table(X,'VariableNames',{'Mean','Std','Variance','EdgeDensity','GradientEnergy','Entropy','FrequencyEnergy'});
tbl.Image=reshape(names(scene),[],1); tbl.BlockIndex=block; tbl.Class=labels;
writetable(tbl,fullfile(out,'real_blocks.csv'));

% Fit feature scaling and PCA only on the two reference training scenes.
train=scene<3; mu=mean(X(train,:)); sd=std(X(train,:)); sd(sd==0)=1; Z=(X-mu)./sd;
[V,d]=eig(cov(Z(train,:)),'vector'); [d,ix]=sort(d,'descend'); V=V(:,ix);
err=zeros(7,1); ztest=Z(~train,:);
for k=1:7
    err(k)=norm(ztest-ztest*V(:,1:k)*V(:,1:k)','fro')/max(norm(ztest,'fro'),eps);
end
pcaTable=table((1:7)',100*cumsum(d)/sum(d),err,'VariableNames', ...
    {'PCs','TrainCumulativePercent','TestRelativeError'});
writetable(pcaTable,fullfile(out,'pca.csv'));
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig));
tiledlayout(fig,1,2,'Padding','compact');
nexttile; plot(1:7,pcaTable.TrainCumulativePercent,'-o'); xlabel('Components'); ylabel('Train variance (%)'); grid on;
nexttile; semilogy(1:7,max(pcaTable.TestRelativeError,1e-15),'-o'); xlabel('Components'); ylabel('Held-out feature error'); grid on;
exportgraphics(fig,fullfile(out,'pca_results.png')); clear guard;

% Train on the same two fixed scenes; evaluate all eligible blocks in the
% selected scene. This keeps the split by image and prevents scene leakage.
ids=[];
for cls=[1 3]
    pool=find(train & labels==cls);
    assert(~isempty(pool),'Missing training class %d.',cls);
    ids=[ids;pool(round(linspace(1,numel(pool),min(100,numel(pool)))) )]; %#ok<AGROW>
end
A=Z(ids,:); y=labels(ids)-2;
test=~train & labels~=2; B=Z(test,:); truth=labels(test)-2;
[w,bias,gaps]=scratch_svm(A,y);
lib=fitcsvm(A,y,'KernelFunction','linear','BoxConstraint',1,'Standardize',false);
pred=2*((B*w+bias)>=0)-1; ref=predict(lib,B);
cost=@(v,b) .5*(v'*v)+sum(max(0,1-y.*(A*v+b)));
if isempty(truth), accScratch=NaN; accLibrary=NaN; else
    accScratch=mean(pred==truth); accLibrary=mean((2*(ref>=0)-1)==truth);
end
summary=table(["scratch";"fitcsvm"],[cost(w,bias);cost(lib.Beta,lib.Bias)], ...
    [accScratch;accLibrary],'VariableNames',{'Method','PrimalObjective','HeldOutAccuracy'});
disp(summary); writetable(summary,fullfile(out,'svm.csv'));
writematrix([A y],fullfile(out,'svm_train.csv')); writematrix([B truth],fullfile(out,'svm_test.csv'));
writematrix(gaps,fullfile(out,'svm_kkt_history.csv'));
counts=table(["strong";"light"],[nnz(truth==1);nnz(truth==-1)], ...
    'VariableNames',{'HeldOutClass','Count'});
writetable(counts,fullfile(out,'svm_test_class_counts.csv'));
if gaps(end)>=1e-4, warning('Scratch SVM stopped with KKT violation %.3g.',gaps(end)); end

% Re-solve the identical primal QP in MATLAB so this run has a QP result even
% when the optional Python/CVXOPT dependency is not installed.
qp=solve_primal_qp(A,y,B,truth);
writetable(struct2table(qp),fullfile(out,'quadprog.csv'));

% CG smoothing uses the selected image's first channel. Bound the linear
% system size for large camera photos and record the actual CG dimensions.
img=read_image(testPath); originalSize=size(img); cgImg=img;
resizeFactor=min(1,800/max(size(img,1),size(img,2)));
if resizeFactor<1
    rowIndex=round(linspace(1,size(img,1),max(1,round(size(img,1)*resizeFactor))));
    colIndex=round(linspace(1,size(img,2),max(1,round(size(img,2)*resizeFactor))));
    cgImg=img(rowIndex,colIndex,:);
end
f=double(cgImg(:,:,1)); [h,n]=size(f);
difference=@(k) diff(speye(k),1,1);
Dh=difference(h); Dw=difference(n);
M=speye(h*n)+8*(kron(speye(n),Dh'*Dh)+kron(Dw'*Dw,speye(h)));
rhs=f(:); x=zeros(size(rhs)); res=rhs; p=res; rr=res'*res; history=1;
for iter=1:500
    Mp=M*p; step=rr/(p'*Mp); x=x+step*p; res=res-step*Mp;
    next=res'*res; history(end+1)=sqrt(next)/max(norm(rhs),eps); %#ok<AGROW>
    if history(end)<1e-8, break; end
    p=res+(next/rr)*p; rr=next;
end
[xref,flag,~,it,base]=pcg(M,rhs,1e-8,500);
actual=norm(M*x-rhs)/max(norm(rhs),eps); relative=norm(x-xref)/max(norm(xref),eps);
assert(flag==0 && actual<1.1e-8 && relative<1e-6,'CG comparison failed to meet tolerance.');
writetable(table(h*n,nnz(M),iter,it,actual,relative,originalSize(2),originalSize(1),n,h,resizeFactor, ...
    'VariableNames',{'Unknowns','Nonzeros','ScratchIterations','PcgIterations','RelativeResidual', ...
    'DifferenceFromPcg','OriginalWidth','OriginalHeight','CGWidth','CGHeight','CGScale'}), ...
    fullfile(out,'cg.csv'));
writematrix(history(:),fullfile(out,'cg_residual.csv'));
smoothed=uint8(min(255,max(0,reshape(x,h,n))));
imwrite(smoothed,fullfile(out,'cg_smoothed_channel.png'));
if resizeFactor<1, imwrite(cgImg,fullfile(out,'cg_input_resized.png')); end
fig=figure('Visible','off','Color','w'); guard=onCleanup(@() close(fig)); tiledlayout(fig,1,2);
nexttile; semilogy(0:numel(gaps)-1,max(gaps,eps)); xlabel('Pair updates'); ylabel('SVM KKT violation'); grid on;
nexttile; semilogy(0:iter,history,'-',0:it,base/max(norm(rhs),eps),'--'); xlabel('Iteration'); ylabel('Relative residual'); legend('Scratch CG','MATLAB pcg'); grid on;
exportgraphics(fig,fullfile(out,'convergence.png')); clear guard;

if isUserRun
    copyfile(testPath,fullfile(out,['input_image' ext]));
    metadata=table(string(testPath),string(datetime('now')),size(img,2),size(img,1),size(img,3), ...
        'VariableNames',{'SourcePath','RunTime','Width','Height','Channels'});
    writetable(metadata,fullfile(out,'run_metadata.csv'));
end
save_codec_outputs(img,root,out);
fprintf('Theme A results saved to: %s\n',out);
end

function q=solve_primal_qp(X,y,testX,testY)
[n,d]=size(X); H=spdiags([ones(d,1);0;zeros(n,1)],0,d+n+1,d+n+1);
f=[zeros(d+1,1);ones(n,1)];
A=[-spdiags(y,0,n,n)*X,-y,-speye(n)]; rhs=-ones(n,1);
lb=[-inf(d+1,1);zeros(n,1)];
opts=optimoptions('quadprog','Display','off','ConstraintTolerance',1e-9,'OptimalityTolerance',1e-9);
[z,obj,flag,output]=quadprog(H,f,A,rhs,[],[],lb,[],[],opts);
assert(flag>0,'MATLAB quadprog did not converge.');
if isempty(testY), accuracy=NaN; else
    accuracy=mean((testX*z(1:d)+z(d+1)>=0)==(testY>0));
end
violation=max([0;A*z-rhs;-z(d+2:end)]);
q=struct('Status',"optimal",'Objective',obj,'HeldOutAccuracy',accuracy, ...
    'MaxViolation',violation,'Iterations',output.iterations);
end

function save_codec_outputs(img,root,out)
model=get_model(root); methods=["Fixed","Rules","SVM","Selective SVM","Exhaustive"];
tmp=[tempname '.soc']; cleaner=onCleanup(@() remove_stream(tmp));
rows=table(); reconstructions=cell(numel(methods),1); labels=strings(numel(methods)+1,1);
labels(1)="Original"; reconstructions{1}=img;
for k=1:numel(methods)
    [~,enc,review]=compress_image(img,tmp,methods(k),1,1,model);
    [rec,~,dec]=decompress_image(tmp); m=image_metrics(img,rec,tmp,enc,dec);
    row=table(methods(k),m.Bytes,m.BPP,m.PSNR,m.SSIM,m.MSE,enc,dec, ...
        'VariableNames',{'Method','Bytes','BPP','PSNR','SSIM','MSE','Encode_s','Decode_s'});
    if methods(k)=="Selective SVM"
        row.Reviewed=review.checked; row.DecisionsChanged=review.changed;
    else
        row.Reviewed=NaN; row.DecisionsChanged=NaN;
    end
    rows=[rows;row]; %#ok<AGROW>
    reconstructions{k+1}=rec; labels(k+1)=methods(k);
    imwrite(rec,fullfile(out,sprintf('reconstruction_%s.png',lower(regexprep(methods(k),'[^A-Za-z0-9]','_')))));
end
writetable(rows,fullfile(out,'compression_metrics.csv'));
fig=figure('Visible','off','Color','w','Position',[100 100 1200 720]); guard=onCleanup(@() close(fig));
tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for k=1:numel(reconstructions)
    ax=nexttile;
    if size(reconstructions{k},3)==1, imagesc(ax,reconstructions{k},[0 255]); colormap(ax,gray(256)); else, image(ax,reconstructions{k}); end
    axis(ax,'image','off');
    if k==1, title(ax,'Original'); else
        title(ax,sprintf('%s | %d B | %.2f dB | SSIM %.3f',labels(k),rows.Bytes(k-1),rows.PSNR(k-1),rows.SSIM(k-1)), ...
            'Interpreter','none','FontSize',9);
    end
end
exportgraphics(fig,fullfile(out,'compression_comparison.png'),'Resolution',180); clear guard;
end

function remove_stream(path)
if isfile(path), delete(path); end
end

function [w,b,gaps]=scratch_svm(X,y)
% Dual pair-coordinate ascent. Updating by (+y_i,-y_j) preserves y'alpha=0.
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
    delta=X(i,:)'-X(j,:)'; s=min([di,dj,(v-u)/max(eps,delta'*delta)]);
    a(i)=a(i)+y(i)*s; a(j)=a(j)-y(j)*s; w=w+s*delta;
end
gaps=gaps(1:t); b=(v+u)/2;
end
