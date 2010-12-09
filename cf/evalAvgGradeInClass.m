function [L1err,L2err,rankedErr]=evalAvgGradeInClass(activeMatTrain,activeMatTest,otherMat,...
    numValues,K,coeff)

[numActive,numItems] = size(activeMatTrain);
for j = 1:numActive
    % indices of all courses for a user
    ind = find(activeMatTest(j, :) > 0);
    truePref = full(activeMatTest(j,ind));
    predPref = full(sum(otherMat(:, ind) / length(find(otherMat(:, ind) > 0))));
    L2err(j) = mean((predPref-truePref).^2);
    L1err(j) = norm(predPref-truePref,1)/length(predPref);
    rankedErr(j) = rankedEvalCF(predPref,truePref,K,coeff);   
end
