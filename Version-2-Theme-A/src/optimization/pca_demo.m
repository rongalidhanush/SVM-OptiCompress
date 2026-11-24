function [scores,explained]=pca_demo(img,ax)
X=block_features(image_blocks(read_image(img))); assert(size(X,1)>1,'PCA needs two or more blocks.');
Z=(X-mean(X))./max(std(X),eps);
[V,D]=eig((Z'*Z)/(size(Z,1)-1),'vector'); [d,ix]=sort(max(0,D),'descend');
scores=Z*V(:,ix(1:2)); explained=100*d/max(sum(d),eps);
if nargin>1
    cla(ax,'reset');
    scatter(ax,scores(:,1),scores(:,2),18,X(:,4),'filled');
    xlabel(ax,sprintf('PC1 (%.1f%%)',explained(1))); ylabel(ax,sprintf('PC2 (%.1f%%)',explained(2)));
    title(ax,'Block features | color indicates edge density');
end
end
