function [L1err,L2err,rankedErr]=evalMemBasedEachMovie(activeMatTrain,...
    activeMatTest,otherMat,simMethod,K,coeff)
% function [L1err,L2err,rankedErr]=evalMemBasedEachMovie(activeMatTrain,...
%    activeMatTest,otherMat,simMethod,K,coeff)
%
% Train and tests a memory based CF model with respect to predicting
% the preferences of the active user given in activeMatTest based on
% the prediction of the active user given in activeMatTrain and the
% prediction of the other users in otherMat. 
%
% Guy Lebanon, August 2003.

% transform training data to cell arrays for mex file call
activeCellVecTrain = sparseMat2CellVec(activeMatTrain);
otherCellVec = sparseMat2CellVec(otherMat);
[numActive,numItems] = size(activeMatTrain);

% Obtain similarity matrices for memory base prediction
simMat=memoryBasedModels(activeCellVecTrain,otherCellVec,simMethod,-1,numItems);

% Predict preferences for each active user and evaluate the predictions
for j=1:numActive,
    ind=find(activeMatTrain(j,:)>0);
    activeUserMean=full(mean(activeMatTrain(j,ind)));
    predPref=predictPreferenceMemBased(simMat(j,:), otherMat, activeUserMean);
    ind = find(activeMatTest(j,:)>0);
    predPref = predPref(ind);
    truePref = full(activeMatTest(j,ind));
    L2err(j)=mean((predPref-truePref).^2);
    L1err(j)=norm(predPref-truePref,1)/length(predPref);
    rankedErr(j)=rankedEvalCF(predPref,truePref,K,coeff);
end