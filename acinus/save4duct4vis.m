function save4duct4vis(fname, par, tim, SSsol, sol, np, p)
%SS = horzcat(SSsol(:,2001:end), zeros(size(SSsol,1),2000) + SSsol(:,end));
SS = SSsol(:,4001:end);
Nal = SS(1,:);
Kl = SS(2,:);
Cll = SS(3,:);
w = SS(4,:);
Na = SS(5,:);
K = SS(6,:);
H = SS(9,:);
Va = SS(10,:);
Vb = SS(11,:);
HCOl = SS(12,:);
Hl = SS(13,:);

%% JS version
% Qa =  par.La*0.9 * ( 2 * ( Nal + Kl - Na - K - H ) - par.CO20 + par.Ul);
%%
Qa =  par.La * ( 2 * ( Nal + Kl - Na - K - H ) - par.CO20 + par.Ul );     % micro-metres^3.s^-1
Qt =  par.Lt * ( 2 * ( Nal + Kl ) + par.Ul - par.Ie);                     % micro-metres^3.s^-1
Qtot=(Qa+Qt);                                                             % micro-metres^3.s^-1

% cell calcium for summary plot and visualisation
ca_solutions = sol(1:np,4001:12001);  % get all the cell calcium values 
ca_avg = mean(ca_solutions,2);        % average calcium at each time step
[ca_avg,order]=sort(ca_avg);          % sort the average values
iCa = order([1:20:np np]);            % indices for subset of sorted calcium values 
Ca = ca_solutions(iCa,:);             % calcium time series subset
pV = p(iCa,:);                        % associated node location subset

% save acinus data for later plotting, visualisation and subsequent duct simulation
time_series = struct('time',tim(1:end-4000),...
    'Q',Qtot,'Na',Nal,'K',Kl,'Cl',Cll,'HCO',HCOl,'H',Hl,...
    'Ca',Ca,'w',w,'Va',Va,'Vb',Vb,'pV',pV);
save(fname, 'time_series');












end
