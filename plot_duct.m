function [] = plot_duct(ductatfixedtime)
cd('duct');
if ~isfile("result_duct.mat")
    disp("File not found: result_duct.mat");
    cd('..');
    return
end
load("result_duct");
cd('..');

%% plot whole duct at a fixed time point
time = 500;% second
time_ind = time/tstep +1;
n_c = length(cell_prop);
yyy_c = reshape(z(time_ind,1 : n_c*9),9,[]); %[9, n_c]
yyy_l = reshape(z(time_ind,1+n_c*9 : end),6,[]); %[6, n_l]

if ductatfixedtime
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
    
    figure
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
    plot(CellPos, -log10(yyy_c(8,I)*1e-3),'.')
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
end
