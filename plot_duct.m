function [] = plot_duct(results_file, p)
cd('duct');
if ~isfile(results_file)
    strcat('File not found: ',results_file)
    cd('..');
    return
end
load(results_file);
cd('..');

%% calculate plot commom properties
time = 180;% second
%time_ind = time/step +1;
time_ind = time/0.1 +1;   % "step" is a function name, so it can't be used here!!!!
n_c = length(cell_prop);
yyy_c = reshape(z(time_ind,1 : n_c*9),9,[]); %[9, n_c]
yyy_l = reshape(z(time_ind,1+n_c*9 : end),6,[]); %[6, n_l]

IntPos = zeros(1,lumen_prop.n_disc);
IntPos(1) = lumen_prop.disc_length(1);
for i = 2:lumen_prop.n_disc
    out = lumen_prop.disc_out_Vec(i);
    IntPos(i) = lumen_prop.disc_length(i) + IntPos(out);
end
max_length = max(IntPos);
IntPos = max_length - IntPos;

CellPos = zeros(1,length(cell_prop));
CellType = zeros(2, length(cell_prop));
for i = 1:length(cell_prop)
    CellPos(i) = cell_prop{i}.mean_dist;
    if cell_prop{i}.type == "I"
        CellType(:,i) = [1,0];
    else
        CellType(:,i) = [0,1];
    end
end
[CellPos,I] = sort(CellPos);
CellPos = max_length - CellPos;

% plot steady state fluxes
if p.steadystatefluxes
    cd('duct');
    ind = find(t==180);
    %ind = find(t==0);
    f_ODE_noMass(t(ind), z(ind,:), P,s_cell_prop, s_lumen_prop, 1, 1, time_series);
    cd('..');
end

if p.steadystateduct
    figure('Position',[50,50,770,750])
    ax(1) = subplot(3,2,1);
    plot(CellPos, yyy_c([1,2],I),'.','MarkerSize',10)
    legend('V_A','V_B','Orientation','horizontal','Location','southoutside')
    xlabel('ID entry     SD entry                                SD exit')
    ylabel('mV')
    title('Membrane Potential')
    ax(2) = subplot(3,2,2);
    w = yyy_c(3,I);
    plot(CellPos(find(CellType(1,:))), w(find(CellType(1,:))),'.','MarkerSize',10)
    hold on
    plot(CellPos(find(CellType(2,:))), w(find(CellType(2,:))),'.','MarkerSize',10)
    hold off
    legend('ID', 'SD','Orientation','horizontal','Location','southoutside')
    xlabel('ID entry     SD entry                                SD exit')
    ylabel('\mu m^3')
    title('Cell Volume')
    ax(3) = subplot(3,2,3);
    plot(CellPos, yyy_c([4,5,6,7],I),'.','MarkerSize',10)
    legend('Na_C','K_C','Cl_C','HCO_C','Orientation','horizontal','Location','southoutside')
    xlabel('ID entry     SD entry                                SD exit')
    ylabel('mM')
    title('Cellular Concentration')
    ax(4) = subplot(3,2,4);
    plot(CellPos, -log10(yyy_c(8,I)*1e-3),'.','MarkerSize',10)
    xlabel('ID entry     SD entry                                SD exit')
    title('Cellular pH')
    hLegend = legend('','Location','southoutside');
    set(hLegend,'visible','off')
    ax(5) = subplot(3,2,5);
    plot(IntPos, yyy_l([1,2,3,4],:),'.','MarkerSize',10)
    legend('Na_A','K_A','Cl_A','HCO_A','Orientation','horizontal','Location','southoutside')
    xlabel('ID entry     SD entry                                SD exit')
    ylabel('mM')
    title('Local Duct Concentration')
    ax(6) = subplot(3,2,6);
    plot(IntPos, -log10(yyy_l(5,:)*1e-3),'.','MarkerSize',10)
    xlabel('ID entry     SD entry                                SD exit')
    title('Local Duct pH')
    hLegend = legend('','Location','southoutside');
    set(hLegend,'visible','off')
    
    sgtitle('Steady-state duct solution')
    %set(gcf,'position',[250,50,800,700])
    x_range = [-5,140];
    
    for k = 1:6
        xlim(ax(k),x_range)
        set(ax(k),'xtick',[],'YGrid','on','xlim',x_range)
    end
end

if p.singlecell
    %% plotting single cell dynamic result
    % if displ
    % load("low_stim.mat")
    cell_no = 20;
    cell_no = cell_no - 1;
    n_c = length(cell_prop);
    poc = cell_prop{cell_no}.mean_dist;
    loc_disc = find(cell_prop{cell_no}.api_area_discs~=0);
    yy_c = z(:,[cell_no*9+1 : cell_no*9+9]);
    yy_l = z(:,[n_c*9+loc_disc(1)*6+1:n_c*9+loc_disc(1)*6+6]);
    
    figure('Position',[100,100,760,760])
    ax(1) = subplot(3,2,1);
    plot(t, yy_c(:,1),'LineWidth',2)
    xlabel('time (s)')
    hold on
    plot(t, yy_c(:,2),'LineWidth',2)
    hold off
    legend('V_A','V_B','Orientation','horizontal','Location','southoutside')
    ylabel('mV')
    ylim([-80,0])
    title('Membrane Potentials')
    ax(2) = subplot(3,2,2);
    plot(t, yy_c(:,3),'LineWidth',2)
    xlabel('time (s)')
    ylabel('\mum^3')
    string1 = strcat('Volume of a cell half way along th SD');
    title(string1)
    hLegend = legend('','Location','southoutside');
    set(hLegend,'visible','off')
    ax(3) = subplot(3,2,3);
    plot(t, yy_c(:,4),'LineWidth',2)
    xlabel('time (s)')
    hold on
    plot(t, yy_c(:,5),'LineWidth',2)
    plot(t, yy_c(:,6),'LineWidth',2)
    plot(t, yy_c(:,7),'LineWidth',2)
    hold off
    legend('Na_C','K_C','Cl_C','HCO_C','Orientation','horizontal','Location','southoutside')
    ylabel('mM')
    title('Cellular Concentrations')
    ax(4) = subplot(3,2,4);
    plot(t, -log10(yy_c(:,8)*1e-3),'-','LineWidth',2)
    xlabel('time (s)')
    title('Cellular pH')
    hLegend = legend('','Location','southoutside');
    set(hLegend,'visible','off')
    ax(5) = subplot(3,2,5);
    plot(t, yy_l(:,1),'LineWidth',2)
    xlabel('time (s)')
    hold on
    plot(t, yy_l(:,2),'LineWidth',2)
    plot(t, yy_l(:,3),'LineWidth',2)
    plot(t, yy_l(:,4),'LineWidth',2)
    hold off
    legend('Na_A','K_A','Cl_A','HCO_A','Orientation','horizontal','Location','southoutside')
    ylabel('mM')
    title('Local duct Concentrations')
    ax(6) = subplot(3,2,6);
    plot(t, -log10(yy_l(:,5)*1e-3),'LineWidth',2)
    xlabel('time (s)')
    hLegend = legend('','Location','southoutside');
    set(hLegend,'visible','off')
    title('Local duct pH')
    
    sgtitle('Single duct cell')
    %set(gcf,'position',[300,150,800,700])
    %x_range = [0,800];
    x_range = [0,400];
    
    for k = 1:6
        xlim(ax(k),x_range)
        %     set(ax(k),'xtick',[],'YGrid','on','xlim',x_range)
    end

end
