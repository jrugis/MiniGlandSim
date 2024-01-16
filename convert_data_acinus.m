function convert_data_acinus(acinus_results_files)
cd('acinus');
tCa = [];
tpV = [];
for f = acinus_results_files
    load(string(f));
    tCa = vertcat(tCa, time_series.Ca);
    tpV = vertcat(tpV, time_series.pV);
end
acinus_save_binary(time_series.time, tCa, tpV);
cd('..');
