function [L1err,L2err,rankedErr]=evalConstEachMovie(activeMatTrain,activeMatTest,...
    numValues,K,coeff)

[numActive,numItems] = size(activeMatTrain);
meanVal=mean(1:numValues);

for j=1:numActive,
    ind = find(activeMatTest(j,:)>0);
    truePref = full(activeMatTest(j,ind));
    predPref = ones(size(truePref)) * meanVal;
    L2err(j)=mean((predPref-truePref).^2);
    L1err(j)=norm(predPref-truePref,1)/length(predPref);
    rankedErr(j)=rankedEvalCF(predPref,truePref,K,coeff);   
end