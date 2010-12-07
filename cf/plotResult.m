function plotResult(sim1Err, sim2Err)

numPoints = length(sim1Err);
x = 1:numPoints;
y1 = 1:numPoints;
y2 = 1:numPoints;
for i = 1:numPoints
    y1(i) = sim1Err{i}(1);
    y2(i) = sim1Err{i}(2);
end

hold off
scatter(x, y1, 5, [0, 0, 1], 'filled');
hold on
scatter(x, y2, 5, [1, 0, 0], 'filled');
hold off

mean(y2 - y1)