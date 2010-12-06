function userVoteMat=loadDataFile(filename, numUsersLimit)
% Reads the ./Votes.txt file of the eachmovie dataset into
% a sparse matrix, whose rows indicate users and columns 
% indicte movies.
%
% FUNCTION userVoteMat=eachMovieReader(numUsersLimit)
%
% The function terminates after numUsersLimit different 
%      users are read.
%
% Guy Lebanon, June 2003

fid = fopen(filename);
mat=[];
currUser=0;
numUsers=0;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    numLine=sscanf(tline,'%f');
    numLine=transformVote(numLine);
    if currUser~=numLine(1), 
        numUsers=numUsers+1;
        currUser=numLine(1);
    end
    if numUsers>numUsersLimit, break;end
    mat=[mat;numLine(1:3)'];
    if mod(numUsers, 1000) == 0
        numUsers
    end
end
userVoteMat=spconvert(mat);
userVoteMat=compressUserVoteMat(userVoteMat);
fclose(fid);
return

function numLine=transformVote(numLine)
% Transforms the original eachmovie votes
% (0,0.2,0.4,0.6,0.8,1) to the scale 1-6.
switch numLine(3), 
case 0
    numLine(3)=1;
case 0.2
    numLine(3)=2;
case 0.4
    numLine(3)=3;
case 0.6
    numLine(3)=4;
case 0.8
    numLine(3)=5;
case 1
    numLine(3)=6;
end
return

function userVoteMat=compressUserVoteMat(userVoteMat);
% Removes extremely unseen movies (seen by < 3 users)
% and users with few votes 
%
% FUNCTION userVoteMat=compressUserVoteMat(userVoteMat);
%
% Guy Lebanon June 2003

userVoteBinary=spones(userVoteMat);
ind=find(sum(userVoteBinary)<3);
userVoteMat(:,ind)=[];

userVoteBinary=spones(userVoteMat);
ind=find(sum(userVoteBinary,2)<4);
userVoteMat(ind,:)=[];

userVoteBinary=spones(userVoteMat);
ind=find(sum(userVoteBinary)==0);
userVoteMat(:,ind)=[];
return 