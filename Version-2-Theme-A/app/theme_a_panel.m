function theme_a_panel(tab,root,currentImageProvider)
% Browse benchmark results and analyze the currently uploaded image.
folder=fullfile(root,'results','theme_a');
g=uigridlayout(tab,[5 2]); g.RowHeight={38,42,48,'1x','1x'};
names={'Real-image PCA','Scratch SVM vs fitcsvm','Primal QP','Conjugate Gradient','Uploaded-image compression'};
pick=uidropdown(g,'Items',names,'ValueChangedFcn',@refresh);
btnDefault=uibutton(g,'Text','Re-run reference benchmark','ButtonPushedFcn',@recompute);
btnImage=uibutton(g,'Text','Analyze current uploaded image','ButtonPushedFcn',@recomputeCurrent);
btnImage.Layout.Column=[1 2];
caption=uilabel(g,'WordWrap','on'); caption.Layout.Column=[1 2];
tbl=uitable(g); tbl.Layout.Column=[1 2];
ax=uiaxes(g); ax.Layout.Column=[1 2];
refresh();
    function refresh(varargin)
        i=find(strcmp(pick.Value,names),1); cla(ax,'reset');
        btnImage.Enable=matlab.lang.OnOffSwitchState(~isempty(currentImageProvider()));
        try
            if i==1
                tbl.Data=readtable(fullfile(folder,'pca.csv'));
                t=tbl.Data; plot(ax,t.PCs,t.TestRelativeError,'-o'); xlabel(ax,'Principal components'); ylabel(ax,'Held-out relative feature error');
                caption.Text='PCA basis and scaling use the two fixed training images; the held-out image is the reference sample or your uploaded image.';
            elseif i==2
                tbl.Data=readtable(fullfile(folder,'svm.csv'));
                name='svm_kkt_history.csv'; v=readmatrix(fullfile(folder,name));
                semilogy(ax,0:numel(v)-1,max(eps,v)); xlabel(ax,'Pair update'); ylabel(ax,'SVM KKT violation');
                caption.Text='Scratch SVM and MATLAB fitcsvm results for the fixed training split and the current benchmark/test image.';
            elseif i==3
                cvxFile=fullfile(folder,'cvxopt.csv'); qpFile=fullfile(folder,'quadprog.csv');
                if isfile(cvxFile)
                    tbl.Data=readtable(cvxFile); q=tbl.Data;
                    bar(ax,[q.MaxViolation q.DualityGap]); xticks(ax,1:2); xticklabels(ax,{'Violation','Duality gap'});
                    caption.Text='CVXOPT result for this run. The optional Python solver can be run on a custom run folder after the MATLAB analysis.';
                elseif isfile(qpFile)
                    tbl.Data=readtable(qpFile);
                    q=tbl.Data; bar(ax,[q.MaxViolation]); ylabel(ax,'Maximum constraint violation');
                    caption.Text='MATLAB quadprog solves the primal soft-margin problem on these Theme A training rows and evaluates the held-out image.';
                else
                    error('No QP result file is available in the selected run folder.');
                end
            elseif i==4
                tbl.Data=readtable(fullfile(folder,'cg.csv'));
                v=readmatrix(fullfile(folder,'cg_residual.csv')); semilogy(ax,0:numel(v)-1,max(eps,v)); xlabel(ax,'Iteration'); ylabel(ax,'Relative residual');
                caption.Text='Sparse image-smoothing system built from the held-out image; compared with MATLAB pcg.';
            else
                f=fullfile(folder,'compression_metrics.csv');
                tbl.Data=readtable(f); t=tbl.Data;
                plot(ax,t.BPP,t.PSNR,'o','LineWidth',1.3); xlabel(ax,'Bits per pixel'); ylabel(ax,'PSNR (dB)'); grid(ax,'on');
                caption.Text='Compression metrics for Fixed, Rules, SVM, Selective SVM, and Exhaustive methods. Reconstructions and the comparison figure are saved in the run folder.';
            end
            grid(ax,'on');
        catch err
            tbl.Data=[]; caption.Text=['No results to display: ' err.message];
        end
    end
    function recompute(varargin)
        btnDefault.Enable='off'; caption.Text='Re-running the reference MATLAB-image benchmark...'; drawnow;
        try
            folder=run_theme_a(); refresh();
            caption.Text=['Reference benchmark refreshed in ' folder];
        catch err, caption.Text=err.message; end
        btnDefault.Enable='on';
    end
    function recomputeCurrent(varargin)
        imagePath=currentImageProvider();
        if isempty(imagePath), caption.Text='Upload an image in the Image codec tab first.'; return; end
        btnImage.Enable='off'; caption.Text='Running Theme A on the uploaded image. This may take a little while...'; drawnow;
        try
            folder=run_theme_a(imagePath); refresh();
            caption.Text=['Uploaded-image Theme A outputs saved in ' folder];
        catch err, caption.Text=err.message; end
        btnImage.Enable='on';
    end
end
