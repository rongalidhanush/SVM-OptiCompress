function T=dct_basis()
persistent basis
if isempty(basis)
    D=cos((0:7)'*((2*(0:7)+1)*pi/16))/2; D(1,:)=D(1,:)/sqrt(2); basis=kron(D,D);
end
T=basis;
end

