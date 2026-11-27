function model=train_svm_model(inputImage,lambda,level,scale)
root=setup();
if nargin>0 && ~isempty(inputImage)
    if nargin<2, lambda=32; end
    if nargin<3, level=1; end
    if nargin<4, scale=1; end
    model=train_image_model(inputImage,lambda,level,scale);
    if isnan(model.accuracy)
        fprintf('Image-specific SVM trained on %d blocks; no held-out blocks were available.\n',numel(model.labels));
    else
        fprintf('Image-specific SVM held-out block accuracy %.1f%%.\n',100*model.accuracy);
    end
    disp(model.confusion)
    return
end
[X,y,trainNames]=dataset('training',root);
[V,t,testNames]=dataset('testing',root);
assert(all(ismember(1:3,unique(y))),'Training set must contain all three rate-distortion classes.');
learner=templateSVM('KernelFunction','gaussian','KernelScale','auto','Standardize',true);
old=rng; restore=onCleanup(@() rng(old)); rng(17);
classifier=fitcecoc(X,y,'Learners',learner,'Coding','onevsone','ClassNames',(1:3)');
p=predict(classifier,V);
model=struct('classifier',compact(classifier),'accuracy',mean(p==t), ...
    'confusion',confusionmat(t,p,'Order',(1:3)'), 'trainingFiles',{trainNames}, ...
    'testingFiles',{testNames},'features',X,'labels',y);
save(fullfile(root,'models','compression_svm.mat'),'model');
fprintf('Held-out block accuracy %.1f%% (%d images, %d blocks)\n',100*model.accuracy,numel(testNames),numel(t));
disp(model.confusion)
end
function [X,y,names]=dataset(split,root)
files=dir(fullfile(root,'datasets',split,'*'));
files=files(~[files.isdir]); names={}; X=[]; y=[];
for i=1:numel(files)
    [~,~,ext]=fileparts(files(i).name);
    if ~ismember(lower(string(ext)),[".png",".jpg",".jpeg",".bmp",".tif",".tiff"]), continue; end
    b=image_blocks(read_image(fullfile(files(i).folder,files(i).name)));
    X=[X;block_features(b)]; y=[y;label_blocks(b)]; %#ok<AGROW>
    names{end+1}=files(i).name; %#ok<AGROW>
end
assert(~isempty(X),'Dataset is empty.');
end
