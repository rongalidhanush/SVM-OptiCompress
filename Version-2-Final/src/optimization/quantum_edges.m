function [map,summary]=quantum_edges(img,ax)
% Simulate H on one address qubit of each normalized 64-amplitude tile.
[blocks,grid]=image_blocks(read_image(img));
if size(blocks,3)==3
    light=.298936*blocks(:,:,1)+.587043*blocks(:,:,2)+.114021*blocks(:,:,3);
else
    light=blocks(:,:,1);
end
norms=sqrt(sum(light.^2,1));
% A black tile has no amplitude encoding. Assign zero contrast by convention.
state=reshape(light./max(norms,eps),8,8,[]);
% The |1> output of H on a pair (a,b) has amplitude (a-b)/sqrt(2).
vertical=(state(1:2:end,:,:)-state(2:2:end,:,:))/sqrt(2);
horizontal=(state(:,1:2:end,:)-state(:,2:2:end,:))/sqrt(2);
pv=reshape(sum(vertical.^2,[1 2]),[],1);
ph=reshape(sum(horizontal.^2,[1 2]),[],1);
map=reshape((pv+ph)/2,grid);
[row,col]=ind2sub(grid,(1:numel(map))');
summary=table(row,col,ph,pv,map(:),'VariableNames', ...
    {'BlockRow','BlockColumn','HorizontalProbability','VerticalProbability','MeanProbability'});
if nargin>1
    imagesc(ax,map); axis(ax,'image'); colorbar(ax);
    title(ax,'Simulated Hadamard edge probability'); xlabel(ax,'Block column'); ylabel(ax,'Block row');
end
end
