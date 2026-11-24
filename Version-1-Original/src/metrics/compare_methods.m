function [rates,matched]=compare_methods(img,model,axesList)
% Compare actual encoded files for the same source, including side information.
tmp=[tempname '.soc']; tidy=onCleanup(@() remove_file(tmp)); rates=table();
methods=["Fixed","Rules","SVM","Selective SVM","Exhaustive"];
for method=methods
    for level=[.35 .55 .8 1 1.4 2 3 4.5 7]
        [~,enc]=compress_image(img,tmp,method,level,1,model);
        [out,~,dec]=decompress_image(tmp);
        row=image_metrics(img,out,tmp,enc,dec); row.Method=method; row.Level=level;
        rates=[rates;row]; %#ok<AGROW>
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
if nargin<3, return; end
fields=["PSNR","SSIM","Ratio","Encode_s"]; units=["PSNR (dB)","SSIM","Raw / encoded bytes","Encoding time (s)"];
for k=1:4
    ax=axesList(k); cla(ax); hold(ax,'on');
    for method=methods
        rows=sortrows(rates(rates.Method==method,:),'BPP');
        plot(ax,rows.BPP,rows.(fields(k)),'-o','DisplayName',method);
    end
    hold(ax,'off'); xlabel(ax,'Actual bits per pixel'); ylabel(ax,units(k)); grid(ax,'on');
    legend(ax,'Location','best');
end
end
function remove_file(path)
if isfile(path), delete(path); end
end
