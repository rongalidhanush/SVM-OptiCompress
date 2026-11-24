function [map,profile,cost]=cluster_blocks(img,k)
% Group spatial blocks using squared distances in standardized feature space.
validateattributes(k,{'numeric'},{'scalar','integer','positive','finite'});
[blocks,grid]=image_blocks(read_image(img));
X=block_features(blocks);
spread=std(X,0,1);
spread(spread==0)=1;
Z=(X-mean(X,1))./spread;
k=min(k,size(unique(Z,'rows'),1));
if k==1
    group=ones(size(X,1),1);
    cost=sum((Z-mean(Z,1)).^2,'all');
else
    state=rng; restore=onCleanup(@() rng(state)); rng(17,'twister');
    [group,~,within]=kmeans(Z,k,'Replicates',5,'MaxIter',300);
    cost=sum(within);
end
% Order the display IDs by average gradient energy for easier interpretation.
energy=accumarray(group,X(:,5),[],@mean);
[~,order]=sort(energy);
ids=zeros(k,1); ids(order)=1:k;
group=ids(group); map=reshape(group,grid);
profile=table((1:k)',accumarray(group,1),accumarray(group,X(:,1),[],@mean), ...
    accumarray(group,X(:,4),[],@mean),energy(order),'VariableNames', ...
    {'Cluster','Blocks','MeanIntensity','EdgeDensity','GradientEnergy'});
end
