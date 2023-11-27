% This is Sam Doak's version of my plotting routine. It does a better job
% of pulling out a line of points from apical to basal, but everything else
% is mostly the same.

% To do the calcium runs, the input has to be the full output file from the run, not just selected
% points.
% To do the secretion runs only, you can use the smaller output file.

clear all
close all
clc

cell_no = 11;
cell_filename = strcat('outputs/long_bicarb_sim_cell_', int2str(cell_no),'_VPLC0.003.mat');
%cell_filename = append('outputs/long_bicarb_sim_cell_', int2str(cell_no),'_VPLC0.001.mat');

plot_calcium_results(cell_filename,cell_no)
plot_secretion(cell_filename,cell_no)

%%
function plot_calcium_results(cell_filename,cell_no)
% Plots Calcium Results. This includes:
%   - Plot of cell showing points where calcium concentration is being
%   graphed
%   - Calcium Plots at each of these points against time
%   - Plot of Average Ca concentration across basal against time


% Draw cell
figure(1)
hold on
load(cell_filename)
volume
%par.volume

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

axis_points = perp_dist < 0.4;
skip = 10;

%You simply need to project vector AP onto vector AB, then add the resulting vector to point A.
%Here is one way to compute it:
%A + dot(AP,AB) / dot(AB,AB) * AB
%his formula will work in 2D and in 3D. In fact it works in all dimensions.

X = p(axis_points, 1);
Y = p(axis_points, 2);
Z = p(axis_points, 3);
%[X,order]=sort(X);   % sort the points by the X coordinate so that they can be selected more easily in a regular sequence along the line.
%Y=Y(order);
[Y,order]=sort(Y);   % sort the points by the X coordinate so that they can be selected more easily in a regular sequence along the line.
X=X(order);
Z=Z(order);
scatter3(X(1:skip:end),Y(1:skip:end),Z(1:skip:end),200,'g','MarkerEdgeColor','k','MarkerFaceColor','g')  % don't plot all the points, only a few

hold off

% Plot calcium and IP3 at each point along axis
ca_solutions = sol(axis_points,:);
ca_solutions = ca_solutions(order,:);
%ca_solutions = ca_solutions(1:skip:end,:);
%ba_solution = mean(sol(basal_point_idx,:));

figure(2)
plot(tim, ca_solutions)
title('Calcium concentrations through middle of cell')
xlim([0,100])

%figure(3)
%plot(tim, ba_solution)
%title('Average calcium concentration across basal membrane')

%writematrix(ca_solutions', "/Users/james/Desktop/calcium_outputs.txt");

end

%%
function plot_secretion(cell_filename,cell_no)
% Plots a number of the dynamic secretion variables in one figure

load(cell_filename)
%par.volume

Nal  = SSsol(1, :);
Kl   = SSsol(2, :);
Cll  = SSsol(3, :);
w    = SSsol(4, :);
Na   = SSsol(5, :);
K    = SSsol(6, :);
Cl   = SSsol(7, :);
HCO3 = SSsol(8, :);
H    = SSsol(9, :);
Va   = SSsol(10, :);
Vb   = SSsol(11, :);
HCOl = SSsol(12, :);
Hl   = SSsol(13, :);

% Compute Fluid Flow
Qa =  par.La*0.9 * ( 2 * ( Nal + Kl - Na - K - H ) - par.CO20 + par.Ul);  
Qt =  par.Lt * ( 2 * ( Nal + Kl ) + par.Ul - par.Ie );
Qtot=(Qa+Qt);

figure(4)
add_subplot(Qtot, tim, 'Fluid Flow', 1)
add_subplot(w, tim, 'Cell Volume', 2)
add_subplot(Nal, tim, 'Na (lumen)', 3)
add_subplot(Kl, tim, 'K (lumen)', 4)
add_subplot(Cll, tim, 'Cl (lumen)', 5);
add_subplot(Cl, tim, 'Cl', 6);
add_subplot(Va, tim, 'Va', 7);
add_subplot(Vb, tim, 'Vb', 8);

%writematrix([Qtot' Nal' Kl' Cl'], "/Users/james/Desktop/secretion_outputs.txt");
Qtot(end)

end

%%
function add_subplot(var, tim, title, i)
subplot(3,3,i)
plot(tim, var,'LineWidth', 2)
ylabel(title)
xlim([0,100])
end


