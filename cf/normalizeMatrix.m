function normMat=normalizeMatrix(mat,dim)
% function normMat=normalizeMatrix(mat)
%
% Normalize a (possibly sparse) matrix.
% dim is either 'rows' or 'columns' and
% indicates which is the dimension that is being normalized

[M,N]=size(mat);

if strcmp(dim,'rows'),
    sumVec=sum(mat,2);
    if issparse(mat),
        normMat= spdiags(1./sumVec, 0, M, M) * mat;
    else
        normMat = mat ./ repmat(sumVec,[1 N]);
    end
elseif strcmp(dim,'columns'),
    sumVec=sum(mat);
    if issparse(mat),
        normMat= mat * spdiags(1./(sumVec'), 0, N, N);
    else
        normMat = mat ./ repmat(sumVec,[M 1]);
    end
end    