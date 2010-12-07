function [ userMat2 ] = sortMatrix( userMat )

[numUsers, numCourses] = size(userMat);

avg = ones(numUsers, 1);
for j = 1:numUsers
    avg(j) = full(sum(userMat(j,:)) / sum(spones(userMat(j,:))));
end

[~, I] = sort(avg);
userMat2 = userMat(I, :);

counts = ones(numCourses, 1);
for j = 1:numCourses
    counts(j) = full(sum(spones(userMat(:, j))));
end
[~, I] = sort(counts);
userMat2 = userMat2(:, I);

end

