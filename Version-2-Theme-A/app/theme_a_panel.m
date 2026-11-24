function resetHandle=theme_a_panel(tab,root,currentImageProvider)
% Display only results from the currently selected uploaded photo.
folder='';
names={'PCA and held-out variance','SVM training/convergence','Primal QP', ...
    'Conjugate gradient','Six-image compression','Rate-distortion', ...
    'Clustering','Spatial transitions','Block costs and map','Every block feature', ...
    'Raw covariance matrix','Feature correlation matrix','PCA covariance matrix'};
g=uigridlayout(tab,[3 2]); g.RowHeight={38,58,'1x'}; g.ColumnWidth={'1x','1.6x'};
pick=uidropdown(g,'Items',names,'ValueChangedFcn',@refresh);
runButton=uibutton(g,'Text','Analyze current uploaded image','ButtonPushedFcn',@analyze);
status=uilabel(g,'Text','Upload a photo, then analyze it here.','WordWrap','on'); status.Layout.Row=2; status.Layout.Column=[1 2];
tbl=uitable(g); tbl.Layout.Row=3; tbl.Layout.Column=1;
ax=uiaxes(g); ax.Layout.Row=3; ax.Layout.Column=2;
pick.Enable='off';
resetHandle=@resetForNewImage;
    function resetForNewImage()
        folder=''; pick.Enable='off'; runButton.Enable=matlab.lang.OnOffSwitchState(~isempty(currentImageProvider()));
        tbl.Data=[]; cla(ax,'reset'); status.Text='New image selected. Click Analyze current uploaded image to compute and save all results.';
    end
    function analyze(varargin)
        settings=currentImageProvider();
        if isempty(settings), status.Text='Upload a photo in the Image codec tab first.'; return; end
        runButton.Enable='off'; pick.Enable='off'; status.Text='Computing all image-specific results and figures...'; drawnow;
        try
            folder=run_theme_a(settings.Path,settings.Level,settings.Scale,settings.Clusters,settings.Lambda);
            if strlength(string(folder))==0, status.Text='Analysis cancelled.'; else
                pick.Enable='on'; refresh();
                status.Text=sprintf('Results for %s saved in %s',fileBase(settings.Path),folder);
            end
        catch err
            status.Text=['Analysis failed: ' err.message];
            try, uialert(ancestor(tab,'figure'),err.message,'Theme A analysis failed'); catch, end
        end
        runButton.Enable='on';
    end
    function refresh(varargin)
        if isempty(folder) || ~isfolder(folder)
            tbl.Data=[]; cla(ax,'reset'); status.Text='Analyze an uploaded photo to populate these results.'; return
        end
        i=find(strcmp(pick.Value,names),1); cla(ax,'reset');
        try
            switch i
                case 1
                    tbl.Data=readtable(fullfile(folder,'pca.csv')); showSavedImage('pca_results.png');
                case 2
                    tbl.Data=readtable(fullfile(folder,'svm.csv')); showSavedImage('svm_convergence.png');
                case 3
                    tbl.Data=readtable(fullfile(folder,'quadprog.csv')); showSavedImage('svm_qp_margins.png');
                case 4
                    tbl.Data=readtable(fullfile(folder,'cg.csv')); showSavedImage('cg_convergence.png');
                case 5
                    tbl.Data=readtable(fullfile(folder,'compression_metrics.csv')); showSavedImage('compression_comparison.png');
                case 6
                    tbl.Data=readtable(fullfile(folder,'rate_curves.csv')); showSavedImage('rate_distortion.png');
                case 7
                    tbl.Data=readtable(fullfile(folder,'cluster_profile.csv')); showSavedImage('cluster_map.png');
                case 8
                    tbl.Data=array2table(readmatrix(fullfile(folder,'spatial_transition_probabilities.csv')));
                    showSavedImage('spatial_transitions.png');
                case 9
                    tbl.Data=readtable(fullfile(folder,'block_costs.csv')); showSavedImage('block_cost_map.png');
                case 10
                    tbl.Data=readtable(fullfile(folder,'block_features.csv'));
                    tbl.Data=tbl.Data(1:min(height(tbl.Data),5000),:);
                    imagesc(ax,readmatrix(fullfile(folder,'cluster_map.csv'))); axis(ax,'image'); colorbar(ax);
                    title(ax,'Current-image block labels and split');
                case 11
                    tbl.Data=readtable(fullfile(folder,'feature_covariance.csv')); showSavedImage('feature_covariance.png');
                case 12
                    tbl.Data=readtable(fullfile(folder,'feature_correlation.csv')); showSavedImage('feature_correlation.png');
                case 13
                    tbl.Data=readtable(fullfile(folder,'pca_covariance.csv')); showSavedImage('pca_covariance.png');
            end
        catch err
            tbl.Data=[]; status.Text=['Could not load result: ' err.message];
            try, uialert(ancestor(tab,'figure'),err.message,'Could not display Theme A result'); catch, end
        end
    end
    function showSavedImage(file)
        imagePath=fullfile(folder,file);
        if ~isfile(imagePath), return; end
        pic=imread(imagePath); image(ax,pic); axis(ax,'image','off');
    end
end

function name=fileBase(path)
[~,name,ext]=fileparts(path); name=[name ext];
end
