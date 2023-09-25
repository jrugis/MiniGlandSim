
load('result_bicarb_VPLC0.004.mat');
Q = time_series.Q;

time_series.Q = movmean(time_series.Q,10);
time_series.Na = movmean(time_series.Na,10);
time_series.K = movmean(time_series.K,10);
time_series.Cl = movmean(time_series.Cl,10);
time_series.HCO = movmean(time_series.HCO,10);
time_series.H = movmean(time_series.H,10);


hold
plot(time_series.time, time_series.Q, '+');
plot(time_series.time, Q);
hold off