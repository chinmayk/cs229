function [sim1Err,sim2Err,PDErr,avgErr,constErr,S]=eachMovieComparison(S)

% essentially an enum
ABSOLUTE = 1; PERCENTAGE = 2;

% how do we choose the number of courses to reserve for testing?
METHOD = ABSOLUTE;
%METHOD = PERCENTAGE;

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
    
    % For each active user, split the items into reported and predicted
    activePat=spones(activeMat); % activeMat with all non-zero entries == 1
    
    % student on rows, courses on cols; 
    % sum(activePat, 2) == number of courses for each student
    % numReported -- how many courses we should consider known
    % numPredicted -- how many courses we should try to predict
    if (METHOD == PERCENTAGE)
        numReported=full(floor(sum(activePat,2) * (1 - S.percentToPredict)));
        numPredicted=sum(activePat,2)-numReported;
    else
        totalCourses = sum(activePat,2);
        numReported = max(totalCourses - S.coursesToPredict, min(totalCourses - 1, S.minCoursesToTrainWith));
        numPredicted = totalCourses - numReported;
    end
    
    % must always have at least one example per user
    noTraining = (numReported == 0);
    numPredicted(noTraining) = numPredicted(noTraining) - 1;
    numReported(noTraining) = 1;
    
    clear activePat;
    
    total_nru = 0;
    total_npu = 0;
    for j=1:S.numActive,
        ind=find(activeMat(j,:)>0);
        % nvu - total number of courses for this student
        % nru - number of courses reported
        % npu - number of courses predicted
        nvu=length(ind);nru=numReported(j);npu=numPredicted(j);
        
        total_nru = total_nru + nvu;
        total_npu = total_npu + npu;
        randPerm=randperm(length(ind));
        activeMatTrain(j,ind(randPerm(1:nru)))=activeMat(j,ind(randPerm(1:nru)));
        activeMatTest(j,ind(randPerm(nru+1:nvu)))=...
            activeMat(j,ind(randPerm(nru+1:nvu)));
    end
    
    fprintf('separated training and testing data:\n\t%d/%d active/test users\t%d/%d active/test course sample points\n', S.numActive, S.numOther, total_nru, total_npu);

    % Perform training and testing of the different models
    [err1, err2, err3] = evalMemBasedEachMovie(activeMatTrain,...
        activeMatTest,otherMat,1,S.K,S.coeff);
    fprintf('memory based (correlation) done:\n\t%f\t%f\t%f\n', mean(err1), mean(err2), mean(err3));
    
    sim1Err{i}=[err1;err2;err3];
    [err1,err2,err3]=evalMemBasedEachMovie(activeMatTrain,...
        activeMatTest,otherMat,2,S.K,S.coeff);
    fprintf('memory based (similarity) done:\n\t%f\t%f\t%f\n', mean(err1), mean(err2), mean(err3));
    
    sim2Err{i}=[err1;err2;err3];
    
    PDErr{i} = 0;
    %[err1,err2,err3]=evalPDEachMovie(activeMatTrain,...
    %    activeMatTest,otherMat,S.K,S.coeff,S.sigma,S.numValues);
    %
    % sprintf('PD done: %f\t%f\t%f', err1, err2, err3); 
    % PDErr{i}=[err1;err2;err3];
    
    [err1,err2,err3]=evalAvgEachMovie(activeMatTrain,activeMatTest,...
        S.K,S.coeff);
    avgErr{i}=[err1;err2;err3];
    fprintf('using student average:\n\t%f\t%f\t%f\n', mean(err1), mean(err2), mean(err3));
    
    [err1,err2,err3]=evalConstEachMovie(activeMatTrain,activeMatTest,...
        S.numValues,S.K,S.coeff);
    constErr{i}=[err1;err2;err3];
    fprintf('using course average:\n\t%f\t%f\t%f\n', mean(err1), mean(err2), mean(err3));
end
