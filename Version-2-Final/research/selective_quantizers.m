function [classes,reviewed,changed]=selective_quantizers(blocks,model,fraction,level,scale)
% Spend a bounded number of three-quantizer searches on ambiguous SVM decisions.
validateattributes(fraction,{'numeric'},{'real','finite','scalar','>=',0,'<=',1});
if nargin<4, level=1; end
if nargin<5, scale=1; end
[classes,scores]=predict_block_model(model,block_features(blocks));
scores=sort(scores,2,'descend');
gap=scores(:,1)-scores(:,2);
[~,order]=sort(gap,'ascend');
reviewed=order(1:floor(numel(classes)*fraction));
if ~isempty(reviewed)
    lambda=32; if isfield(model,'ratePenalty'), lambda=model.ratePenalty; end
    decisions=label_blocks(blocks(:,reviewed,:),lambda,level,scale);
    changed=nnz(classes(reviewed)~=decisions);
    classes(reviewed)=decisions;
else
    changed=0;
end
end
