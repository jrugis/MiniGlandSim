clear all
close all
clc

for  i=1:7
cell_no = i;
cell_filename = append('outputs/long_bicarb_sim_cell_', int2str(cell_no),'_VPLC0.0015.mat');
cell_filename1 = append('downsampled_outputs/long_bicarb_sim_cell_', int2str(cell_no),'_VPLC0.0015.mat');
load(cell_filename, 'sol', 'tim');
time_samples = tim(1:2:end);
ca_solutions = sol(:,1:2:end);

save(cell_filename1,'time_samples','ca_solutions')
end
%  load(cell_filename1)
%  plot(time_samples, ca_solutions(1,:))
%  xlim([0,50])

%{
for  ncell=1:14
icfname = append('long_bicarb_sim_cell_', int2str(ncell),'_VPLC0.001.mat'); % simulation data file
imfname = append('sim_cell_', int2str(ncell),'_mesh.mat');                  % mesh data file
ofname = append('a', int2str(ncell),'.mat');  % subsampled combined data output file            
load(icfname, 'ca_solutions', 'time_samples');
load(imfname, 'p');             % the mesh vertices (simulation nodes)
s = size(ca_solutions);
ss = s(1)/3
xc = ca_solutions(1:10:ss,:);  % subsampled calcium data (not ip3, h)
xp = p(1:10:end,:);             % subsampled vertices
save(ofname,'time_samples','xc','xp');
end
}%
