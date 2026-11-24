function run_theme_a()
% Real-image course experiments; run from the project root.
root=setup(); out=fullfile(root,'results','theme_a');
if ~isfolder(out), mkdir(out); end
names=["street1.jpg","ngc6543a.jpg","peppers.png"];
paths=[fullfile(matlabroot,'toolbox','matlab','demos',names(1)), ...
    fullfile(matlabroot,'toolbox','matlab','demos',names(2)), ...
    fullfile(matlabroot,'toolbox','matlab','matlab_images','png',names(3))];
X=[]; labels=[]; scene=[]; block=[];
for i=1:numel(paths)
    img=read_image(paths(i)); b=image_blocks(img); count=size(b,2);
    X=[X;block_features(b)]; labels=[labels;label_blocks(b)]; %#ok<AGROW>
    scene=[scene;repmat(i,count,1)]; block=[block;(1:count)']; %#ok<AGROW>
end
tbl=array2table(X,'VariableNames',{'Mean','Std','Variance','EdgeDensity','GradientEnergy','Entropy','FrequencyEnergy'});
tbl.Image=reshape(names(scene),[],1); tbl.BlockIndex=block; tbl.Class=labels;
writetable(tbl,fullfile(out,'real_blocks.csv'));
train=scene<3; mu=mean(X(train,:)); sd=std(X(train,:)); sd(sd==0)=1; Z=(X-mu)./sd;
[V,d]=eig(cov(Z(train,:)),'vector'); [d,ix]=sort(d,'descend'); V=V(:,ix);
err=zeros(7,1); ztest=Z(~train,:);
for k=1:7
    err(k)=norm(ztest-ztest*V(:,1:k)*V(:,1:k)','fro')/norm(ztest,'fro');
end
writetable(table((1:7)',100*cumsum(d)/sum(d),err,'VariableNames',{'PCs','TrainCumulativePercent','TestRelativeError'}),fullfile(out,'pca.csv'));
assert(err(end)<1e-10 && all(diff(err)<1e-10));
% Cap training work per class deterministically. Evaluate every eligible held-out block.
ids=[];
for cls=[1 3]
    pool=find(train & labels==cls);
    assert(~isempty(pool),'Missing training class');
    ids=[ids;pool(round(linspace(1,numel(pool),min(100,numel(pool)))) )]; %#ok<AGROW>
end
A=Z(ids,:); y=labels(ids)-2; test=~train & labels~=2; B=Z(test,:); truth=labels(test)-2;
assert(numel(unique(truth))==2);
[w,bias,gaps]=scratch_svm(A,y);
lib=fitcsvm(A,y,'KernelFunction','linear','BoxConstraint',1,'Standardize',false);
pred=2*((B*w+bias)>=0)-1; ref=predict(lib,B);
writematrix([A y],fullfile(out,'svm_train.csv')); writematrix([B truth],fullfile(out,'svm_test.csv'));
cost=@(v,b) .5*(v'*v)+sum(max(0,1-y.*(A*v+b)));
summary=table(["scratch";"fitcsvm"],[cost(w,bias);cost(lib.Beta,lib.Bias)], ...
    [mean(pred==truth);mean(ref==truth)],'VariableNames',{'Method','PrimalObjective','HeldOutAccuracy'});
disp(summary); writetable(summary,fullfile(out,'svm.csv'));
writematrix(gaps,fullfile(out,'svm_kkt_history.csv'));
assert(gaps(end)<1e-4 && abs(diff(summary.PrimalObjective))<0.02*max(summary.PrimalObjective));
% Pixel smoothing: (I + 8 L)u = f on the real held-out image.
f=double(img(:,:,1)); [h,n]=size(f);
difference=@(k) diff(speye(k),1,1);
Dh=difference(h); Dw=difference(n);
M=speye(h*n)+8*(kron(speye(n),Dh'*Dh)+kron(Dw'*Dw,speye(h)));
rhs=f(:); x=zeros(size(rhs)); res=rhs; p=res; rr=res'*res; history=1;
for iter=1:500
    Mp=M*p; step=rr/(p'*Mp); x=x+step*p; res=res-step*Mp;
    next=res'*res; history(end+1)=sqrt(next)/norm(rhs); %#ok<AGROW>
    if history(end)<1e-8, break; end
    p=res+(next/rr)*p; rr=next;
end
[xref,flag,~,it,base]=pcg(M,rhs,1e-8,500);
actual=norm(M*x-rhs)/norm(rhs); relative=norm(x-xref)/norm(xref);
assert(flag==0 && actual<1.1e-8 && relative<1e-6);
writetable(table(h*n,nnz(M),iter,it,actual,relative,'VariableNames',{'Unknowns','Nonzeros','ScratchIterations','PcgIterations','RelativeResidual','DifferenceFromPcg'}),fullfile(out,'cg.csv'));
writematrix(history(:),fullfile(out,'cg_residual.csv'));
fig=figure('Visible','off'); guard=onCleanup(@() close(fig)); tiledlayout(1,2);
nexttile; semilogy(0:numel(gaps)-1,max(gaps,eps)); xlabel('Pair updates'); ylabel('SVM KKT violation'); grid on;
nexttile; semilogy(0:iter,history,'-',0:it,base/norm(rhs),'--'); xlabel('Iteration'); ylabel('Relative residual'); legend('Scratch CG','MATLAB pcg'); grid on;
exportgraphics(fig,fullfile(out,'convergence.png'));
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
