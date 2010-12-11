function [L1err,L2err,rankedErr,pErr]=evalAvgGradeInClass(activeMatTrain,activeMatTest,otherMat,...
    numValues,K,coeff)

[numActive,~] = size(activeMatTrain);

L1err = zeros(1, numActive);
L2err = zeros(1, numActive);
rankedErr = zeros(1, numActive);
pErr = 0;
pSum = 0;

for j = 1:numActive
    % indices of all courses for a user
    ind = find(activeMatTest(j, :) > 0);
    truePref = full(activeMatTest(j,ind));
    predPref = full(sum(otherMat(:, ind) / length(find(otherMat(:, ind) > 0))));
    L2err(j) = mean((predPref-truePref).^2);
    L1err(j) = norm(predPref-truePref,1)/length(predPref);
    rankedErr(j) = rankedEvalCF(predPref,truePref,K,coeff);   
    
    pErr = pErr + sum(abs(round(predPref) - truePref) < 2);
    pSum = pSum + length(truePref);
end

pErr = pErr / pSum;
