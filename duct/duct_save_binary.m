function duct_save_binary(zzzz, flowrate, s_lumen_prop)

fbin = fopen("_4Unity_duct.bin", "w");

%load("dynamic_data");
%load("dynamic_flow");
%load("lumen_prop");

% ********* HARD CODED *************
%ndisc = 191;  % number of discs
ndvars = 6;   %    "      disc vars: flow + 5x concentrations (Na, K, Cl, HCO, pH) 
ncell = 111;  %    "      active cells
ncvars = 5;   %    "      cell concentrations (Na, K, Cl, HCO, pH)                     
% **********************************

% *****************************************************
% write fixed duct data to bin file for unity
% *****************************************************
ndiscs = s_lumen_prop.n_disc;
ddiam = sqrt(s_lumen_prop.disc_X_area/pi)*2;
dleng = s_lumen_prop.disc_length;
dsegs = s_lumen_prop.d_s_Vec;
ndsegs = max(dsegs);
dcenters = double.empty(0,3);
for i = 1:ndsegs % DATA "ERROR" CORRECTION:flip order of centers within each segment
    scenters = flip(s_lumen_prop.disc_centres(find(dsegs == i), :));
    dcenters = [dcenters; scenters];
end

dvects = zeros([ndiscs 3]); % calculate disc direction vectors
s = 0;                      % previous duct segment
for i = 1:ndiscs
    if dsegs(i) ~= s        % moved to next duct segment?
        dvect = dcenters(i+1,:) - dcenters(i,:); % use first two segments points for direction
        s = dsegs(i);
    end
    dvects(i,:) = dvect;    % same direction for all discs in each segment
end
fwrite(fbin, ndiscs, 'int');                  % number of discs
fwrite(fbin, transpose(dcenters), 'single');  % disc center coordinates
fwrite(fbin, transpose(ddiam), 'single');     % disc diameters
fwrite(fbin, transpose(dleng), 'single');     % disc lengths
fwrite(fbin, transpose(dvects), 'single');    % disc direction vectors

% *****************************************************
% write dynamic duct data to bin file for unity
% *****************************************************
nsteps = size(flowrate,1);
fwrite(fbin, nsteps, 'int');

% ********* HARD CODED *************
fwrite(fbin, [0, 4000], 'int');
% **********************************

% ********* HARD CODED *************
% simulation time at each step, first 500s @ 0.1s step, remainder at 1s step
fwrite(fbin, [0:5000] * 0.1, 'single');                 
fwrite(fbin, 500.0 + ([5001:nsteps-1] - 5000), 'single');
% **********************************

% total number of simulated variables
fwrite(fbin, (ndiscs * ndvars) + (ncell * ncvars), 'int');

% minimum cell concentrations
for n = 1:ncvars 
    fwrite(fbin, min(zzzz(:, n:ncvars:ncell*ncvars),[],'all'),'single');
end
%fwrite(fbin, min(zzzz(:, 1:ncvars),[],1),'single');
% minimum disc concentrations
step = ndvars-1;
stop = (ndiscs * (ndvars-1)) + (ncell * ncvars);
for n = 1:ndvars-1 
    start = ncvars*ncell+n;
    fwrite(fbin, min(zzzz(:, start:step:stop),[],'all'),'single');
end
% minimum flow value
fwrite(fbin, min(flowrate,[],'all'),'single');

% maximum cell concentrations
for n = 1:ncvars 
    fwrite(fbin, max(zzzz(:, n:ncvars:ncell*ncvars),[],'all'),'single');
end
%fwrite(fbin, max(zzzz(:, 1:ncvars),[],1),'single');
% maximum disc concentrations
for n = 1:ndvars-1 
    start = ncvars*ncell+n;
    fwrite(fbin, max(zzzz(:, start:step:stop),[],'all'),'single');
end
% maximum flow value
fwrite(fbin, max(flowrate,[],'all'),'single');

%fwrite(fbin, transpose(flowrate), 'single');% flow data
%fwrite(fbin, transpose(zzzz), 'single'); % concentration data
fwrite(fbin, transpose([zzzz flowrate]), 'single');


fclose(fbin);

