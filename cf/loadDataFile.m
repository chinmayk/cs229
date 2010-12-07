function [studentCourseMat, courseIDMap] = loadDataFile(filename, numUsersLimit)
% Reads the ./Votes.txt file of the eachmovie dataset into
% a sparse matrix, whose rows indicate users and columns 
% indicte movies.
%
% FUNCTION studentCourseMat=eachMovieReader(numUsersLimit)
%
% The function terminates after numUsersLimit different 
%      users are read.
%
% Guy Lebanon, June 2003

fid = fopen(filename);
mat = zeros(140934, 3);
currUser=0;
numUsers=0;
i = 0;
while 1
    i = i + 1;
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    numLine=sscanf(tline,'%f');
    if currUser ~= numLine(1)
        numUsers = numUsers+1;
        currUser = numLine(1);
    end
    if numUsers > numUsersLimit, break;end
    mat(i, :) = numLine(1:3);
    if mod(i, 10000) == 0
        fprintf('Loaded %d users, %d lines\n', numUsers, i);
    end
end

studentCourseMat=spconvert(mat);
[studentCourseMat, courseIDMap] = filterMat(studentCourseMat);
fclose(fid);
return

function [studentCourseMat, courseIDMap] = filterMat(studentCourseMat)
% Removes classes with less than 3 grades
% and users with less than 4 classes

numCourses = size(studentCourseMat, 2);
courseIDMap = 1:numCourses;

% remove courses with less than 3 grades
binaryMat = spones(studentCourseMat);
ind = find(sum(binaryMat) < 3);
studentCourseMat(:,ind)=[];
courseIDMap(ind) = [];

% remove users with less than 4 courses
binaryMat = spones(studentCourseMat);
ind = find(sum(binaryMat, 2) < 4);
studentCourseMat(ind,:)=[];

% remove courses with no users
binaryMat = spones(studentCourseMat);
ind = find(sum(binaryMat) == 0);
studentCourseMat(:,ind)=[];
courseIDMap(ind) = [];

return 