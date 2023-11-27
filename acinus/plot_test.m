% Draw cell
%{
figure()
hold on

title(strcat('Cell ', int2str(cell_no)))
trisurf(apicaltrilist, p(:, 1), p(:, 2), p(:, 3), 'facecolor', 'red', 'FaceAlpha', 0.5)
trisurf(basaltrilist, p(:, 1), p(:, 2), p(:, 3), 'facecolor', 'blue', 'FaceAlpha',0.1)
set(gca,'FontSize',14)

% Find 'middle axis' of cell
apical_point_idx = dist_to_apical < 0.6;
apical_points = p(apical_point_idx, :);

basal_point_idx = dist_to_basal < 0.1; % Only get first point index for each triangle
basal_points = p(basal_point_idx, :);

% mean basal and apical points are determining points for 'middle axis'
mean_apical = mean(apical_points);
mean_basal = mean(basal_points);

% Construct line
n = (mean_basal - mean_apical) / norm(mean_basal - mean_apical);
perp_dist = zeros(np, 1);
for i=1:np
    point = p(i, :);
    axis_to_point = (point - mean_apical) - dot(point - mean_apical, n)*n;
    perp_dist(i) = norm(axis_to_point);
end

iaxis_points = perp_dist < 0.3;

%You simply need to project vector AP onto vector AB, then add the resulting vector to point A.
%Here is one way to compute it:
%A + dot(AP,AB) / dot(AB,AB) * AB
ap = p(iaxis_points,:);
nap = length(ap);
ap_dist = zeros(nap,1);
AB = mean_apical - mean_basal;
for i=1:nap
    P = ap(i, :);
    AP = mean_apical - P;
    ap_dist(i) = dot(AP,AB) / dot(AB,AB);
end
[ap_dist,order]=sort(ap_dist);
ap = ap(order, :);

X = ap(:, 1);
Y = ap(:, 2);
Z = ap(:, 3);

%{
X = p(axis_points, 1);
Y = p(axis_points, 2);
Z = p(axis_points, 3);
[X,order]=sort(X);   % sort the points by the X coordinate so that they can be selected more easily in a regular sequence along the line.
Y=Y(order);
Z=Z(order);
%}

scatter3(X,Y,Z,200,'m','MarkerEdgeColor','m','MarkerFaceColor','b')  % don't plot all the points, only a few
scatter3(X(1),Y(1),Z(1),200,'g','MarkerEdgeColor','g','MarkerFaceColor','g')  % don't plot all the points, only a few
scatter3(X(end),Y(end),Z(end),200,'r','MarkerEdgeColor','r','MarkerFaceColor','r')  % don't plot all the points, only a few
scatter3(p(:,1),p(:,2),p(:,3),10,'g')
%skip = 3;
%scatter3(X(1:skip:end),Y(1:skip:end),Z(1:skip:end),200,'r','MarkerEdgeColor','r','MarkerFaceColor','r')  % don't plot all the points, only a few

% Plot calcium and IP3 at each point along axis

figure()
ca_solutions = sol(1:6233,:);
plot(tim, ca_solutions)
title('Calcium concentrations')

figure()
%ca_solutions = sol(iaxis_points,:);
%ca_solutions = ca_solutions(order,:);
%%ca_solutions = ca_solutions(1:skip:end,:);
%%ba_solution = mean(sol(basal_point_idx,:));
ca_solutions = sol(1:20:6233,:);
plot(tim, ca_solutions)
title('Calcium concentrations SKIP')

figure()
ca_solutions = sol(iaxis_points,:);
%ca_solutions = ca_solutions(order,:);
plot(tim, ca_solutions)
title('Calcium concentrations through middle of cell')
%xlim([0,100])

%figure()
%plot(tim, ca_solutions)
%title('Calcium concentrations apical & basal')
%}

figure()
hold on
ca_solutions = sol(1:6233,4001:12001);
ptim = tim(1:8001);
ca_avg = mean(ca_solutions,2);
[ca_avg,order]=sort(ca_avg);
ca_solutions = ca_solutions(order,:);

%plot(ptim, ca_solutions(1:600:end,:),'color','#404040','LineWidth',1)
%plot(ptim, ca_solutions(1,:),'r','LineWidth',2)
%plot(ptim, ca_solutions(end,:),'b','LineWidth',2)
plot(ptim, ca_solutions(1:600:end,:))
plot(ptim, ca_solutions(end,:))


title('Calcium concentrations')
hold off
