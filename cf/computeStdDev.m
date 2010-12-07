function [stddev, means] = computeStdDev(userMat)

[numStudents, numCourses] = size(userMat);
stddev = zeros(numStudents, 1);
means = zeros(numStudents, 1);
for i = 1:numCourses
    stddev(i) = full(std(userMat(:, userMat(:, i) > 0)));
    means(i) = full(mean(userMat(:, userMat(:, i) > 0)));
end

stddev = mean(stddev(stddev > 0));
means = mean(means(means > 0));
