function q=quant_steps(classes,level,scale)
validateattributes(level,{'numeric'},{'real','scalar','finite','>=',0.1,'<=',8});
validateattributes(scale,{'numeric'},{'real','scalar','finite','>=',0.25,'<=',4});
[u,v]=ndgrid(0:7);
base=4+1.6*(u+v)+.32*(u+v).^2;
factor=[2.4 1 .42];
q=max(1,round(base(:)*(level*scale*reshape(factor(classes),1,[]))));
end
