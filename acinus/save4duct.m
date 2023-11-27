function save4duct(fname, par, tim, SSsol, sol)
%SS = horzcat(SSsol(:,2001:end), zeros(size(SSsol,1),2000) + SSsol(:,end));
SS = SSsol(:,4001:end);
Nal = SS(1,:);
Kl = SS(2,:);
Cll = SS(3,:);
Na = SS(5,:);
K = SS(6,:);
H = SS(9,:);
HCOl = SS(12,:);
Hl = SS(13,:);

%% JS version
% Qa =  par.La*0.9 * ( 2 * ( Nal + Kl - Na - K - H ) - par.CO20 + par.Ul);
%%
Qa =  par.La * ( 2 * ( Nal + Kl - Na - K - H ) - par.CO20 + par.Ul );     % micro-metres^3.s^-1
Qt =  par.Lt * ( 2 * ( Nal + Kl ) + par.Ul - par.Ie);                     % micro-metres^3.s^-1
Qtot=(Qa+Qt);                                                             % micro-metres^3.s^-1

ca_solutions = sol(1:6233,4001:12001);
ca_avg = mean(ca_solutions,2);
[ca_avg,order]=sort(ca_avg);
ca_solutions = ca_solutions(order,:);
Ca = ca_solutions([1:20:end end],:);

time_series = struct('time',tim(1:end-4000),'Q',Qtot,'Na',Nal,'K',Kl,'Cl',Cll,'HCO',HCOl,'H',Hl,'Ca',Ca);
save(fname, 'time_series');

end
