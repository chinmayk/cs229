function [pred,meanPred]=predictPreferencePD(activeUser, otherUserMat,numValues,sigma)
% Collaborative filtering prediction using personality diagnosis (PD)
% method of Pennock et al. 
%
% activeUser   row vector representing the preferences of the active user
% otherUserMat sparse matrix whose rows represent the preferences of the
%              training set users
% numValues    The number of distinct perference values
% sigma        The variance of the Gaussian that models the preference
% pred(i,j)    the probability of predicting value j for item i.
%
% unknown preferences are recorded as 0 in the input matrices.
%
% Guy Lebanon, August 2003.

if ~exist('sigma'),
    tau=1/2;
else 
    tau=1/(2*sigma^2);
end

[numUsers,numItems] = size(otherUserMat);
ind = find(activeUser>0);
meanActiveUser = mean(activeUser(ind));

% compute normalization terms for the discrete Gaussians
[X,Y]=meshgrid(1:numValues,1:numValues);
ZlogVec=log(sum(exp(-tau * (X-Y).^2)));

% compute prob that the active user is of the same personality as user i
activeMat = (ones(numUsers,1)*sparse(activeUser)) .* spones(otherUserMat);
otherUserMatMod = otherUserMat .* spones(activeMat);
logProbPerson = -tau * full(sum((activeMat-otherUserMatMod).^2,2));
for i=1:numUsers,
    ind = find(otherUserMatMod(i,:)>0);
    if ~isempty(ind),
        logProbPerson(i) = logProbPerson(i) ... %- (sum(ZlogVec(otherUserMatMod(i,ind)))) ...
            - (numItems-length(ind)) * log(numValues);
    else
        logProbPerson(i) = - numItems * log(numValues);
    end
end
probPerson = normalizeLogVecNoUnderflow(logProbPerson);
clear otherUserMatMod activeMat;

% compute posterior probability for predicted value of the different items
pred = ones(numItems,numValues)/numValues;
meanPred=zeros(1,numItems);
for i=1:numItems,
    [predVec,predVecMean]=computePosteriorPD(probPerson,...
        full(otherUserMat(:,i)),numValues,tau);
    pred(i,:) = predVec';
    meanPred(i) = predVecMean;
end