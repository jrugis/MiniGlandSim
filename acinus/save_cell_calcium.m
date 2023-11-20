
figure()
hold on;
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
    %perp_dist(i) = norm(cross(point - mean_apical, n))/norm(n);
end

axis_points = perp_dist < 0.4;
%axis_points = perp_dist < 0.2;
%skip = 10;
X = p(axis_points, 1);
Y = p(axis_points, 2);
Z = p(axis_points, 3);

%%%%%% c++ opengl
%vec3 target_dir = normalise( vector );
%float rot_angle = acos( dot_product(target_dir,z_axis) );
%if( fabs(rot_angle) > a_very_small_number )
%{
%    vec3 rot_axis = normalise( cross_product(target_dir,z_axis) );
%    glRotatef( rot_angle, rot_axis.x, rot_axis.y, rot_axis.z );
%}
%%%%%%

[X,order]=sort(X);   % sort the points by the X coordinate so that they can be selected more easily in a regular sequence along the line.
Y=Y(order);
%[Y,order]=sort(Y);   % sort the points by the X coordinate so that they can be selected more easily in a regular sequence along the line.
%X=X(order);
Z=Z(order);
skip = 1;
scatter3(X(1:skip:end),Y(1:skip:end),Z(1:skip:end),50,'g','MarkerEdgeColor','k','MarkerFaceColor','r')  % don't plot all the points, only a few
skip = floor(length(X)/8);
scatter3(X(1:skip:end),Y(1:skip:end),Z(1:skip:end),200,'g','MarkerEdgeColor','k','MarkerFaceColor','g')  % don't plot all the points, only a few
scatter3(p(:,1),p(:,2),p(:,3),100);
scatter3(X(1),Y(1),Z(1),300,'g','MarkerEdgeColor','k','MarkerFaceColor','b');
scatter3(X(end),Y(end),Z(end),300,'g','MarkerEdgeColor','k','MarkerFaceColor','b');
hold off;
