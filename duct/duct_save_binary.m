%function duct_save_binary(dynamic_data, dynamic_flow, lumen_prop)

fbin = fopen("_4Unity_duct.bin", "w");

load("dynamic_data");
load("dynamic_flow");
load("lumen_prop");

% ********* HARD CODED *************
%ndisc = 191;  % number of discs
%ndvars = 6;   %    "      disc vars: flow + 5x concentrations (Na, K, Cl, HCO, pH) 
%ncell = 111;  %    "      active cells
%ncvars = 5;   %    "      cell concentrations (Na, K, Cl, HCO, pH)                     

% write fixed duct data to bin file for unity
ndiscs = s_lumen_prop.n_disc;
dcenters = s_lumen_prop.disc_centres;
darea = s_lumen_prop.disc_X_area;
dleng = s_lumen_prop.disc_length;
dsegs = s_lumen_prop.d_s_Vec;

%  dvects = np.zeros((ndiscs,3))  
%  # calculate disc direction vectors
%  s = 0                                   # previous duct segment
%  for i in range(ndiscs):
%    if dsegs[i] != s:                     # moved to next duct segment?   
%      dvect = dcenters[i+1] - dcenters[i] # use first two segments points for direction 
%      s = dsegs[i]
%    dvects[i] = dvect                     # same direction for all discs in each segment 

%fwrite(fbin, zzz, 'single');

fclose(fbin);

