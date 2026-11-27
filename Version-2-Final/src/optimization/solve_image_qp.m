function result=solve_image_qp(binary)
% Solve the binary soft-margin primal from the uploaded image's block split.
if ~binary.Available
    result=struct('Status',"not_applicable",'Reason',string(binary.Reason), ...
        'Objective',NaN,'HeldOutAccuracy',NaN,'MaxViolation',NaN,'Iterations',NaN);
    return
end
X=binary.TrainX; y=binary.TrainY; [n,d]=size(X);
H=spdiags([ones(d,1);0;zeros(n,1)],0,d+n+1,d+n+1);
f=[zeros(d+1,1);ones(n,1)];
A=[-spdiags(y,0,n,n)*X,-y,-speye(n)]; rhs=-ones(n,1);
lb=[-inf(d+1,1);zeros(n,1)];
opts=optimoptions('quadprog','Display','off','ConstraintTolerance',1e-9,'OptimalityTolerance',1e-9);
[z,obj,flag,output]=quadprog(H,f,A,rhs,[],[],lb,[],[],opts);
if flag<=0
    result=struct('Status',"solver_failed",'Reason',string(output.message), ...
        'Objective',NaN,'HeldOutAccuracy',NaN,'MaxViolation',NaN,'Iterations',output.iterations);
    return
end
if isempty(binary.TestY), accuracy=NaN; else
    accuracy=mean((binary.TestX*z(1:d)+z(d+1)>=0)==(binary.TestY>0));
end
violation=max([0;A*z-rhs;-z(d+2:end)]);
result=struct('Status',"optimal",'Reason',"",'Objective',obj, ...
    'HeldOutAccuracy',accuracy,'MaxViolation',violation,'Iterations',output.iterations, ...
    'Weights',z(1:d),'Bias',z(d+1),'Slacks',z(d+2:end));
end
