function [labels,scores]=predict_block_model(model,features)
% Predict block classes for either a trained ECOC model or one-class fallback.
if isfield(model,'fallbackClass') && ~isempty(model.fallbackClass)
    labels=repmat(model.fallbackClass,size(features,1),1);
    scores=zeros(size(features,1),3); scores(:,model.fallbackClass)=1;
else
    [labels,scores]=predict(model.classifier,features);
end
end
