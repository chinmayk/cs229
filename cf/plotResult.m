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

plot(x, y1, '-mo', 'Color', 'blue', 'MarkerSize',5, 'MarkerFaceColor','blue');
hold on
plot(x, y2, '-mo', 'Color', 'red', 'MarkerSize',5, 'MarkerFaceColor','red');

hold off
fprintf('%f, ', y1);
fprintf('\n');
fprintf('%f, ', y2);