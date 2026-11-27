function [model,data]=train_image_model(input,lambda,level,scale)
% Fit the codec's three-class SVM using blocks from the uploaded image only.
if nargin<2, lambda=32; end
if nargin<3, level=1; end
if nargin<4, scale=1; end
data=image_block_dataset(input,lambda,level,scale);
X=data.Features; y=data.Labels; train=data.TrainMask; test=data.TestMask;
classes=unique(y(train));
assert(~isempty(classes),'The uploaded image produced no training blocks.');
selected=[];
for cls=classes(:)'
    ids=find(train & y==cls);
    pick=unique(round(linspace(1,numel(ids),min(500,numel(ids)))));
    selected=[selected;ids(pick(:))]; %#ok<AGROW>
end
selected=sort(selected);
model=struct('classifier',[],'fallbackClass',[],'accuracy',NaN, ...
    'confusion',zeros(3),'trainingFiles',{{'uploaded image'}}, ...
    'features',X(selected,:),'labels',y(selected),'allFeatures',X,'allLabels',y, ...
    'trainMask',train,'testMask',test,'sourceKind','uploaded-image', ...
    'testFeatures',X(test,:),'testLabels',y(test), ...
    'trainingClasses',classes(:)','ratePenalty',lambda, ...
    'compressionLevel',level,'compressionScale',scale);
if numel(classes)>=2
    learner=templateSVM('KernelFunction','gaussian','KernelScale','auto','Standardize',true);
    classifier=fitcecoc(X(selected,:),y(selected),'Learners',learner,'Coding','onevsone', ...
        'ClassNames',classes(:));
    model.classifier=compact(classifier);
    if any(test)
        predicted=predict(model.classifier,X(test,:));
        model.accuracy=mean(predicted==y(test));
        model.confusion=confusionmat(y(test),predicted,'Order',(1:3)');
    end
else
    % A constant, image-derived policy keeps compression available when this
    % photo's rate-distortion labels contain only one class.
    model.fallbackClass=classes(1);
    if any(test), model.accuracy=mean(y(test)==model.fallbackClass); end
    model.confusion(model.fallbackClass,model.fallbackClass)=nnz(test);
end
end
