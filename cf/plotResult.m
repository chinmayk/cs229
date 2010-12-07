function plotResult(sim1Err, sim2Err)

numPoints = length(sim1Err);
x = 1:numPoints;
y1 = 1:numPoints;
y2 = 1:numPoints;
for i = 1:numPoints
    y1(i) = sim1Err{i}(1);
    y2(i) = sim2Err{i}(1);
end

hold off
[y1, ind] = sort(y1);
y2 = y2(ind);

plot(x, y1, 'Color', 'blue');
hold on
plot(x, y2, 'Color', 'red');
scatter(x, y1, 5, [0, 0, 1], 'filled');
scatter(x, y2, 5, [1, 0, 0], 'filled');

hold off

mean(y2 - y1)