function fig=OptiCompressApp(root)
% Desktop demonstration. The compressed stream can be opened in a fresh session.
if nargin==0, root=setup(); end
currentSourcePath=''; haveCurrentEncode=false;
fig=uifigure('Name','SVM-OptiCompress | Image compression laboratory','Position',[75 70 1090 720]);
tabs=uitabgroup(fig); outer=uigridlayout(fig,[1 1]); tabs.Parent=outer;
gallery=uitab(tabs,'Title','Six-image comparison');
galleryLayout=tiledlayout(gallery,2,3,'TileSpacing','compact','Padding','compact');
themeAReset=theme_a_panel(uitab(tabs,'Title','Theme A experiments'),root,@currentSettings);
codec=uitab(tabs,'Title','Image codec'); learning=uitab(tabs,'Title','Block classifier');
mathTab=uitab(tabs,'Title','Optimization & Quantum'); perf=uitab(tabs,'Title','Rate comparisons');
clusterTab=uitab(tabs,'Title','Clustering');
cg=uigridlayout(clusterTab,[4 1]); cg.RowHeight={36,'1x',160,30};
controls=uigridlayout(cg,[1 3]); controls.ColumnWidth={130,65,180}; controls.Padding=0;
uilabel(controls,'Text','Requested clusters');
kInput=uidropdown(controls,'Items',{'2','3','4','5','6','7'},'Value','3');
uibutton(controls,'Text','Cluster image blocks','ButtonPushedFcn',@clusterView);
clusterAx=uiaxes(cg); clusterTable=uitable(cg); clusterStatus=uilabel(cg);
spatialTab=uitab(tabs,'Title','Spatial transitions');
sg=uigridlayout(spatialTab,[3 1]); sg.RowHeight={40,'1x',62};
uilabel(sg,'Text','Rows = current cluster. Columns = cluster immediately to its right. Each entry is a conditional probability.');
transitionTable=uitable(sg,'Tag','SpatialMatrix');
spatialText=uilabel(sg,'WordWrap','on');
rdTab=uitab(tabs,'Title','Block cost');
rg=uigridlayout(rdTab,[4 1]); rg.RowHeight={38,'1x',125,50};
rc=uigridlayout(rg,[1 6]); rc.Padding=0; rc.ColumnWidth={80,70,105,70,160,90};
uilabel(rc,'Text','Block row'); blockRow=uispinner(rc,'Limits',[1 Inf],'RoundFractionalValues','on','ValueChangedFcn',@blockCost);
uilabel(rc,'Text','Block column'); blockCol=uispinner(rc,'Limits',[1 Inf],'RoundFractionalValues','on','ValueChangedFcn',@blockCost);
uilabel(rc,'Text','Rate penalty (lambda)'); penalty=uispinner(rc,'Limits',[0 1024],'Value',32,'Step',8,'ValueChangedFcn',@settingsChanged,'Tag','RatePenalty');
blockAx=uiaxes(rg); candidateTable=uitable(rg,'Tag','BlockCosts');
costText=uilabel(rg,'WordWrap','on');
g=uigridlayout(codec,[5 2]); g.RowHeight={38,38,'1x',52,60};
bar=uigridlayout(g,[1 5]); bar.Layout.Column=[1 2]; bar.ColumnWidth={110,145,95,'1x','1x'}; bar.Padding=0;
uibutton(bar,'Text','Upload image','ButtonPushedFcn',@upload);
method=uidropdown(bar,'Items',{'Selective SVM','SVM','Fixed','Rules','Exhaustive','Lossless PNG'});
uilabel(bar,'Text','Level  /  scale'); level=uispinner(bar,'Limits',[.1 150],'Value',1,'Step',.1,'ValueChangedFcn',@settingsChanged);
scale=uispinner(bar,'Limits',[.25 4],'Value',1,'Step',.25,'ValueChangedFcn',@settingsChanged);
bar2=uigridlayout(g,[1 4]); bar2.Layout.Column=[1 2]; bar2.Padding=0;
uibutton(bar2,'Text','Compress','ButtonPushedFcn',@encode);
uibutton(bar2,'Text','Save compressed file','ButtonPushedFcn',@saveStream);
uibutton(bar2,'Text','Open compressed file','ButtonPushedFcn',@openStream);
uibutton(bar2,'Text','Decompress','ButtonPushedFcn',@decode);
orig=uiaxes(g); recon=uiaxes(g); title(orig,'Original'); title(recon,'Reconstruction');
info=uilabel(g,'Text',''); info.Layout.Column=[1 2]; info.WordWrap='on';
status=uilabel(g,'Text','Ready'); status.Layout.Column=[1 2]; status.WordWrap='on';
l=uigridlayout(learning,[3 2]); l.RowHeight={34,50,'1x'};
uibutton(l,'Text','Train and validate SVM','ButtonPushedFcn',@train);
modelText=uilabel(l,'Text',''); counts=uilabel(l,'Text','Compress an image to see block assignments.');
counts.Layout.Column=[1 2]; mapAx=uiaxes(l); tableUI=uitable(l,'RowName',{'Strong','Moderate','Light'}, ...
    'ColumnName',{'Pred strong','Pred moderate','Pred light'});
mg=uigridlayout(mathTab,[3 2]); mg.RowHeight={36,'1x',110};
uibutton(mg,'Text','Solve binary SVM with quadprog','ButtonPushedFcn',@qp);
uibutton(mg,'Text','Simulate quantum edges','ButtonPushedFcn',@quantumView);
qa=uiaxes(mg); pa=uiaxes(mg);
qt=uitextarea(mg,'Editable','off','Value',{'Minimize 0.5 ||w||² + C Σξ with signed margins ≥ 1 − ξ and ξ ≥ 0.'});
pt=uitextarea(mg,'Editable','off','Value',{'Six simulated qubits encode the 64 brightness values in each block.'});
pg=uigridlayout(perf,[3 2]); pg.RowHeight={36,'1x','1x'};
uibutton(pg,'Text','Compare current image at nine levels','ButtonPushedFcn',@compare);
ptext=uilabel(pg,'Text',''); axs=gobjects(1,4); for k=1:4, axs(k)=uiaxes(pg); end
addHint(g,'The left image is the input and the right is the decoded file. Fewer bits per pixel saves space. Higher PSNR and SSIM indicate a closer match.');
addHint(l,'Each map color is a compression strength. In the table, rows are the measured best settings and columns are SVM predictions. Diagonal counts are correct.');
addHint(mg,'Left: each negative margin is a wrong binary prediction. Right: brighter cells have greater contrast between paired neighboring pixels.');
addHint(pg,'Compare at similar bits per pixel. Higher PSNR and SSIM indicate better fidelity, a larger raw-size ratio means more compression, and a lower time means faster encoding.');
addHint(cg,'Each color marks blocks with similar features. Read the gradient energy column to see which group has the strongest changes in brightness.');
addHint(sg,'The largest number in a row gives the most frequent right neighbor. A large diagonal value means the same cluster often continues to the right.');
addHint(rg,'Read the three rows for this block. The smallest cost wins. Increasing lambda gives saving bits more weight in that decision.');
restoration_panel(uitab(tabs,'Title','Photo restoration'));
tmp=[tempname '.soc']; fig.CloseRequestFcn=@finish; stream=''; paired=false; enc=NaN; model=[]; original=[];
refreshModel();
info.Text='Upload a photo to analyze, cluster, compare and save all results for that image.';
status.Text='Waiting for an uploaded image';
    function loadSource(path)
        haveCurrentEncode=false; currentSourcePath=char(path);
        img=read_image(path); original=img; preview(orig,original,'Original');
        themeAReset();
        blockRow.Value=1; blockCol.Value=1;
        blockRow.Limits=[1 max(2,ceil(size(img,1)/8))];
        blockCol.Limits=[1 max(2,ceil(size(img,2)/8))];
        blockRow.Enable=matlab.lang.OnOffSwitchState(size(img,1)>8);
        blockCol.Enable=matlab.lang.OnOffSwitchState(size(img,2)>8);
        blockCost([],[]);
        transitionTable.Data=[]; transitionTable.RowName={}; transitionTable.ColumnName={};
        spatialText.Text='In Clustering, click Cluster image blocks to estimate the probabilities for this image.';
        cla(clusterAx); colorbar(clusterAx,'off'); clusterTable.Data=[];
        clusterStatus.Text='Choose the number of clusters and run k-means on this image.';
        f=dir(path); info.Text=sprintf('%s   |   %d × %d   |   %d channel(s)   |   source file %d bytes', ...
            f.name,size(img,2),size(img,1),size(img,3),f.bytes);
        paired=false; stream=''; cla(recon); cla(mapAx); counts.Text='Compress to view block classes.'; status.Text='Ready';
        model=train_svm_model(original,penalty.Value,level.Value,scale.Value); refreshModel();
        delete(findall(galleryLayout,'Type','axes'));
        draw_six_images(galleryLayout,original,model,level.Value,scale.Value);
        subtitle(galleryLayout,'Compare one edge across all five reconstructions to see which settings preserve fine detail.');
        title(galleryLayout,sprintf('Compression comparison   |   Level %g   |   Scale %g',level.Value,scale.Value));
        tabs.SelectedTab=gallery;
    end
    function settings=currentSettings()
        settings=[];
        if ~isempty(currentSourcePath)
            settings=struct('Path',currentSourcePath,'Level',level.Value,'Scale',scale.Value, ...
                'Clusters',str2double(kInput.Value),'Lambda',penalty.Value);
        end
    end
    function refreshModel()
        if isempty(model), modelText.Text='Model awaiting training'; return; end
        if isnan(model.accuracy)
            modelText.Text=sprintf('Image-specific SVM | %d training blocks | no held-out blocks',numel(model.labels));
        else
            modelText.Text=sprintf('Image-specific SVM | held-out accuracy %.1f%% | %d training blocks', ...
                100*model.accuracy,numel(model.labels));
        end
        tableUI.Data=model.confusion;
    end
    function ensureModel()
        assert(~isempty(original),'Upload a photo first.');
        if isempty(model), model=train_svm_model(original,penalty.Value,level.Value,scale.Value); refreshModel(); end
    end
    function upload(~,~)
        [f,d]=uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff','Images'});
        if isequal(f,0), return; end
        try, loadSource(fullfile(d,f)); catch e, alert(e); end
    end
    function train(~,~)
        try, assert(~isempty(original),'Upload a photo first.'); model=train_svm_model(original,penalty.Value,level.Value,scale.Value); refreshModel(); catch e, alert(e); end
    end
    function encode(~,~)
        try
            if ismember(string(method.Value),["SVM","Selective SVM"]), ensureModel(); end
            [map,enc,review]=compress_image(original,tmp,method.Value,level.Value,scale.Value,model);
            haveCurrentEncode=true; stream=tmp; paired=true; decode([],[]);
            if strcmp(method.Value,'Selective SVM')
                status.Text=sprintf('%s   |   Reviewed %d of %d blocks; changed %d decisions',status.Text,review.checked,numel(map),review.changed);
            end
        catch e, alert(e); end
    end
    function decode(button,~)
        try
            assert(~isempty(stream),'Select or compress a file first.');
            [b,map,dec]=decompress_image(stream); preview(recon,b,'Reconstruction');
            if isempty(map)
                cla(mapAx); counts.Text='Lossless PNG preserves the loaded pixels without block quantization.';
            else
                showMap(map);
            end
            f=dir(stream); text=sprintf('%d bytes   |   %.2f bpp   |   raw ratio %.2f   |   decode %.3f s', ...
                f.bytes,8*f.bytes/(size(b,1)*size(b,2)),numel(b)/f.bytes,dec);
            if paired
                m=image_metrics(original,b,stream,enc,dec);
                text=sprintf('%s   |   PSNR %.2f dB   |   SSIM %.3f   |   MSE %.6g   |   encode %.3f s', ...
                    text,m.PSNR,m.SSIM,m.MSE,enc);
            else
                text=[text ' | MSE unavailable: no verified original for this stream.'];
            end
            if ~isempty(button)
                source=stream;
                if strcmp(stream,tmp), source=currentSourcePath; end
                [~,stem]=fileparts(source);
                out=fullfile(root,'results','reconstructed',sprintf('%s_decoded_%s.png',stem,char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))));
                imwrite(b,out);
                text=sprintf('%s | Saved: %s',text,out);
            end
            status.Text=text;
        catch e, alert(e); end
    end
    function showMap(map)
        imagesc(mapAx,map,[1 3]); axis(mapAx,'image'); colormap(mapAx,[.1 .35 .65;.98 .72 .26;.78 .23 .27]);
        title(mapAx,'8 × 8 block assignments'); counts.Text=sprintf('Strong (blue) %d   |   Moderate (gold) %d   |   Light (red) %d', ...
            nnz(map==1),nnz(map==2),nnz(map==3));
    end
    function openStream(~,~)
        [f,d]=uigetfile('*.soc'); if isequal(f,0), return; end
        stream=fullfile(d,f); paired=haveCurrentEncode && same_stream(stream,tmp); cla(recon); cla(mapAx); counts.Text='Decompress to view block classes.';
        status.Text=['Selected ' f '  |  press Decompress'];
    end
    function saveStream(~,~)
        try
            assert(isfile(stream),'Select or compress a file first.');
            [f,d]=uiputfile('*.soc','Save compressed stream'); if isequal(f,0), return; end
            copyfile(stream,fullfile(d,f)); status.Text=['Saved ' f];
        catch e, alert(e); end
    end
    function qp(~,~)
        try
            ensureModel(); r=svm_qp_demo(model,qa);
            if isfield(r,'isImageRun') && r.isImageRun
            qt.Value={sprintf('Image-derived QP status: %s',char(r.status)), ...
                    sprintf('Primal objective: %.6g | held-out image-block accuracy: %.3f',r.objective,r.accuracy), ...
                    sprintf('Maximum feasibility violation: %.3g | margin width: %.3g',r.primal,r.width)};
            else
                qt.Value={sprintf('0.5 ||w||² + C Σξ = %.4f   |   support vectors %d',r.objective,r.supportCount), ...
                    sprintf('Training accuracy %.1f%%   |   margin width %.3f   |   min signed margin %.3f',100*r.accuracy,r.width,r.minFunctionalMargin), ...
                    sprintf('KKT: primal %.2g, dual %.2g, stationarity %.2g, complementarity %.2g',r.primal,r.dual,r.stationarity,r.complementarity)};
            end
        catch e, alert(e); end
    end
    function quantumView(~,~)
        try, map=quantum_edges(original,pa); pt.Value={sprintf('Mean edge probability across blocks: %.4f',mean(map(:)))}; catch e, alert(e); end
    end
    function compare(~,~)
        try
            ptext.Text='Running comparisons…'; drawnow; ensureModel();
            [~,pairs]=compare_methods(original,model,axs,[],scale.Value,@compareProgress);
            ptext.Text=sprintf('%d/%d pairs within 10%% bitrate',nnz(pairs.Within10Pct),height(pairs));
        catch e, ptext.Text='Comparison interrupted'; alert(e); end
    end
    function compareProgress(done,total,compareMethod,compareLevel)
        ptext.Text=sprintf('Rate comparison %d/%d | %s | level %g',done,total,char(compareMethod),compareLevel);
    end
    function clusterView(~,~)
        try
            [groups,profile,cost]=cluster_blocks(original,str2double(kInput.Value));
            n=height(profile);
            imagesc(clusterAx,groups,[.5 n+.5]); axis(clusterAx,'image');
            colormap(clusterAx,lines(n)); barKey=colorbar(clusterAx); barKey.Ticks=1:n;
            title(clusterAx,'Cluster membership by 8 × 8 block');
            clusterTable.Data=profile;
            [prob,observations]=spatial_transitions(groups);
            names=cellstr(compose('Cluster %d',1:n));
            transitionTable.Data=prob; transitionTable.RowName=names; transitionTable.ColumnName=names;
            totals=sum(observations,2); [total,i]=max(totals);
            if total==0
                spatialText.Text='This image has only one block column, so no right-neighbor pairs are available.';
            else
                [hits,j]=max(observations(i,:));
                spatialText.Text=sprintf('From cluster %d, cluster %d is a most frequent right neighbor (%d of %d pairs, %.1f%%). A NaN row means no outgoing pairs were observed.',i,j,hits,total,100*hits/total);
            end
            clusterStatus.Text=sprintf('%d clusters from %d blocks   |   Within-cluster sum of squares %.2f',n,numel(groups),cost);
        catch e, alert(e); end
    end
    function alert(e), uialert(fig,e.message,'Operation could not finish'); end
    function blockCost(~,~)
        rows=(blockRow.Value-1)*8+(1:8); cols=(blockCol.Value-1)*8+(1:8);
        patch=original(min(rows,size(original,1)),min(cols,size(original,2)),:);
        [id,d]=label_blocks(image_blocks(patch),penalty.Value);
        names=["Strong";"Moderate";"Light"];
        candidateTable.Data=table(names,d.mse',d.bytes',d.bytes'/8,d.cost', ...
            'VariableNames',{'Setting','MSE','Bytes','BitsPerPixel','Cost'});
        preview(blockAx,patch,sprintf('Original block at row %d, column %d',blockRow.Value,blockCol.Value));
        costText.Text=sprintf('Lowest cost: %s (%.2f). Cost = MSE + lambda × bits per pixel. Current-image SVM uses lambda = %g.',names(id),d.cost(id),penalty.Value);
    end
    function settingsChanged(~,~)
        if isempty(original), return; end
        try
            model=train_svm_model(original,penalty.Value,level.Value,scale.Value); refreshModel();
            themeAReset(); blockCost([],[]);
            delete(findall(galleryLayout,'Type','axes'));
            draw_six_images(galleryLayout,original,model,level.Value,scale.Value);
            subtitle(galleryLayout,'Compare one edge across all five reconstructions to see which settings preserve fine detail.');
        title(galleryLayout,sprintf('Uploaded image | Level %g | Scale %g',level.Value,scale.Value));
        catch e, alert(e); end
    end
    function finish(~,~)
        if isfile(tmp), delete(tmp); end
        delete(fig);
    end
end
function preview(ax,img,label)
if size(img,3)==1, imagesc(ax,img,[0 255]); colormap(ax,gray(256)); else, image(ax,img); end
axis(ax,'image'); ax.XTick=[]; ax.YTick=[]; title(ax,label);
end


function addHint(grid,message)
row=numel(grid.RowHeight)+1;
grid.RowHeight=[grid.RowHeight,{50}];
label=uilabel(grid,'Text',message,'WordWrap','on');
label.Layout.Row=row;
if numel(grid.ColumnWidth)>1, label.Layout.Column=[1 numel(grid.ColumnWidth)]; else, label.Layout.Column=1; end
end

function equal=same_stream(first,second)
% Only associate the open file with this photo if its encoded bytes match.
equal=false;
a=dir(first); b=dir(second);
if isempty(a) || isempty(b) || a.bytes~=b.bytes, return; end
fa=fopen(first,'rb'); if fa<0, return; end
guardA=onCleanup(@() fclose(fa));
fb=fopen(second,'rb'); if fb<0, return; end
guardB=onCleanup(@() fclose(fb));
while ~feof(fa)
    if ~isequal(fread(fa,65536,'*uint8'),fread(fb,65536,'*uint8')), return; end
end
equal=true;
end
