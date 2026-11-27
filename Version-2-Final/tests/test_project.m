function tests=test_project()
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.TestData.root=setup(); t.TestData.model=train_svm_model();
t.TestData.tmp=tempname(); mkdir(t.TestData.tmp);
end
function teardownOnce(t)
rmdir(t.TestData.tmp,'s');
end
function testPartitionAndFeatures(t)
img=reshape(uint8(1:99),9,11); [b,g]=image_blocks(img);
verifyEqual(t,g,[2 2]); verifyEqual(t,reshape(b(:,1),8,8),double(img(1:8,1:8)));
verifyEqual(t,b(end,end),double(img(end,end)));
X=block_features(b); verifySize(t,X,[4 7]); verifyEqual(t,X(:,3),X(:,2).^2,'AbsTol',1e-10);
verifyEqual(t,block_features(128*ones(64,1)),[128 0 0 0 0 0 0],'AbsTol',1e-10);
verifyEqual(t,sort(zig_order()),(1:64)'); verifyEqual(t,dct_basis()*dct_basis()',eye(64),'AbsTol',1e-12);
end
function testLearning(t)
m=t.TestData.model; verifyEmpty(t,intersect(m.trainingFiles,m.testingFiles));
verifyEqual(t,unique(m.labels),(1:3)'); verifyEqual(t,size(m.confusion),[3 3]);
verifyEqual(t,m.accuracy,trace(m.confusion)/sum(m.confusion(:)),'AbsTol',1e-12);
loaded=get_model(t.TestData.root); verifyEqual(t,predict(m.classifier,m.features(1:6,:)),predict(loaded.classifier,m.features(1:6,:)));
[b,~]=image_blocks(read_image(fullfile(t.TestData.root,'datasets','sample_images','scene_12.png')));
[y,d]=label_blocks(b); [~,best]=min(d.mse+32*d.bytes/8,[],2); verifyEqual(t,y,best);
end
function testClustering(t)
flat=uint8(zeros(8)); img=[flat flat+150;flat+150 flat];
[map,profile,cost]=cluster_blocks(img,3);
verifySize(t,map,[2 2]); verifyEqual(t,height(profile),2);
verifyEqual(t,map(1,1),map(2,2)); verifyNotEqual(t,map(1,1),map(1,2));
verifyEqual(t,profile.Blocks,[2;2]); verifyEqual(t,cost,0,'AbsTol',1e-12);
verifyEqual(t,cluster_blocks(uint8(127),3),1);
end
function testOptimization(t)
r=svm_qp_demo(t.TestData.model); verifyLessThan(t,max([r.primal r.dual r.stationarity r.complementarity]),1e-4);
verifyGreaterThan(t,r.supportCount,0); verifyGreaterThan(t,r.width,0);
verifyEqual(t,r.objective,.5*norm(r.w)^2+sum(r.slack),'AbsTol',1e-6);
[m,q]=quantum_edges(uint8(ones(24))); verifySize(t,m,[3 3]); verifyEqual(t,height(q),9); verifyEqual(t,max(m(:)),0);
end
function testBlockCostsAndSpatialProbabilities(t)
block=image_blocks(uint8(reshape(mod((1:64)*113,251),8,8)));
[a,quality]=label_blocks(block,0); [b,rate]=label_blocks(block,1024);
verifyEqual(t,quality.cost,quality.mse);
verifyEqual(t,rate.cost,rate.mse+1024*rate.bytes/8);
verifyLessThanOrEqual(t,rate.bytes(b),quality.bytes(a));
verifyEqual(t,label_blocks(block),label_blocks(block,32));
[prob,counts]=spatial_transitions([1 2 2;2 1 3]);
verifyEqual(t,counts,[0 1 1;1 1 0;0 0 0]);
verifyEqual(t,prob(1:2,:),[0 .5 .5;.5 .5 0]);
verifyTrue(t,all(isnan(prob(3,:))));
verifyTrue(t,all(isnan(spatial_transitions([1;2])),'all'));
end
function testCodecAndMetrics(t)
folder=t.TestData.tmp;
for c=[1 3]
    img=uint8(reshape(mod(1:(19*31*c),137),19,31,c));
    for method=["Fixed","Rules","SVM"]
        file=fullfile(folder,'test.soc'); source=fullfile(folder,'source.png'); imwrite(img,source);
        [map,enc]=compress_image(source,file,method,1,1,t.TestData.model); delete(source);
        [b,bmap,dec]=decompress_image(file); verifyEqual(t,map,bmap); verifySize(t,b,size(img));
        m=image_metrics(img,b,file,enc,dec);
        verifyEqual(t,m.Bytes,dir(file).bytes); verifyEqual(t,m.BPP,8*m.Bytes/(19*31));
        verifyEqual(t,m.Ratio,numel(img)/m.Bytes); verifyGreaterThan(t,m.PSNR,17);
        verifyGreaterThan(t,m.SSIM,.7); verifyLessThanOrEqual(t,m.SSIM,1+1e-9);
    end
end
file=fullfile(folder,'tiny.soc'); compress_image(uint8(128),file,'Fixed',1,1);
b=decompress_image(file); verifyEqual(t,b,uint8(128)); verifyEqual(t,dir(file).bytes,31);
m=image_metrics(b,b,file,0,0); verifyEqual(t,m.PSNR,Inf); verifyEqual(t,m.SSIM,1,'AbsTol',1e-12);
end
function testMalformedInput(t)
verifyTrue(t,fails(@() read_image(zeros(2,3,4))));
verifyTrue(t,fails(@() read_image(NaN)));
path=fullfile(t.TestData.tmp,'bad.soc'); compress_image(uint8(128),path,'Fixed',1,1);
f=fopen(path,'rb'); bytes=fread(f,Inf,'*uint8'); fclose(f);
for tail={bytes(1:8),bytes(1:end-1),[bytes;uint8(0)]}
    f=fopen(path,'wb'); fwrite(f,tail{1}); fclose(f);
    verifyTrue(t,fails(@() decompress_image(path)));
end
end
function testSelectiveReview(t)
img=read_image(fullfile(t.TestData.root,'datasets','sample_images','scene_12.png'));
[blocks,grid]=image_blocks(img); model=t.TestData.model;
[base,scores]=predict(model.classifier,block_features(blocks));
sorted=sort(scores,2,'descend'); [~,order]=sort(sorted(:,1)-sorted(:,2));
indices=order(1:floor(numel(base)/4));
expected=base; expected(indices)=label_blocks(blocks(:,indices,:),32,2,.75);
path=fullfile(t.TestData.tmp,'review.soc');
[map,~,review]=compress_image(img,path,'Selective SVM',2,.75,model);
verifyEqual(t,map,reshape(expected,grid));
verifyEqual(t,review.checked,numel(indices)); verifyEqual(t,review.changed,nnz(expected~=base));
[recon,stored]=decompress_image(path); verifySize(t,recon,size(img)); verifyEqual(t,stored,map);
verifyEqual(t,compress_image(img,path,'Exhaustive',2,.75),reshape(label_blocks(blocks,32,2,.75),grid));
end
function yes=fails(action)
try, action(); yes=false; catch, yes=true; end
end
function testDesktop(t)
fig=run_project(); guard=onCleanup(@() close(fig)); drawnow;
verifyTrue(t,isvalid(fig));
tabs=findall(fig,'Type','uitabgroup');
verifyEqual(t,tabs.SelectedTab.Title,'Six-image comparison');
verifyNumElements(t,findall(tabs.SelectedTab,'Type','image'),6);
labels={'Compress','Cluster image blocks','Solve binary SVM with quadprog','Simulate quantum edges','Compare current image at nine levels'};
for i=1:numel(labels)
    btn=findall(fig,'Text',labels{i}); verifyNumElements(t,btn,1);
    feval(btn.ButtonPushedFcn,btn,[]); drawnow;
end
ui=findall(fig,'Type','uilabel'); txt=string({ui.Text});
verifyTrue(t,any(contains(txt,'Reviewed')));
knob=findall(fig,'Tag','RatePenalty'); knob.Value=0; feval(knob.ValueChangedFcn,knob,[]);
tbl=findall(fig,'Tag','BlockCosts'); verifyEqual(t,tbl.Data.Cost,tbl.Data.MSE);
matrix=findall(fig,'Tag','SpatialMatrix'); verifySize(t,matrix.Data,[3 3]);
verifyEqual(t,sum(matrix.Data,2),ones(3,1),'AbsTol',1e-12);
verifyTrue(t,any(contains(txt,'3 clusters from')));
verifyTrue(t,any(contains(txt,'PSNR'))); verifyTrue(t,any(contains(txt,'pairs within')));
ta=findall(fig,'Type','uitextarea');
values=string(join([reshape(ta(1).Value,1,[]) reshape(ta(2).Value,1,[])],' '));
verifyTrue(t,contains(values,'KKT')); verifyTrue(t,contains(values,'descending PC'));
end
