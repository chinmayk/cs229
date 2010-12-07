function [L1err,L2err,rankedErr]=evalPDEachMovie(activeMatTrain,...
    activeMatTest,otherMat,K,coeff,sigma,numValues)

valVec=1:numValues;
for j=1:size(activeMatTest,1),
    [pred,predMean]=predictPreferencePD(activeMatTrain(j,:), otherMat,...
        numValues,sigma);
    ind = find(activeMatTest(j,:)>0);
    predPref = predMean(ind);
    truePref = full(activeMatTest(j,ind));
    L2err(j)=mean((predPref-truePref).^2);
    L1err(j)=norm(predPref-truePref,1)/length(predPref);
    rankedErr(j)=rankedEvalCF(predPref,truePref,K,coeff);
end