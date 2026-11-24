function binary=image_binary_split(data)
% One-vs-rest binary data derived only from the uploaded image's block labels.
train=data.TrainMask; test=data.TestMask; labels=data.Labels;
binary=struct('Available',false,'Reason','','PositiveClass',NaN,'Mean',[], ...
    'Scale',[],'TrainX',[],'TrainY',[],'TestX',[],'TestY',[]);
classes=unique(labels(train));
if numel(classes)<2
    binary.Reason='This image has fewer than two rate-distortion classes in its training blocks.';
    return
end
positive=classes(end);
mu=mean(data.Features(train,:),1); scale=std(data.Features(train,:),0,1); scale(scale==0)=1;
Z=(data.Features-mu)./scale;
trainRows=find(train); allTrainY=2*(labels(train)==positive)-1;
selected=[];
for cls=[-1 1]
    pool=find(allTrainY==cls);
    if isempty(pool), continue; end
    pick=unique(round(linspace(1,numel(pool),min(100,numel(pool)))));
    selected=[selected;pool(pick(:))]; %#ok<AGROW>
end
selected=sort(selected); trainY=allTrainY(selected);
if numel(unique(trainY))<2
    binary.Reason='The uploaded image does not provide both binary classes for the SVM split.';
    return
end
binary.Available=true; binary.PositiveClass=positive; binary.Mean=mu; binary.Scale=scale;
binary.TrainX=Z(trainRows(selected),:); binary.TrainY=trainY;
binary.TestX=Z(test,:); binary.TestY=2*(labels(test)==positive)-1;
end
