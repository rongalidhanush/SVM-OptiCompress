function [rates,matched]=compare_methods(img,model,axesList,levels,scale,progressFcn)
% Compare actual encoded files for the same source, including side information.
if nargin<4 || isempty(levels), levels=[.35 .55 .8 1 1.4 2 3 4.5 7]; end
if nargin<5 || isempty(scale), scale=1; end
if nargin<6, progressFcn=[]; end
tmp=[tempname '.soc']; tidy=onCleanup(@() remove_file(tmp)); rates=table();
methods=["Fixed","Rules","SVM","Selective SVM","Exhaustive"];
total=numel(methods)*numel(levels); step=0;
for method=methods
    for level=levels
        [~,enc]=compress_image(img,tmp,method,level,scale,model);
        [out,~,dec]=decompress_image(tmp);
        row=image_metrics(img,out,tmp,enc,dec); row.Method=method; row.Level=level;
        rates=[rates;row]; %#ok<AGROW>
        step=step+1;
        if isa(progressFcn,'function_handle')
            progressFcn(step,total,method,level); drawnow limitrate;
        end
    end
end
% Pick the closest measured rate for each alternative to each fixed point.
matched=table(); base=rates(rates.Method=="Fixed",:);
for i=1:height(base)
    for method=methods(2:end)
        cand=rates(rates.Method==method,:);
        [gap,j]=min(abs(cand.BPP-base.BPP(i))/base.BPP(i));
        row=cand(j,:); row.FixedLevel=base.Level(i); row.FixedBPP=base.BPP(i);
        row.FixedPSNR=base.PSNR(i); row.FixedSSIM=base.SSIM(i); row.RateGapPct=100*gap;
        row.Within10Pct=gap<=.10; matched=[matched;row]; %#ok<AGROW>
    end
end
if nargin<3 || isempty(axesList), return; end
fields=["PSNR","SSIM","Ratio","Encode_s"]; units=["PSNR (dB)","SSIM","Raw / encoded bytes","Encoding time (s)"];
titles=["PSNR by bitrate","SSIM by bitrate","Raw size / encoded size by bitrate","Encoding time by bitrate"];
for k=1:4
    ax=axesList(k); cla(ax,'reset'); hold(ax,'on');
    for method=methods
        rows=sortrows(rates(rates.Method==method,:),'BPP');
        plot(ax,rows.BPP,rows.(fields(k)),'-o','MarkerSize',4,'DisplayName',method);
    end
    hold(ax,'off'); title(ax,titles(k)); xlabel(ax,'Actual bits per pixel'); ylabel(ax,units(k)); grid(ax,'on');
    legend(ax,'Location','best');
end
end
function remove_file(path)
if isfile(path), delete(path); end
end
