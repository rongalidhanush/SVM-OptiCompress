function model=get_model(root)
file=fullfile(root,'models','compression_svm.mat');
if isfile(file)
    s=load(file,'model'); model=s.model;
else
    model=train_svm_model();
end
end
