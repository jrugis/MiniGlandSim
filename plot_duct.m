function [] = plot_duct(results_file, p)
cd('duct');
if ~isfile(results_file)
    disp("File not found: result_duct.mat");
    cd('..');
    return
end
load(results_file);
cd('..');

% common properties for plots
IntPos = zeros(1,lumen_prop.n_disc);
IntPos(1) = lumen_prop.disc_length(1);
for i = 2:lumen_prop.n_disc
    out = lumen_prop.disc_out_Vec(i);
    IntPos(i) = lumen_prop.disc_length(i) + IntPos(out);
end
max_length = max(IntPos);
IntPos = max_length - IntPos;
% IntPos = IntPos(1:58);
% y_l = y_l(:,1:58);

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

%% plot whole duct at a fixed time point

if p.ductatfixedtime
    time = 500;% second
    time_ind = time/tstep +1;
    n_c = length(cell_prop);
    yyy_c = reshape(z(time_ind,1 : n_c*9),9,[]); %[9, n_c]
    yyy_l = reshape(z(time_ind,1+n_c*9 : end),6,[]); %[6, n_l]
  
    figure('Name', 'Duct at Fixed Time');
    subplot(3,2,1)
    plot(CellPos, yyy_c([1,2],I),'.')
    legend('V_A','V_B')
    ylabel('mV')
    title('Membrane Potential')

    subplot(3,2,2)
    w = yyy_c(3,I);
    plot(CellPos(find(CellType(1,:))), w(find(CellType(1,:))),'.')
    hold on
    plot(CellPos(find(CellType(2,:))), w(find(CellType(2,:))),'.')
    hold off
    legend('ID', 'SD')
    ylabel('\mu m^3')
    title('Cell Volume')

    subplot(3,2,3)
    plot(CellPos, yyy_c([4,5,6,7],I),'.')
    legend('Na_C','K_C','Cl_C','HCO_C')
    ylabel('mM')
    title('Cellular Concentration')

    subplot(3,2,4)
    w = -log10(yyy_c(8,I)*1e-3);
    plot(CellPos(find(CellType(1,I))), w(find(CellType(1,I))),'.')
    hold on
    plot(CellPos(find(CellType(2,I))), w(find(CellType(2,I))),'.')
    hold off
    legend('ID', 'SD')
    title('Cellular pH')
    
    subplot(3,2,5)
    plot(IntPos, yyy_l([1,2,3,4],:),'.')
    legend('Na_A','K_A','Cl_A','HCO_A')
    ylabel('mM')
    xlabel('Duct Length (\mum)')
    title('Luminal Concentration')

    subplot(3,2,6)
    plot(IntPos, -log10(yyy_l(5,:)*1e-3),'.')
    xlabel('Duct Length (\mum)')
    title('Luminal pH')
end

if p.ductacrossalltime
    time = 500;% second
    time_ind = time/tstep +1;
    n_c = length(cell_prop);
    yyy_c = reshape(z(time_ind,1 : n_c*9),9,[]); %[9, n_c]
    yyy_l = reshape(z(time_ind,1+n_c*9 : end),6,[]); %[6, n_l]
    
    t_sample = 1:200:10000;
    x = 1:2:(length(lumen_prop.disc_length)-1);
    pos = zeros(size(x));
    tt = t(t_sample);
    NAA = zeros(length(x),length(tt));
    KA = zeros(length(x),length(tt));
    CLA = zeros(length(x),length(tt));
    
    % looping through all the duct discs
    for i = 1:length(x)
        % cell_no = x(i);
        % cell_no = cell_no - 1;
        n_c = length(cell_prop);
        % yy_c = z(:,[cell_no*9+1 : cell_no*9+9]);
        yy_l = z(:,[n_c*9+x(i)*6+1:n_c*9+x(i)*6+6]);
        pos(i) = IntPos(x(i));
        NAA(i,:) = yy_l(t_sample,1);
        KA(i,:) = yy_l(t_sample,2);
        CLA(i,:) = yy_l(t_sample,3);
    end
    
    figure('Name', 'Duct Across All Time');
    subplot(2,2,1)
    [ppos,I] = sort(pos);
    [X,Y] = meshgrid(ppos,tt);
    surf(X,Y,NAA(I,:)')
    zlabel('mM')
    ylabel('Time (s)')
    xlabel('Dist along Duct (\mum)')
    title('A : [Na^+]_A')
    
    subplot(2,2,2)
    surf(X,Y,KA(I,:)')
    zlabel('mM')
    ylabel('Time (s)')
    xlabel('Dist along Duct (\mum)')
    title('B : [K^+]_A')
    
    subplot(2,2,3)
    surf(X,Y,CLA(I,:)')
    zlabel('mM')
    ylabel('Time (s)')
    xlabel('Dist along Duct (\mum)')
    title('C : [Cl^-]_A')
    
    x = 2:28:length(cell_prop);
    x = [90,86,76,58,30,2];
    cpos = zeros(size(x));
    tt = t(t_sample);
    wC = zeros(length(x),length(tt));
    
    for i = 1:length(x)
        cell_no = x(i);
        cell_no = cell_no - 1;
        n_c = length(cell_prop);
        %cell_prop{x(i)}.type
        yy_c = z(:,[cell_no*9+1 : cell_no*9+9]);
        cpos(i) = max_length - cell_prop{x(i)}.mean_dist;
        wC(i,:) = yy_c(t_sample,3);
    end
    
    subplot(2,2,4)
    [ppos,I] = sort(cpos);
    [X,Y] = meshgrid(ppos,tt);
    surf(X,Y,wC(I,:)')
    zlabel('\mum^3')
    ylabel('Time (s)')
    xlabel('Dist along Duct (\mum)')
    xlim([0,150])
    title('D : Cell volume')
end

if p.steadystatefluxes
    cd('duct');
    f_ODE_noMass(1, y(end,:), P, s_cell_prop, s_lumen_prop, 1, 0, 0);
    cd('..');
end

if p.stimulatedfluxes
    cd('duct');
    ind = find(t==400);
    f_ODE_noMass(t(ind), z(ind,:), P,s_cell_prop, s_lumen_prop, 1, 1, time_series);
    cd('..');
end

end
