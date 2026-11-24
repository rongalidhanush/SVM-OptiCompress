function root = setup()
% Add only project code and create output locations.
root = fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'app'),fullfile(root,'research'),genpath(fullfile(root,'src')));
for name = ["fitcecoc","quadprog"]
    assert(~isempty(which(name)), 'Missing required toolbox function %s.', name);
end
for folder = ["models","datasets/training","datasets/testing","datasets/sample_images", ...
        "results/compressed","results/reconstructed","results/graphs","results/metrics"]
    dest = fullfile(root,folder);
    if ~isfolder(dest), mkdir(dest); end
end
generate_samples(root);
end

