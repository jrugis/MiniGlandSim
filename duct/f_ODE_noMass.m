function [dxdt,flow_rate] = f_ODE_noMass(t,x,P,cell_prop,lumen_prop,displ,dynamic,time_series)

% x is [1 ; 9 * n_c + 6 * n_l] 
% 
% x_c(1,:) V_A
% x_c(2,:) V_B
% x_c(3,:) w_C
% x_c(4,:) Na_C
% x_c(5,:) K_C
% x_c(6,:) Cl_C
% x_c(7,:) HCO_C
% x_c(8,:) H_C
% x_c(9,:) CO_C
% 
% x_l(1,:) Na_A
% x_l(2,:) K_A
% x_l(3,:) Cl_A
% x_l(4,:) HCO_A
% x_l(5,:) H_A
% x_l(6,:) CO_A

GHK = 1;

n_c = length(cell_prop);  % number of cells
n_l = lumen_prop.n_disc;   % number of lumen segments

x_c = reshape(x(1 : n_c*9),9,[]);        % [9, n_c]
x_l = reshape(x(1 + n_c*9 : end),6,[]);  % [6, n_l]

if displ
    flux = initiate_flux(n_l, n_c, x_c);
end

% read the constant parameters from input struct P
if dynamic
    % primary saliva volume flow rate dependent on time
    if t<500
        Na_P = interp1(time_series.time,time_series.Na,t);
        K_P = interp1(time_series.time,time_series.K,t);
        Cl_P = interp1(time_series.time,time_series.Cl,t);
        HCO_P = interp1(time_series.time,time_series.HCO,t);
        H_P = interp1(time_series.time,time_series.H,t);
        pv = interp1(time_series.time,time_series.Q,t);
    else
        Na_P = P.ConP.Na;% mM
        K_P = P.ConP.K;
        Cl_P = P.ConP.Cl;
        HCO_P = P.ConP.HCO;
        H_P = P.ConP.H;
        pv = P.PSflow;
    end
else 
    % primary saliva volume flow rate independent on time
    Na_P = P.ConP.Na;% mM
    K_P = P.ConP.K;
    Cl_P = P.ConP.Cl;
    HCO_P = P.ConP.HCO;
    H_P = P.ConP.H;
    pv = P.PSflow;
end
% HCO_P = P.ConP.HCO;% 
% H_P = P.ConP.H;% 
CO_P = P.ConP.CO;% 

Na_B = P.ConI.Na;
K_B = P.ConI.K;
Cl_B = P.ConI.Cl; %
HCO_B = P.ConI.HCO; % 
H_B = P.ConI.H; % interstitium pH = 7.35
CO_B = P.ConI.CO;

R = P.R; % J/mol/K
T = P.T; % K
F = P.F;% C/mol

V_w = P.V_w; % um^3/mol 
A_L = lumen_prop.disc_X_area; %um^2 [1,n_l]
phi_A = P.phi_A; % mM
phi_B = P.phi_B; % mM

K_na_nhe    = P.NHE.K_na;
K_h_nhe     = P.NHE.K_h;

k3_p = P.AE.k3_p; % 1/s
k3_m = P.AE.k3_m; % 1/s
k4_p = P.AE.k4_p; % 1/s
k4_m = P.AE.k4_m; % 1/s 
K_cl_ae = P.AE.K_cl;
K_hco_ae = P.AE.K_hco;

K_na_nbc    = P.NBC.K_na;
K_hco_nbc   = P.NBC.K_hco;
R_lk        = P.NBC.R_lk;

r_NKA = P.NKA.r; % mM-3s-1
beta_NKA = P.NKA.beta; % mM-1

p_CO = P.p_CO; % 1/s 
k_buf_p = P.buf.k_p; %/s
k_buf_m = P.buf.k_m; %/mMs

% setup a vector to record the rate of change of lumen fluid flow
dwAdt = zeros(1,n_l); 

% setup the ode rate of change matrices
dxcdt = zeros(size(x_c)); % [9,n_c]
dxldt = zeros(size(x_l)); % [6,n_l]

% loop through the cells to populate the rate of change for each cell/variable
for i = 1:n_c
    
    % first, read all the cell specific parameters
    cell_struct = cell_prop{i};
    
    G_ENaC = cell_struct.scaled_rates.G_ENaC;
    G_CFTR = cell_struct.scaled_rates.G_CFTR;
    G_CaCC = cell_struct.scaled_rates.G_CaCC;
    G_BK   = cell_struct.scaled_rates.G_BK;
    G_K_B  = cell_struct.scaled_rates.G_K_B;
    G_Cl_B = cell_struct.scaled_rates.G_Cl_B;
    G_Na_B = cell_struct.scaled_rates.G_Na_B;
    G_P_Na = cell_struct.scaled_rates.G_P_Na;
    G_P_K  = cell_struct.scaled_rates.G_P_K;
    G_P_Cl = cell_struct.scaled_rates.G_P_Cl;
    
    alpha_NKA_A = cell_struct.scaled_rates.NKA.alpha_A;
    alpha_NKA_B = cell_struct.scaled_rates.NKA.alpha_B;
    
    L_B = cell_struct.scaled_rates.L_B; % um/s 
    L_A = cell_struct.scaled_rates.L_A; % um/s 
    
    G_NHE_A = cell_struct.scaled_rates.NHE.G_A;
    G_NHE_B = cell_struct.scaled_rates.NHE.G_B;
    
    G_AE_A = cell_struct.scaled_rates.AE.G_A;
    G_AE_B = cell_struct.scaled_rates.AE.G_B;
    
    G_NBC_A = cell_struct.scaled_rates.NBC.G_A;
    G_NBC_B = cell_struct.scaled_rates.NBC.G_B;

    chi_C = cell_struct.scaled_rates.chi_C; % mol
    
    % read the cellular variables of this particular cell
    V_A   = x_c(1,i);
    V_B   = x_c(2,i);
    w_C   = x_c(3,i);
    Na_C  = x_c(4,i);
    K_C   = x_c(5,i);
    Cl_C  = x_c(6,i);
    HCO_C = x_c(7,i);
    H_C   = x_c(8,i);
    CO_C  = x_c(9,i);
    
    % read the lumenal variables of all lumen discs this cell interface with
    loc_disc = find(cell_struct.api_area_discs~=0);
    A_A = cell_struct.api_area;
    A_B = cell_struct.baslat_area;
    A_A_disc = cell_struct.api_area_discs(loc_disc); % um^2 [1,n_loc_disc]
    w_A = lumen_prop.disc_volume(loc_disc); % um^3 [1,n_loc_disc]
    
    Na_A  = x_l(1,loc_disc);
    K_A   = x_l(2,loc_disc);
    Cl_A  = x_l(3,loc_disc);
    HCO_A = x_l(4,loc_disc);
    H_A   = x_l(5,loc_disc);
    CO_A  = x_l(6,loc_disc);
    
    % water transport
    osm_c = chi_C./w_C*1e18; % osmolarity of cell due to proteins (chi)
    
    J_B = 1e-14*L_B.*V_w.*(Na_C + K_C + Cl_C + HCO_C + osm_c - Na_B - K_B - Cl_B - HCO_B - phi_B); % um/s 
    J_A = 1e-14*L_A.*V_w.*(Na_A + K_A + Cl_A + HCO_A + phi_A - Na_C - K_C - Cl_C - HCO_C - osm_c); % um/s [1, n_loc_disc]
    dwdt = A_B * J_B - sum(A_A_disc .* J_A); % um^3/s
    dwAdt(1,loc_disc) = dwAdt(1,loc_disc) + A_A_disc .* J_A; % um^3/s [1, n_loc_disc]
    
%     % CDF C02 Diffusion 
%     J_CDF_A = p_CO * (CO_C - CO_A).* w_C .* A_A_disc./A_A; % e-18 mol/s [1, n_loc_disc]
%     J_CDF_B = p_CO * (CO_C - CO_B).* w_C; % e-18 mol/s
    
    % buf CO2 buffering
    J_buf_C = (k_buf_p*CO_C - k_buf_m.*HCO_C.*H_C.*1e-3).* w_C; % e-18 mol/s 
    J_buf_A =  k_buf_p*CO_A - k_buf_m.*HCO_A.*H_A.*1e-3; %mM/s [1,n_loc_disc]
    
    % NHE
    J_NHE_A = G_NHE_A .* A_A_disc .* (Na_A.*H_C - Na_C.*H_A) ./ ((K_na_nhe*K_h_nhe).*( (1 + Na_A./K_na_nhe + H_A/K_h_nhe).*(Na_C/K_na_nhe + H_C/K_h_nhe) + (1+Na_C/K_na_nhe+H_C/K_h_nhe).*(Na_A./K_na_nhe + H_A./K_h_nhe) )); % e-8 mol/s
    J_NHE_A = J_NHE_A * 1e10; % e-18 mol/s
    
    J_NHE_B = G_NHE_B .* A_B .* (Na_B.*H_C - Na_C.*H_B) ./ ((K_na_nhe*K_h_nhe).*( (1 + Na_B./K_na_nhe + H_B/K_h_nhe).*(Na_C/K_na_nhe + H_C/K_h_nhe) + (1+Na_C/K_na_nhe+H_C/K_h_nhe).*(Na_B./K_na_nhe + H_B./K_h_nhe) )); % e-8 mol/s
    J_NHE_B = J_NHE_B * 1e10; % e-18 mol/s

    % AE
    K_1 = K_cl_ae*K_hco_ae;
    K_2 = K_1;
    K_3 = k3_m/k3_p;
    k4_m = P.AE.k4_m; % 1/s 
    
    beta1_p = ( k3_p*K_hco_ae.*Cl_C ) ./ ( K_cl_ae*K_hco_ae + K_hco_ae.*Cl_C + K_cl_ae.*HCO_C ); % /s
    beta1_m = ( k3_m*K_hco_ae.*Cl_B ) ./ ( K_cl_ae*K_hco_ae + K_hco_ae.*Cl_B + K_cl_ae.*HCO_B ); % /s
    beta2_p = ( k4_p*K_cl_ae.*HCO_B ) ./ ( K_cl_ae*K_hco_ae + K_hco_ae.*Cl_B + K_cl_ae.*HCO_B ); % /s
    beta2_m = ( k4_m*K_cl_ae.*HCO_C ) ./ ( K_cl_ae*K_hco_ae + K_hco_ae.*Cl_C + K_cl_ae.*HCO_C ); % /s

    J_AE_B = 1e10.* G_AE_B .* A_B .* ( - beta1_p.*beta2_p + beta1_m.*beta2_m) ./ (beta1_p + beta1_m + beta2_p + beta2_m); % e-18 mol/s

    e_term = exp(-F*0.001*V_A/(R*T));
    k4_m =  e_term/(K_1*K_2*K_3)*k4_p;

    alpha1_p = ( k3_p.*Cl_C ) ./ ( Cl_C + K_1.*HCO_C.^2 );
    alpha1_m = ( k3_m.*K_2.*Cl_A ) ./ ( K_2.*Cl_A + HCO_A.^2 );
    alpha2_p = ( k4_p.*HCO_A.^2 ) ./ ( K_2.*Cl_A + HCO_A.^2);
    alpha2_m = ( k4_m.*K_1.*HCO_C.^2 ) ./ ( Cl_C + K_1.*HCO_C.^2 );
    
    J_AE_A = 1e10.* G_AE_A .* A_A_disc .* (alpha1_m.*alpha2_m - alpha1_p.*alpha2_p)./(alpha1_p + alpha1_m + alpha2_p + alpha2_m); % e-18 mol/s

    % NBC 
    NH_B = Na_B .* HCO_B ./ (K_na_nbc.*K_hco_nbc);
    NH_C = Na_C .* HCO_C ./ (K_na_nbc.*K_hco_nbc);
    NH_A = Na_A .* HCO_A ./ (K_na_nbc.*K_hco_nbc);

    J_NBC_B = G_NBC_B .* A_B .* ( NH_B - NH_C ) ./ ( (1 + R_lk.*NH_B).*(1 + Na_C/K_na_nbc + NH_C) + (1 + R_lk.*NH_C).*(1+Na_B/K_na_nbc + NH_B) ).* 1e10; % e-18 mol/s
    J_NBC_A = G_NBC_A * A_A_disc .* ( NH_A - NH_C ) ./ ( (1 + R_lk.*NH_A).*(1 + Na_C/K_na_nbc + NH_C) + (1 + R_lk.*NH_C).*(1+Na_A/K_na_nbc + NH_A) ).* 1e10; % e-18 mol/s
    

    % CFTR
    V_A_Cl = 1e3*R*T/(-1*F).*log(Cl_A./Cl_C); % mV [1,n_loc_disc]
    if ~ GHK
        I_CFTR = G_CFTR.*90000 .* A_A_disc .* (V_A - V_A_Cl); % e-6 nA [1,n_loc_disc]
        I_CaCC = G_CaCC.*90000 .* A_A_disc .* (V_A - V_A_Cl); % e-6 nA [1,n_loc_disc]
    else
        I_CFTR = 10.*G_CFTR .* A_A_disc .* F.^2 .* 1e-3.*V_A ./ (R*T) .* (Cl_C - Cl_A*exp(1e-3*V_A*F/(R*T))) / (1 - exp(1e-3*V_A*F/(R*T))); % e-6 nA [1,n_loc_disc]
        I_CaCC = 10.*G_CaCC .* A_A_disc .* F.^2 .* 1e-3.*V_A ./ (R*T) .* (Cl_C - Cl_A*exp(1e-3*V_A*F/(R*T))) / (1 - exp(1e-3*V_A*F/(R*T))); % e-6 nA [1,n_loc_disc]
    end
    
    % CFTR_B
    V_A_HCO = 1e3*R*T/((-1)*F).*log(HCO_A./HCO_C); % mV [1,n_loc_disc]
    if ~GHK
        I_CFTR_B = 0.25 .* G_CFTR .*90000 .* A_A_disc .* (V_A - V_A_HCO); % e-6 nA [1,n_loc_disc]
    else
        I_CFTR_B = 10.*0.25 .* G_CFTR .* A_A_disc .* F.^2 .* 1e-3.*V_A ./ (R*T) .* (HCO_C - HCO_A*exp(1e-3*V_A*F/(R*T))) / (1 - exp(1e-3*V_A*F/(R*T))); % e-6 nA [1,n_loc_disc]
    end
    
    % I_BK Apical
    V_A_K = 1e3*R*T/F.*log(K_A./K_C); % mV  [1,n_loc_disc]
    if ~ GHK
    I_BK = G_BK.*330000 .* A_A_disc .* (V_A - V_A_K); % e-6 nA
    else
    I_BK = 10.* G_BK .* A_A_disc .* F.^2 .* 1e-3.*V_A ./ (R*T) .* (K_C - K_A*exp(-1e-3*V_A*F/(R*T))) / (1 - exp(-1e-3*V_A*F/(R*T))); % e-6 nA 
    end

    % ENaC Apical
    V_A_Na = 1e3*R*T/F*log(Na_A./Na_C); % mV  [1,n_loc_disc]
    if ~ GHK
        I_ENaC = G_ENaC .*100000 .* A_A_disc .* (V_A - V_A_Na); % e-6 nA
    else
        I_ENaC = 10.*G_ENaC .* A_A_disc .* F.^2 .* 1e-3.*V_A ./ (R*T) .* (Na_C - Na_A*exp(-1e-3*V_A*F/(R*T))) / (1 - exp(-1e-3*V_A*F/(R*T))); % e-6 nA 
    end

    % I_Na_B Basolateral
    V_B_Na = 1e3*R*T/F.*log(Na_B./Na_C); % mV
    if ~ GHK
    I_Na_B = G_Na_B *300000 * A_B .* (V_B - V_B_Na); % e-6 nA
    else
    I_Na_B = 10* G_Na_B * A_B * F^2 * 1e-3*V_B / (R*T) * (Na_C - Na_B*exp(-1e-3*V_B*F/(R*T))) / (1 - exp(-1e-3*V_B*F/(R*T))); % e-6 nA
    end

    % I_K_B Basolateral
    V_B_K = 1e3*R*T/F.*log(K_B./K_C); % mV
    if ~ GHK
    I_K_B = G_K_B *90000 * A_B .* (V_B - V_B_K); % e-6 nA
    else
    I_K_B = 10* G_K_B .* A_B * F^2 * 1e-3*V_B / (R*T) * (K_C - K_B*exp(-1e-3*V_B*F/(R*T))) / (1 - exp(-1e-3*V_B*F/(R*T)));
    end

    % I_Cl_B Basolateral
    V_B_Cl = 1e3*R*T/(-1*F).*log(Cl_B./Cl_C); % mV

    if ~ GHK
    I_Cl_B = G_Cl_B .*100000 * A_B .* (V_B - V_B_Cl); % e-6 nA 
    else
    I_Cl_B = 10* G_Cl_B * A_B * F^2 * 1e-3*V_B / (R*T) * (Cl_C - Cl_B*exp(1e-3*V_B*F/(R*T))) / (1 - exp(1e-3*V_B*F/(R*T)));
    end

    % NaKATPase, NKA 
    J_NKA_A = 1e-4.* A_A_disc .* alpha_NKA_A * r_NKA .*(K_A.^2.*Na_C.^3)./(K_A.^2+beta_NKA*Na_C.^3); % 10^-12 mol/s [1,n_loc_disc]
    J_NKA_B = 1e-4.* A_B .* alpha_NKA_B * r_NKA .*(K_B.^2.*Na_C.^3)./(K_B.^2+beta_NKA*Na_C.^3); % 10^-12 mol/s
     
    
    % Paracellular currents
    V_T      = V_A - V_B; % mV
    V_P_Na   = 1e3*R*T/F.*log(Na_A/Na_B); % mV [1,n_loc_disc]
    V_P_K    = 1e3*R*T/F.*log(K_A/K_B); % mV [1,n_loc_disc]
    V_P_Cl   = 1e3*R*T/(-F).*log(Cl_A/Cl_B); % mV [1,n_loc_disc]
    if  ~GHK
        I_P_Na   = G_P_Na.*280000 .* A_A_disc .* (V_T - V_P_Na); % e-6 nA [1,n_loc_disc] .*420000
        I_P_K    = G_P_K.*65000 .* A_A_disc .* (V_T - V_P_K); % e-6 nA [1,n_loc_disc] .*49000
        I_P_Cl   = G_P_Cl.*180000 .* A_A_disc .* (V_T - V_P_Cl); % e-6 nA [1,n_loc_disc] .*280000
    else
        I_P_Na   = 10.* G_P_Na .* A_A_disc .* F.^2 .* 1e-3.*V_T ./ (R*T) .* (Na_B - Na_A*exp(-1e-3*V_T*F/(R*T))) / (1 - exp(-1e-3*V_T*F/(R*T))); % e-6 nA [1,n_loc_disc]
        I_P_K    = 10.* G_P_K .* A_A_disc .* F.^2 .* 1e-3.*V_T ./ (R*T) .* (K_B - K_A*exp(-1e-3*V_T*F/(R*T))) / (1 - exp(-1e-3*V_T*F/(R*T))); % e-6 nA [1,n_loc_disc]
        I_P_Cl   = 10.* G_P_Cl .* A_A_disc .* F.^2 .* 1e-3.*V_T ./ (R*T) .* (Cl_B - Cl_A*exp(1e-3*V_T*F/(R*T))) / (1 - exp(1e-3*V_T*F/(R*T))); % e-6 nA [1,n_loc_disc]
   end
    
    
    % V_A e-15 c/s
    dxcdt(1,i) = -100000.*(sum(F*J_NKA_A*1e3 + I_ENaC + I_BK + I_CFTR + I_CaCC + I_CFTR_B + I_P_Na + I_P_K + I_P_Cl - F.*J_AE_A*1e-3));
    % V_B e-15 c/s
    dxcdt(2,i) = -100000.*(F*J_NKA_B*1e3 + I_K_B + I_Na_B + I_Cl_B - sum(I_P_Na + I_P_K + I_P_Cl));
    % w_C um^3
    dxcdt(3,i) = dwdt;
    % Na_C mM/s
    dxcdt(4,i) = -dwdt*Na_C/w_C + 1e3*(-sum(I_ENaC)./(F*w_C) - I_Na_B./(F*w_C)) - 1e6*(3*(J_NKA_B+sum(J_NKA_A))/w_C) + sum(J_NBC_A)/w_C + J_NBC_B/w_C + sum(J_NHE_A)/w_C + J_NHE_B/w_C;
    % K_C mM/s
    dxcdt(5,i) = -dwdt*K_C/w_C + 1e3*(-sum(I_BK)./(F*w_C) - I_K_B./(F*w_C)) + 1e6*(2*(J_NKA_B+sum(J_NKA_A))/w_C);
    % Cl_C mM/s
    dxcdt(6,i) = -dwdt*Cl_C/w_C + 1e3*(sum(I_CFTR)./(F*w_C) + sum(I_CaCC)./(F*w_C) + I_Cl_B./(F*w_C)) + sum(J_AE_A)/w_C + J_AE_B/w_C;
    % HCO_C mM/s
    dxcdt(7,i) = -dwdt*HCO_C/w_C + 1e3*(sum(I_CFTR_B)./(F*w_C)) + sum(J_NBC_A)/w_C + J_NBC_B/w_C - 2*sum(J_AE_A)/w_C - J_AE_B/w_C + J_buf_C/w_C;
    % H_C mM/s
    dxcdt(8,i) = -dwdt*H_C/w_C - sum(J_NHE_A)/w_C - J_NHE_B/w_C + J_buf_C/w_C;
    % CO_C mM/s
    dxcdt(9,i) = 0; % -dwdt*CO_C/w_C - sum(J_CDF_A)/w_C - J_CDF_B/w_C - J_buf_C/w_C;
    
    % Na_A mM/s
    dxldt(1,loc_disc) = dxldt(1,loc_disc) + 1e6*(3*J_NKA_A./w_A) + 1e3*(I_ENaC./(F*w_A)) + 1e3*(I_P_Na./(F*w_A)) - J_NHE_A./w_A - J_NBC_A./w_A;
    % K_A mM/s
    dxldt(2,loc_disc) = dxldt(2,loc_disc) - 1e6*(2*J_NKA_A./w_A) + 1e3*(I_BK./(F*w_A)) + 1e3*(I_P_K./(F*w_A));
    % Cl_A mM/s
    dxldt(3,loc_disc) = dxldt(3,loc_disc) + 1e3*(-I_CFTR./(F*w_A)) + 1e3*(-I_CaCC./(F*w_A)) + 1e3*(-I_P_Cl./(F*w_A)) - J_AE_A./w_A;
    % HCO_A mM/s
    dxldt(4,loc_disc) = dxldt(4,loc_disc) + 1e3*(-I_CFTR_B./(F*w_A)) - J_NBC_A./w_A + 2*J_AE_A./w_A + J_buf_A;
    % H_A mM/s
    dxldt(5,loc_disc) = dxldt(5,loc_disc) + J_NHE_A./w_A + J_buf_A;
    % CO_A mM/s
    dxldt(6,loc_disc) = dxldt(6,loc_disc); % + J_CDF_A./w_A - J_buf_A;
    
    if displ
        flux.V_A_Na(loc_disc) = V_A_Na;
        flux.V_P_Na(loc_disc) = V_P_Na;
        flux.V_B_Na(i) = V_B_Na;
        flux.V_A_K(loc_disc) = V_A_K;
        flux.V_B_K(i) = V_B_K;
        flux.V_P_K(loc_disc) = V_P_K;
        flux.V_A_Cl(loc_disc) = V_A_Cl;
        flux.V_B_Cl(i) = V_B_Cl;
        flux.V_P_Cl(loc_disc) = V_P_Cl;
        flux.V_A_HCO(loc_disc) = V_A_HCO;
        flux.J_NHE_A(loc_disc) = flux.J_NHE_A(loc_disc) + J_NHE_A;
        flux.J_NHE_A_c(i) = sum(J_NHE_A);
        flux.J_NHE_B(i) = J_NHE_B;
        flux.J_AE_A(loc_disc) = flux.J_AE_A(loc_disc) + J_AE_A;
        flux.J_AE_A_c(i) = sum(J_AE_A);
        flux.J_AE_B(i) = J_AE_B;
        flux.J_NBC_A(loc_disc) = flux.J_NBC_A(loc_disc) + J_NBC_A;
        flux.J_NBC_A_c(i) = sum(J_NBC_A);
        flux.J_NBC_B(i) = J_NBC_B;
        flux.J_NKA_A(loc_disc) = flux.J_NKA_A(loc_disc) + J_NKA_A;
        flux.J_NKA_A_c(i) = sum(J_NKA_A);
        flux.J_NKA_B(i) = J_NKA_B;
        flux.J_buf_A(loc_disc) = flux.J_buf_A(loc_disc) + J_buf_A.*w_A;
        flux.J_buf_A_c(i) = sum(J_buf_A.*w_A);
        flux.J_buf_C(i) = J_buf_C;
        flux.I_ENaC(loc_disc) = flux.I_ENaC(loc_disc) + I_ENaC;
        flux.I_ENaC_c(i) = sum(I_ENaC);
        flux.I_P_Na(loc_disc) = flux.I_P_Na(loc_disc) + I_P_Na;
        flux.I_P_Na_c(i) = sum(I_P_Na);
        flux.I_BK(loc_disc) = flux.I_BK(loc_disc) + I_BK;
        flux.I_BK_c(i) = sum(I_BK);
        flux.I_K_B(i) = I_K_B;
        flux.I_Cl_B(i) = I_Cl_B;
        flux.I_Na_B(i) = I_Na_B;
        flux.I_P_K(loc_disc) = flux.I_P_K(loc_disc) + I_P_K;
        flux.I_P_K_c(i) = sum(I_P_K);
        flux.I_CFTR(loc_disc) = flux.I_CFTR(loc_disc) + I_CFTR;
        flux.I_CFTR_c(i) = sum(I_CFTR);
        flux.I_CaCC(loc_disc) = flux.I_CaCC(loc_disc) + I_CaCC;
        flux.I_CaCC_c(i) = sum(I_CaCC);
        flux.I_P_Cl(loc_disc) = flux.I_P_Cl(loc_disc) + I_P_Cl;
        flux.I_P_Cl_c(i) = sum(I_P_Cl);
        flux.I_CFTR_B(loc_disc) = flux.I_CFTR_B(loc_disc) + I_CFTR_B;
        flux.I_CFTR_B_c(i) = sum(I_CFTR_B);
    end
end

% compute the fluid flow rate in the lumen
v_secreted = zeros(1,n_l); % um^3/s accumulated volume flow rates of secreted fluid
v_up = zeros(1,n_l); % um^3/s volume flow rate of fluid into each lumen disc
x_up = zeros(size(x_l)); 

disc_out = lumen_prop.disc_out_Vec;

for i=n_l:-1:1
    
    % find upstream disc(s) of disc i
    i_up = find(ismember(disc_out, i));
    
    % if no upstream disc, it is an acinus end disc, v_up = PSflow
    if isempty(i_up)
        v_up(i) = pv;
        v_secreted(i) = 0;
%         x_up(:,i) = cell2mat(struct2cell(P.ConP));
        x_up(:,i) = [Na_P; K_P; Cl_P; HCO_P; H_P; CO_P];
        
    else % i_up could be a vector due to i being a branching disc
        v_up(i) = sum(v_up(i_up));
        v_secreted(i) = sum(v_secreted(i_up) + dwAdt(i_up));
        x_up(:,i) = sum(x_l(:,i_up).*v_up(i_up)/sum(v_up(i_up)),2);
    end
end
v_up = v_up + v_secreted;
v = v_up + dwAdt;

% convert volumetric flow rate to linear flow speed
v = v./A_L; % um/s 
v_up = v_up./A_L; % um/s

% 1D finite difference discretisation of the lumen, backward differences scheme
for i = 1:6
    dxldt(i,:) = dxldt(i,:) + (v_up.*x_up(i,:) - v.*x_l(i,:))./lumen_prop.disc_length;
end

% flatten the matrix to a column vector
dxdt = [dxcdt(:); dxldt(:)];

flow_rate = v.*A_L;

% display for debugging and cross checking purposes
if displ
    fprintf('initial P.S. flow rate: %2.2f  um3 \n',(5*v_up(end)*A_L(end))) % um^3/s
    fprintf('final P.S. flow rate:   %2.2f  um3 \n',(v(1)*A_L(1))) % um^3/s
    fprintf('percentage:             %2.2f  ',(v(1)*A_L(1)-5*v_up(end)*A_L(end))/(5*v_up(end)*A_L(end))*100)
    
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
    CellPos = max_length - CellPos;
    
%%%%%%%%%%%%
    %figure_no = 40; % not used!
    %plot_fluxes(figure_no, CellPos, IntPos, flux, dwAdt)
%%%%%%%%%%%%

%     c_idx = find(CellType(2,:));
    c_idx = 1:n_c;
    l_idx = 1:n_l;
    z = IntPos(l_idx);
    x = CellPos(c_idx);

%%%%%%%%%%%%
    x_range = [-5,135];
    x_label = 'ID entry     SD entry                                SD exit';
%%%%%%%%%%%%
    
    
%% plot the apical fluxes breakdown
%{
    figure()
    ax(1) = subplot(4,2,1);
    y = zeros(1,length(z));
    y(1,:) = flux.I_ENaC(l_idx).*1e-6;
    y(2,:) = flux.I_P_Na(l_idx).*1e-6;
    y(3,:) = -flux.J_NBC_A(l_idx).*F.*1e-9;
    y(4,:) = -flux.J_NHE_A(l_idx).*F.*1e-9;
    y_na = sum(y);
    plot(z,y,'.','MarkerSize',10)
%    ylim([-0.2,0.01]) % in-vivo
    %ylim([-0.15,0.01]) % ex-vivo
    title('Apical Na^+ into lumen')
    ylabel('nA\mum')
    legend('I_{ENaC}', 'I_{P_{Na}}', 'J_{NBC_A}', 'J_{NHE_A}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')
    ax(2) = subplot(4,2,3);
    y = zeros(2,length(z));
    y(1,:) = flux.I_BK(l_idx).*1e-6;
    y(2,:) = flux.I_P_K(l_idx).*1e-6;
    y_k = sum(y);
    plot(z,y,'.','MarkerSize',10)
    %ylim([-0.008,0.1]) % in-vivo 
%     ylim([-0.008,0.08]) % ex-vivo
    title('Apical K^+ into lumen')
    ylabel('nA/\mum')
    legend('I_{BK}', 'I_{P_{K}}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    ax(3) = subplot(4,2,5);
    y = zeros(2,length(z));
    y(1,:) = -flux.I_CFTR(l_idx).*1e-6-flux.I_CaCC(l_idx).*1e-6;
    y(2,:) = -flux.I_P_Cl(l_idx).*1e-6;
    y(3,:) = -flux.J_AE_A(l_idx).*F.*1e-9;
    y_cl = sum(y);
    plot(z,y,'.','MarkerSize',10)
    %ylim([-0.1,0.01]) % in-vivo
%     ylim([-0.07,0.01]) % ex-vivo
    title('Apical Cl^- into lumen')
    ylabel('nA/\mum')
    legend('I_{CFTR/CaCC}', 'I_{P_{Cl}}', 'J_{AE_A}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    ax(4) = subplot(4,2,7);
    y = zeros(2,length(z));
    y(1,:) = -flux.I_CFTR_B(l_idx).*1e-6;
    y(2,:) = flux.J_buf_A(l_idx).*F.*1e-9;
    y(3,:) = 2.*flux.J_AE_A(l_idx).*F.*1e-9;
    y(4,:) = -flux.J_NBC_A(l_idx).*F.*1e-9;
    y_hco = sum(y);
    plot(z,y,'.','MarkerSize',10)
    %ylim([-0.005,0.041]) % in-vivo
%     ylim([-0.005,0.03]) % ex-vivo
    title('Apical HCO_3^- into lumen')
    ylabel('nA/\mum')
    legend('I_{CFTR_B}', 'J_{buf_A}', 'J_{AE_A}', 'J_{NBC_A}','AutoUpdate','off')
    xlabel('Duct entry                                Duct exit')
    
    sgtitle('Apical ion fluxes per \mum duct ( positive flux enters lumen )') 
    

    % plot the apical net fluxes

    ax(5) = subplot(4,2,2);
    plot(z,y_na,'.','MarkerSize',10)
%     ylim([-0.25,0.01])  in-vivo
    %ylim([-0.2,0.01])
    legend('Na^+','AutoUpdate','off','Location','southoutside')

    ax(6) = subplot(4,2,4);
    plot(z,y_k,'.','MarkerSize',10)
%     ylim([-0.008,0.15]) % in-vivo
    %ylim([-0.008,0.1])
    legend('K^+','AutoUpdate','off')
    
    ax(7) = subplot(4,2,6);
    plot(z,y_cl,'.','MarkerSize',10)
%     ylim([-0.23,0.01]) % in-vivo
    %ylim([-0.1,0.01])
    legend('Cl^-','AutoUpdate','off','Location','southoutside')

    ax(8) = subplot(4,2,8);
    plot(z,y_hco,'.','MarkerSize',10)
%     ylim([-0.002,0.04]) % in-vivo
    %ylim([-0.005,0.041]) % ex-vivo
    legend('HCO_3^-','AutoUpdate','off','Location','southoutside')
    xlabel(x_label)

    %set(gcf,'position',[200,50,850,900])

    for k = 1:8
        if i==1
            ylabel(ax(k),'nA/\mum');
        end
        xlim(ax(k),x_range)
        set(ax(k),'xtick',[],'YGrid','on','xlim',x_range)
%         line(ax(k), x_range, [0,0], 'Color', 'k', 'LineWidth', 1.2); % Draw line for X axis.
    end
%}    
     
    %% plot the apical and basolateral fluxes
    figure('Position', [10 10 768 1024])
    
    for k = 1:8
    ax(k) = subplot(4,2,k);
    end
    
    % subplot(4,2,1)
    x = CellPos(c_idx);
    y = zeros(1,length(x));
    y(1,:) = flux.I_ENaC_c(c_idx).*1e-6;
    y(2,:) = flux.I_P_Na_c(c_idx).*1e-6;
    y(3,:) = -flux.J_NBC_A_c(c_idx).*F.*1e-9;
    y(4,:) = -flux.J_NHE_A_c(c_idx).*F.*1e-9;
    plot(ax(1),x,y,'.','MarkerSize',10)
    title(ax(1),'Apical Na into lumen ')
    xlabel(ax(1),x_label)
    legend(ax(1),'I_{ENaC}', 'I_{P_{Na}}', 'J_{NBC_A}', 'J_{NHE_A}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')
    
    % subplot(4,2,1)
    y = zeros(2,length(x));
    y(1,:) = -3.*flux.J_NKA_B(c_idx).*F*1e-3;
    y(2,:) = -flux.I_Na_B(c_idx).*1e-6;
    y(3,:) = flux.J_NBC_B(c_idx).*F.*1e-9;
    y(4,:) = flux.J_NHE_B(c_idx).*F.*1e-9;
    plot(ax(2),x,y,'.','MarkerSize',10)
    title(ax(2),'Basolateral Na into cell ')
    xlabel(ax(2),x_label)
    legend(ax(2),'J_{NKA_B}','I_{Na_B}','J_{NBC_B}', 'J_{NHE_B}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')
    
    % subplot(4,2,3)
    y = zeros(2,length(x));
    y(1,:) = flux.I_BK_c(c_idx).*1e-6;
    y(2,:) = flux.I_P_K_c(c_idx).*1e-6;
    plot(ax(3),x,y,'.','MarkerSize',10)
    title(ax(3),'Apical K into lumen ')
    xlabel(ax(3),x_label)
    legend(ax(3),'I_{BK}', 'I_{P_{K}}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    % subplot(4,2,4)
    y = zeros(2,length(x));
    y(1,:) = 2.*flux.J_NKA_B(c_idx).*F*1e-3;
    y(2,:) = -flux.I_K_B(c_idx).*1e-6;
    plot(ax(4),x,y,'.','MarkerSize',10)
    title(ax(4),'Basolateral K into cell ')
    xlabel(ax(4),x_label)
    legend(ax(4),'J_{NKA_B}','I_{K_B}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    % subplot(4,2,5)
    y = zeros(2,length(x));
    y(1,:) = -flux.I_CFTR_c(c_idx).*1e-6-flux.I_CaCC_c(c_idx).*1e-6;
    y(2,:) = -flux.I_P_Cl_c(c_idx).*1e-6;
    y(3,:) = -flux.J_AE_A_c(c_idx).*F.*1e-9;
    plot(ax(5),x,y,'.','MarkerSize',10)
    title(ax(5),'Apical Cl into lumen ')
    xlabel(ax(5),x_label)
    legend(ax(5),'I_{CFTR/CaCC}', 'I_{P_{Cl}}', 'J_{AE_A}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    % subplot(4,2,6)
    y = zeros(2,length(x));
    y(1,:) = flux.J_AE_B(c_idx).*F.*1e-9;
    y(2,:) = flux.I_Cl_B(c_idx).*1e-6;
    plot(ax(6),x,y,'.','MarkerSize',10)
    title(ax(6),'Basolateral Cl into cell ') 
    xlabel(ax(6),x_label)
    legend(ax(6),'J_{AE_B}','I_{Cl_B}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    % subplot(4,2,7)
    y = zeros(2,length(x));
    y(1,:) = -flux.I_CFTR_B_c(c_idx).*1e-6;
    y(2,:) = flux.J_buf_A_c(c_idx).*F.*1e-9;
    y(3,:) = 2.*flux.J_AE_A_c(c_idx).*F.*1e-9;
    y(4,:) = -flux.J_NBC_A_c(c_idx).*F.*1e-9;
    plot(ax(7),x,y,'.','MarkerSize',10)
    title(ax(7),'Apical HCO into lumen ')
    xlabel(ax(7),x_label)
    legend(ax(7),'I_{CFTR_B}', 'J_{buf_A}', 'J_{AE_A}', 'J_{NBC_A}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')

    % subplot(4,2,8)
    y = zeros(2,length(x));
    y(1,:) = -flux.J_AE_B(c_idx).*F.*1e-9;
    y(2,:) = flux.J_buf_C(c_idx).*F.*1e-9;
    y(3,:) = flux.J_NBC_B(c_idx).*F.*1e-9;
    plot(ax(8),x,y,'.','MarkerSize',10)
    title(ax(8),'Basolateral HCO into cell ')
    legend(ax(8),'J_{AE_B}','J_{buf_C}','J_{NBC_B}','AutoUpdate','off','Location','southoutside','Orientation','horizontal')
    xlabel(ax(8),x_label)

    sgtitle('Stimulated Apical & Basolateral Ion Fluxes ( positive flux enters lumen )') 
    %set(gcf,'position',[400,50,850,900])

    for k = 1:8
        if mod(k,2)
            ylabel(ax(k),'nA/cell');
        end
        set(ax(k),'xtick',[],'YGrid','on','xlim',x_range)
        line(ax(k), x_range, [0,0], 'Color', 'k', 'LineWidth', 0.8); % Draw line for X axis.
    end
end
end

function flux = initiate_flux(n_l,n_c,x_c)
    flux = struct;
    flux.V_A = x_c(1,:);
    flux.V_B = x_c(2,:);
    flux.V_T = flux.V_A - flux.V_B;
    flux.V_A_Na = zeros(1, n_l);
    flux.V_B_Na = zeros(1, n_c);
    flux.V_P_Na = zeros(1, n_l);
    flux.V_A_K = zeros(1, n_l);
    flux.V_B_K = zeros(1, n_c);
    flux.V_P_K = zeros(1, n_l);
    flux.V_A_Cl = zeros(1, n_l);
    flux.V_B_Cl = zeros(1, n_c);
    flux.V_P_Cl = zeros(1, n_l);
    flux.V_A_HCO = zeros(1, n_l);
    flux.J_NHE_A = zeros(1, n_l);
    flux.J_NHE_A_c = zeros(1, n_c);
    flux.J_NHE_B = zeros(1, n_c);
    flux.J_AE_A = zeros(1, n_l);
    flux.J_AE_A_c = zeros(1, n_c);
    flux.J_AE_B = zeros(1, n_c);
    flux.J_NBC_A = zeros(1, n_l);
    flux.J_NBC_A_c = zeros(1, n_c);
    flux.J_NBC_B = zeros(1, n_c);
    flux.J_NKA_A = zeros(1, n_l);
    flux.J_NKA_B = zeros(1, n_c);
    flux.I_ENaC = zeros(1, n_l);
    flux.I_ENaC_c = zeros(1, n_c);
    flux.I_P_Na = zeros(1, n_l);
    flux.I_P_Na_c = zeros(1, n_c);
    flux.I_BK = zeros(1, n_l);
    flux.I_BK_c = zeros(1, n_c);
    flux.I_K_B = zeros(1, n_c);
    flux.I_P_K = zeros(1, n_l);
    flux.I_P_K_c = zeros(1, n_c);
    flux.I_CFTR = zeros(1, n_l);
    flux.I_CFTR_c = zeros(1, n_c);
    flux.I_CaCC = zeros(1, n_l);
    flux.I_CaCC_c = zeros(1, n_c);
    flux.I_P_Cl = zeros(1, n_l);
    flux.I_P_Cl_c = zeros(1, n_c);
    flux.I_CFTR_B = zeros(1, n_l);
    flux.I_CFTR_B_c = zeros(1, n_c);
    flux.J_buf_A = zeros(1, n_l);
    flux.J_buf_A_c = zeros(1, n_c);
    flux.J_buf_C = zeros(1, n_c);
end