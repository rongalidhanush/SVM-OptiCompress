function theme_a_panel(tab,root)
% Browse measured course results directly from the desktop launcher.
folder=fullfile(root,'results','theme_a');
g=uigridlayout(tab,[4 2]); g.RowHeight={38,48,'1x','1x'};
names={'Real-image PCA','Scratch SVM vs fitcsvm','CVXOPT (saved run)','Conjugate Gradient'};
files={'pca.csv','svm.csv','cvxopt.csv','cg.csv'};
info={'Training variance and held-out relative feature reconstruction error for one to seven components.', ...
    'Same binary training split and objective. Held-out classes are highly imbalanced.', ...
    'Saved Python CVXOPT result on the exported training data. This table shows the packaged solver run.', ...
    'Sparse image smoothing. Compare the iterations and relative residual with MATLAB pcg.'};
pick=uidropdown(g,'Items',names,'ValueChangedFcn',@refresh);
btn=uibutton(g,'Text','Re-run MATLAB experiments','ButtonPushedFcn',@recompute);
caption=uilabel(g,'WordWrap','on'); caption.Layout.Column=[1 2];
tbl=uitable(g); tbl.Layout.Column=[1 2];
ax=uiaxes(g); ax.Layout.Column=[1 2];
refresh();
    function refresh(varargin)
        i=find(strcmp(pick.Value,names),1);
        caption.Text=info{i}; cla(ax,'reset');
        try
            tbl.Data=readtable(fullfile(folder,files{i}));
            if i==1
                t=tbl.Data; plot(ax,t.PCs,t.TestRelativeError,'-o'); xlabel(ax,'Principal components'); ylabel(ax,'Held-out relative error');
            elseif i==3
                bar(ax,[tbl.Data.MaxViolation tbl.Data.DualityGap]); xticks(ax,1:2); xticklabels(ax,{'Maximum violation','Duality gap'}); ylabel(ax,'Solver diagnostic');
            else
                name='svm_kkt_history.csv'; label='SVM KKT violation';
                if i==4, name='cg_residual.csv'; label='Relative residual'; end
                v=readmatrix(fullfile(folder,name)); semilogy(ax,0:numel(v)-1,max(eps,v)); xlabel(ax,'Iteration'); ylabel(ax,label);
            end
            grid(ax,'on');
        catch err
            tbl.Data=[]; caption.Text=err.message;
        end
    end
    function recompute(varargin)
        btn.Enable='off'; caption.Text='Running the MATLAB experiments...'; drawnow;
        try, run_theme_a(); refresh(); catch err, caption.Text=err.message; end
        btn.Enable='on';
    end
end
