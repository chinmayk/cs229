% specify either S.numUsersLimit and a filename or a sparse matrix
% preloaded into S.userMat:

%S.numUsersLimit = 100000;
%S.dataFilename = 'grades.txt';
%if isfield(S, 'userMat')
%    S = rmfield(S, 'userMat');
%end

S.userMat = userMat;

S.activePerc=0.1;
S.percentToPredict=0.1;
S.crossValNum=10;
S.K=10;
S.coeff=0.5;
S.sigma=0.7;
S.numValues=14;

% rather than use percentage of courses to predict, we can just set the
% numbers here.  CoursesToTrain = max(n - coursesToPredict, min(n - 1, 5))
%   -- either all courses minus 3, unless that's less than 5, in which case
%      we use as many as we courses as we can up to 5.
S.minCoursesToTrainWith = 5; % try to have at least 5 courses per student known
S.coursesToPredict = 3; % try to predict 3 courses for each student


% for predicting only for one course:
S.courseIDMap = courseIDMap; % mapping of IDs to course indices
courses = [1738, 3634, 6107, 10853, 12688, 17316, 20197, 21837, 23805, 31075, 31632, 1962, 6107, 16796, 21691, 23092, 23849, 29783];
S.courseID = courses(2);
S.maxIter = 50;

[sim1Err,sim2Err,PDErr,avgErr,constErr,S]=eachMovieComparison(S);
save experiment1 sim1Err sim2Err PDErr avgErr constErr S;

disp([mean(cell2mat(sim1Err)')', mean(cell2mat(sim2Err)')', mean(cell2mat(avgErr)')', mean(cell2mat(constErr)')'])
