function r=svm_qp_demo(model,ax)
if isfield(model,'sourceKind') && strcmp(model.sourceKind,'uploaded-image')
    data=struct('Features',model.allFeatures,'Labels',model.allLabels, ...
        'TrainMask',model.trainMask,'TestMask',model.testMask);
    binary=image_binary_split(data); q=solve_image_qp(binary);
    r=struct('objective',q.Objective,'accuracy',q.HeldOutAccuracy, ...
        'supportCount',NaN,'width',NaN,'minFunctionalMargin',NaN, ...
        'primal',q.MaxViolation,'dual',NaN,'stationarity',NaN, ...
        'complementarity',NaN,'status',q.Status,'reason',q.Reason, ...
        'isImageRun',true,'margins',[]);
    if binary.Available && isfield(q,'Weights') && ~isempty(q.Weights)
        r.margins=binary.TestY.*(binary.TestX*q.Weights+q.Bias);
        if ~isempty(r.margins), r.minFunctionalMargin=min(r.margins); end
        r.width=2/norm(q.Weights);
    end
    if nargin>1 && ~isempty(ax)
        cla(ax);
        if binary.Available && ~isempty(r.margins)
            stem(ax,1:numel(r.margins),r.margins,'filled'); yline(ax,1,'k--');
            xlabel(ax,'Held-out block'); ylabel(ax,'Signed functional margin');
            title(ax,'Uploaded-image QP margins'); grid(ax,'on');
        else
            text(ax,.05,.5,char(q.Reason),'Units','normalized','Interpreter','none'); axis(ax,'off');
        end
    end
    return
end
% Use two named features and bounded, evenly spaced samples per class.
ids=[]; y=[];
for k=[1 3]
    ix=find(model.labels==k); ix=ix(round(linspace(1,numel(ix),min(70,numel(ix)))));
    ids=[ids;ix(:)]; y=[y;repmat(k-2,numel(ix),1)];
end
X=model.features(ids,[2 4]); X=(X-mean(X))./max(std(X),eps);
n=numel(y); C=1; H=spdiags([1;1;zeros(n+1,1)],0,n+3,n+3);
f=[0;0;0;C*ones(n,1)]; A=[sparse(-y.*X),sparse(-y),-speye(n)];
lb=[-inf(3,1);zeros(n,1)];
[z,obj,flag,~,lambda]=quadprog(H,f,A,-ones(n,1),[],[],lb,[],[], ...
    optimoptions('quadprog','Display','off','ConstraintTolerance',1e-9,'OptimalityTolerance',1e-9));
assert(flag>0,'quadprog did not converge.');
w=z(1:2); b=z(3); slack=z(4:end); margin=y.*(X*w+b);
alpha=lambda.ineqlin; mu=lambda.lower(4:end); sv=alpha>1e-5;
r=struct('objective',obj,'supportCount',nnz(sv),'accuracy',mean(margin>0), ...
    'width',2/norm(w),'minFunctionalMargin',min(margin),'margins',margin,'w',w,'b',b, ...
    'slack',slack,'alpha',alpha,'mu',mu,'primal',max([0;1-margin-slack;-slack]), ...
    'dual',max([0;-alpha;-mu]),'stationarity',norm(H*z+f+A'*alpha-lambda.lower,inf), ...
    'complementarity',max(abs([alpha.*(margin+slack-1);mu.*slack])));
if nargin>1 && ~isempty(ax)
    cla(ax); scatter(ax,X(:,1),X(:,2),22,y,'filled'); hold(ax,'on');
    plot(ax,X(sv,1),X(sv,2),'ko','MarkerSize',8);
    [u,v]=meshgrid(linspace(min(X(:,1))-.2,max(X(:,1))+.2,80),linspace(min(X(:,2))-.2,max(X(:,2))+.2,80));
    F=w(1)*u+w(2)*v+b;
    contour(ax,u,v,F,[-1 1],'k--'); contour(ax,u,v,F,[0 0],'k-','LineWidth',2);
    hold(ax,'off'); xlabel(ax,'Standard deviation (standardized)'); ylabel(ax,'Edge density (standardized)');
    title(ax,'Binary SVM | circles indicate support vectors');
end
end
