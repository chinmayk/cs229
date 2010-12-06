% specify either S.numUsersLimit and a filename or a sparse matrix
% preloaded into S.userMat:
%   S.numUsersLimit=300;
%   S.dataFilename = 'grades.txt';
S.userMat = userMat;

S.activePerc=0.5;
S.percReported=0.5;
S.percPredicted=0.5;
S.crossValNum=1;
S.K=10;
S.coeff=0.5;
S.sigma=0.7;
S.numValues=6;

[sim1Err,sim2Err,PDErr,avgErr,constErr,S]=eachMovieComparison(S);
save experiment1 sim1Err sim2Err PDErr avgErr constErr S;

tp=1;
disp([mean(sim1Err{1}(tp,:)) mean(sim2Err{1}(tp,:)) ...
        mean(PDErr{1}(tp,:)) mean(avgErr{1}(tp,:)) mean(constErr{1}(tp,:)) ]);
tp=2;
disp([mean(sim1Err{1}(tp,:)) mean(sim2Err{1}(tp,:)) ...
        mean(PDErr{1}(tp,:)) mean(avgErr{1}(tp,:)) mean(constErr{1}(tp,:)) ]);
tp=3;
disp([mean(sim1Err{1}(tp,:)) mean(sim2Err{1}(tp,:)) ...
        mean(PDErr{1}(tp,:)) mean(avgErr{1}(tp,:)) mean(constErr{1}(tp,:)) ]);
