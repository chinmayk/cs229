function [L1err,L2err,rankedErr]=evalAvgGradeForUser(activeMatTrain,activeMatTest,...
    K,coeff)

[numActive,numItems] = size(activeMatTrain);

for j=1:numActive
    % average grade for user is sum of all grades known in training matrix
    % divided by number of grades in training matrix
    avgUser = full(sum(activeMatTrain(j,:)) / sum(spones(activeMatTrain(j,:))));
    ind = find(activeMatTest(j,:)>0);
    truePref = full(activeMatTest(j,ind));
    predPref = ones(size(truePref)) * avgUser;
    L2err(j)=mean((predPref-truePref).^2);
    L1err(j)=norm(predPref-truePref,1)/length(predPref);
    rankedErr(j)=rankedEvalCF(predPref,truePref,K,coeff);
end