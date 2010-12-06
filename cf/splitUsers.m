function [activeMat,otherMat]=splitUsers(userVoteMat, numActive,...
    numOther, activeFileName, otherFileName)
% Randomly splits the sparse matrix userVoteMat into a 
% set of active users and a set of other users.
% If activeFileName and otherFileName are supplied, the function
% saves the two sets as ASCII files with the supplied names.
%
% Guy Lebanon, July, 2003

if numActive+numOther>size(userVoteMat,1),
    disp('Error in splitTrainTest() - numActive+numOther too big!');
    return;
end
rp=randperm(size(userVoteMat,1));
activeInd=rp(1:numActive);
otherInd=rp(numActive+1:numActive+numOther);
activeMat=userVoteMat(activeInd,:);
otherMat=userVoteMat(otherInd,:);
if nargin>3,
    eval(['save ' activeFileName ' activeMat -ASCII;']);
end
if nargin>4,
    eval(['save ' otherFileName '  otherMat  -ASCII;']);
end