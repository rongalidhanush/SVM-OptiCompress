function img=read_image(input)
if ischar(input) || isstring(input)
    [img,map]=imread(input);
    if ~isempty(map), img=ind2rgb(img,map); end
else
    img=input;
end
assert((isnumeric(img)||islogical(img)) && isreal(img) && ~isempty(img) && ...
    ndims(img)<=3 && ismember(size(img,3),[1 3]),'Expected a grayscale or RGB image.');
if isfloat(img)
    assert(all(isfinite(img(:))) && min(img(:))>=0 && max(img(:))<=1,'Floating images must be in [0,1].');
end
assert(isa(img,'uint8')||isa(img,'uint16')||isfloat(img)||islogical(img),'Unsupported pixel type.');
if isa(img,'uint16'), img=uint8(double(img)/257); elseif ~isa(img,'uint8'), img=uint8(255*double(img)); end
end

