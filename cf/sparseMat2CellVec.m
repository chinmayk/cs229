function cellVec=sparseMat2CellVec(sparseMat)
% function cellVec=sparseMat2CellVec(sparseMat)
%
% converts a sparse matrix S to a cell vector c in the
% following manner:
%
% c{i} represents the non-zero entries in S(i,:) in an nnz(i)x2 table

for i=1:size(sparseMat,1),
    ind=find(sparseMat(i,:)>0);
    cellVec{i,1}=[ind' full(sparseMat(i,ind)')];
end