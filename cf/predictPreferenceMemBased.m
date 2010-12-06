function predPref=predictPreferenceMemBased(simVec, usersMat, activeAvg)
% Collaborative filtering predictions using memory based methods
% in Breese et al (see equation (1) therein).
%
% FUNCTION predPref=predictPreferenceMemBased(simMat, usersMat, activeAvg)
%
% simVec         simVec(j) contains the similarity of the active user
%                and user j. The similarity may be computed using any
%                of the methods in Breese et al.
% usersMat       A sparse matrix representing the votes of the non-active
%                users (rows) on the different items (columns).
% activeAvg      The mean vote of the active user (scalar).
%
% Guy Lebanon, August 2003.

if size(simVec,2) > 1, simVec=simVec';end

[numUsers,numItems]=size(usersMat);
sumAbs=sum(abs(simVec));
if sumAbs == 0,
    predPref = ones(1,numItems) * activeAvg;
else
    simVec = simVec / sumAbs; % make sure the similarities are normalized
    usersAvg = full(sum(usersMat')./sum(spones(usersMat')));
    usersMat = usersMat - spdiags(usersAvg',0,numUsers,numUsers)*spones(usersMat);
    predPref = sum(spdiags(simVec,0,numUsers,numUsers) * usersMat) + activeAvg;
end