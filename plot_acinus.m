function [] = plot_acinus(results_file, p)
cd('acinus');
if ~isfile(results_file)
    disp(strcat('File not found: ',results_file));
    cd('..');
    return
end
load(results_file);
cd('..');

if p.saliva
    figure('Position',[10,10,760,550])
    add_subplot(time_series.Q, time_series.time, '\mum^3/s', 1);
    title('Fluid Flow');
    add_subplot(time_series.Na, time_series.time, 'mM', 2);
    title('Na');
    add_subplot(time_series.K, time_series.time, 'mM', 3);
    title('K');
    add_subplot(time_series.Cl, time_series.time, 'mM', 4);
    title('Cl');
    add_subplot(time_series.HCO, time_series.time, 'mM', 5);
    title('HCO');
    xlabel('time s');
    add_subplot(time_series.H, time_series.time, 'mM', 6);
    title('H');
    xlabel('time s');
    sgtitle('Primary saliva')
end

if p.calcium
    figure('Position',[20,20,320,800])

    subplot(4,1,1)
    plot(time_series.time, time_series.w, 'LineWidth', 2);
    title('Cell Volume')
    ylabel('\mum^3');
    
    subplot(4,1,2)
    hold on
    p1 = plot(time_series.time, time_series.Ca(end, :),'b', 'LineWidth', 2);
    n = floor(0.8 * size(time_series.Ca,1));
    p2 = plot(time_series.time, time_series.Ca(n, :),'r', 'LineWidth', 2);
    p3 = plot(time_series.time, time_series.Ca(1, :),'g', 'LineWidth', 2);
    legend([p1 p2 p3],'apical','internal','basal');
    hold off
    title('Ca')
    ylabel('\muM');

    subplot(4,1,3)
    plot(time_series.time, time_series.Va, 'LineWidth', 2);
    ylim([-70 -20])
    title('Va')
    ylabel('mV');

    subplot(4,1,4)
    plot(time_series.time, time_series.Vb, 'LineWidth', 2);
    ylim([-70 -20])
    title('Vb')
    ylabel('mV');
    xlabel('time s');
    
    sgtitle('Cell concentrations')
end
end

function add_subplot(var, tim, title, i)
subplot(3,2,i)
plot(tim, var,'LineWidth', 2)
ylabel(title)
end
