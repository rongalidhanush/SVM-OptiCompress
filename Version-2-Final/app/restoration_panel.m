function restoration_panel(tab)
g=uigridlayout(tab,[5 2]); g.RowHeight={46,46,42,'1x',50};
openButton=uibutton(g,'Text','Open ordinary photo','ButtonPushedFcn',@loadPhoto);
openButton.Layout.Row=1; openButton.Layout.Column=1;
widthPanel=uigridlayout(g,[1 2]); widthPanel.Padding=0; widthPanel.ColumnWidth={120,'1x'};
widthPanel.Layout.Row=1; widthPanel.Layout.Column=2;
uilabel(widthPanel,'Text','Blur width (pixels)');
sigma=uispinner(widthPanel,'Limits',[.4 8],'Step',.2,'Value',1.2,'ValueChangedFcn',@invalidate);
stepPanel=uigridlayout(g,[1 2]); stepPanel.Padding=0; stepPanel.ColumnWidth={115,'1x'};
stepPanel.Layout.Row=2; stepPanel.Layout.Column=1;
uilabel(stepPanel,'Text','Iterations');
steps=uispinner(stepPanel,'Limits',[1 40],'Step',1,'RoundFractionalValues','on','Value',16,'ValueChangedFcn',@invalidate);
go=uibutton(g,'Text','Reconstruct photo','Enable','off','ButtonPushedFcn',@restore);
go.Layout.Row=2; go.Layout.Column=2;
saveButton=uibutton(g,'Text','Save reconstruction as PNG','Enable','off','ButtonPushedFcn',@savePhoto);
saveButton.Layout.Row=3; saveButton.Layout.Column=[1 2];
left=uiaxes(g); left.Layout.Row=4; left.Layout.Column=1;
right=uiaxes(g); right.Layout.Row=4; right.Layout.Column=2;
note=uilabel(g,'Text','Open a blurry photo, then reconstruct it. Start with 16 iterations. Reduce iterations or blur width if noise or bright outlines appear.','WordWrap','on'); note.Layout.Row=5; note.Layout.Column=[1 2];
input=[]; output=[];
    function loadPhoto(~,~)
        [f,d]=uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp','Image files'});
        if isequal(f,0), return; end
        try
            input=read_image(fullfile(d,f)); invalidate(); displayPhoto(left,input,'Input photo'); go.Enable='on';
        catch err, uialert(ancestor(tab,'figure'),err.message,'Could not load photo'); end
    end
    function invalidate(varargin)
        output=[]; saveButton.Enable='off'; cla(right);
    end
    function restore(~,~)
        try
            output=restore_photo(input,sigma.Value,steps.Value); displayPhoto(right,output,'Richardson-Lucy reconstruction'); saveButton.Enable='on';
        catch err, uialert(ancestor(tab,'figure'),err.message,'Restoration failed'); end
    end
    function savePhoto(~,~)
        [f,d]=uiputfile('*.png','Save restored photo','restored.png');
        if ~isequal(f,0), imwrite(output,fullfile(d,f),'png'); end
    end
end
function displayPhoto(ax,img,caption)
if size(img,3)==1, imagesc(ax,img,[0 255]); colormap(ax,gray(256)); else, image(ax,img); end
axis(ax,'image','off'); title(ax,caption);
end
