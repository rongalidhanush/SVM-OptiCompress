function results=run_selective_pilot()
% Compare selection policies against exhaustive nominal-level block costs.
root=setup(); model=get_model(root);
files=dir(fullfile(root,'datasets','testing','*.png'));
results=table();
for f=1:numel(files)
    blocks=image_blocks(read_image(fullfile(files(f).folder,files(f).name)));
    [oracle,d]=label_blocks(blocks);
    base=selective_quantizers(blocks,model,0);
    [hybrid,indices]=selective_quantizers(blocks,model,.25);
    row=(1:numel(base))';
    at=@(c) d.cost(sub2ind(size(d.cost),row,c));
    excess=at(base)-at(oracle);
    % Exact expectation for a uniformly random subset of the same size.
    random=mean(excess)*(1-numel(indices)/numel(base));
    r=table(string(files(f).name),numel(base),numel(indices),mean(excess), ...
        mean(at(hybrid)-at(oracle)),random,'VariableNames', ...
        {'Image','Blocks','Reviewed','SVMExcess','SelectiveExcess','RandomExpectedExcess'});
    results=[results;r]; %#ok<AGROW>
end
disp(results)
end
