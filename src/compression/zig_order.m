function order=zig_order()
[r,c]=ndgrid(0:7);
s=r+c; direction=1-2*mod(s,2);
[~,order]=sort(8*s(:)-direction(:).*r(:)/8);
end
