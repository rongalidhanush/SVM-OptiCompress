function [prob,counts]=spatial_transitions(groups)
% Estimate P(right block = j | current block = i) within each image row.
k=max(groups,[],'all');
left=groups(:,1:end-1); right=groups(:,2:end);
counts=zeros(k);
if ~isempty(left)
    counts=accumarray([left(:),right(:)],1,[k k]);
end
prob=counts./sum(counts,2); % NaN denotes a state with no observed neighbor.
end
