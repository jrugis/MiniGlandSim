%function [] = plot_acinus(results_file, p)
function [] = plot_acinus(results_file)
cd('acinus');
if ~isfile(results_file)
    disp(strcat('File not found: ',results_file));
    cd('..');
    return
end
load(results_file);
cd('..');

figure('Name','Acinus Lumen Fluid');
add_subplot(time_series.Q, time_series.time, 'Fluid Flow', 1);
add_subplot(time_series.Na, time_series.time, 'Na', 2);
add_subplot(time_series.K, time_series.time, 'K', 3);
add_subplot(time_series.Cl, time_series.time, 'Cl', 4);
add_subplot(time_series.HCO, time_series.time, 'HCO', 5);
add_subplot(time_series.H, time_series.time, 'H', 6);
end

function add_subplot(var, tim, title, i)
subplot(3,2,i)
plot(tim, var,'LineWidth', 2)
ylabel(title)
xlabel('time s');
end
