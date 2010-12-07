function [ userMat2 ] = sortByUserGradeAvg( userMat )

[numUsers, numCourses] = size(userMat);

avg = ones(numUsers, 1);
for j = 1:numUsers
    avg(j) = full(sum(userMat(j,:)) / sum(spones(userMat(j,:))));
end

[~, I] = sort(avg);
userMat2 = userMat(I, :);

end

