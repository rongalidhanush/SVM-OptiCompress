function model=get_model(root,inputImage)
if nargin>1 && ~isempty(inputImage)
    model=train_image_model(inputImage);
    return
end
file=fullfile(root,'models','compression_svm.mat');
if isfile(file)
    s=load(file,'model'); model=s.model;
else
    model=train_svm_model();
end
end
