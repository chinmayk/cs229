function [sim1Err,sim2Err,PDErr,avgErr,constErr,S]=eachMovieComparison(S)

if isfield(S, 'userMat')
    userVoteMat = S.userMat;
else
    userVoteMat = loadDataFile(S.dataFilename, S.numUsersLimit);
end

[S.numUsers,S.numItems]=size(userVoteMat);
S.numActive = floor(S.numUsers * S.activePerc);
S.numOther = S.numUsers - S.numActive;
activeMatTrain=sparse(S.numActive,S.numItems);
activeMatTest=sparse(S.numActive,S.numItems);

for i=1:S.crossValNum,
    % randomly split the into active and other users
    [activeMat,otherMat]=splitUsers(userVoteMat, S.numActive,S.numOther);
    clear userVoteMat;

    % For each active user, split the items into reported and predicted
    activePat=spones(activeMat); % activeMat with all non-zero entries == 1
    
    % student on rows, courses on cols; 
    % sum(activePat, 2) == number of courses for each student
    % numReported -- how many courses we should consider known
    % numPredicted -- how many courses we should try to predict
    numReported=full(floor(sum(activePat,2) * S.percPredicted)); 
    numPredicted=sum(activePat,2)-numReported;
    clear activePat;    
    for j=1:S.numActive,
        ind=find(activeMat(j,:)>0);
        % nvu - total number of courses for this student
        % nru - number of courses reported
        % npu - number of courses predicted
        nvu=length(ind);nru=numReported(j);npu=numPredicted(j);
        randPerm=randperm(length(ind));
        activeMatTrain(j,ind(randPerm(1:nru)))=activeMat(j,ind(randPerm(1:nru)));
        activeMatTest(j,ind(randPerm(nru+1:nvu)))=...
            activeMat(j,ind(randPerm(nru+1:nvu)));
    end

    % Perform training and testing of the different models
    [err1,err2,err3]=evalMemBasedEachMovie(activeMatTrain,...
        activeMatTest,otherMat,1,S.K,S.coeff);
    sim1Err{i}=[err1;err2;err3];
    [err1,err2,err3]=evalMemBasedEachMovie(activeMatTrain,...
        activeMatTest,otherMat,2,S.K,S.coeff);
    sim2Err{i}=[err1;err2;err3]; 
    [err1,err2,err3]=evalPDEachMovie(activeMatTrain,...
        activeMatTest,otherMat,S.K,S.coeff,S.sigma,S.numValues);
    PDErr{i}=[err1;err2;err3];
    [err1,err2,err3]=evalAvgEachMovie(activeMatTrain,activeMatTest,...
        S.K,S.coeff);
    avgErr{i}=[err1;err2;err3];
    [err1,err2,err3]=evalConstEachMovie(activeMatTrain,activeMatTest,...
        S.numValues,S.K,S.coeff);
    constErr{i}=[err1;err2;err3];
end