function data=image_block_dataset(input,lambda,level,scale)
% Build all block labels/features from one uploaded image and a reproducible
% within-image train/test partition. No external reference images are used.
if nargin<2 || isempty(lambda), lambda=32; end
if nargin<3 || isempty(level), level=1; end
if nargin<4 || isempty(scale), scale=1; end
img=read_image(input);
[blocks,grid]=image_blocks(img);
features=block_features(blocks);
labels=label_blocks(blocks,lambda,level,scale);
n=numel(labels);
trainMask=true(n,1); testMask=false(n,1);
for cls=unique(labels(:))'
    ids=find(labels==cls);
    if numel(ids)>=2
        held=mod((1:numel(ids))',5)==0;
        if ~any(held), held(end)=true; end
        testMask(ids(held))=true;
        trainMask(ids(held))=false;
    end
end
if ~any(testMask) && n>=2
    testMask(end)=true; trainMask(end)=false;
end
[blockRow,blockCol]=ind2sub(grid,(1:n)');
data=struct('Image',img,'Blocks',blocks,'Grid',grid,'Features',features, ...
    'Labels',labels(:),'TrainMask',trainMask,'TestMask',testMask, ...
    'BlockRow',blockRow,'BlockCol',blockCol);
end
