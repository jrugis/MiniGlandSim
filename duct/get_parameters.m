%function [P_i, P_s] = get_parameters(Conc,PSflow, parms_file, gui_parms)
function [P_i, P_s] = get_parameters(Conc,PSflow, gui_parms)

% The nested structure of P is as follows:
%
%    fields      sub-fields
% 
% P - ConI              (struct of Interstitium ion concentrations)
%   - ConP              (struct of primary saliva ion concentrations)
%   - PSflow
%   - G_ENaC
%   - G_CFTR
%   - G_CaCC
%   - G_K_B    
%   - G_BK      
%   - NBC       - alpha   
%               - k's
%   - AE2       - alpha_A
%               - alpha_B
%               - k's
%   - NHE       - alpha_A
%               - alpha_B
%               - k's
%   - p_CO
%   - buf       - k_m
%               - k_p
%   - NKA       - alpha
%               - r
%               - beta
%   - G_P_Na
%   - G_P_K
%   - G_P_Cl
%   - L_A
%   - L_B
%   - w_A
%   - chi_C
%   - phi_A
%   - phi_B
%   - R
%   - T
%   - F
%   - V
%   - A_L
%   - V_w


%addpath('/Users/ssu655/Dropbox (Uni of Auckland)/shan/PhD/method_of_lines_mesh/ini2struct')
%INI = ini2struct(parms_file);
INI = ini2struct('parms_ex-vivo.ini');
param_s = INI.striated;
param_i = INI.intercalated;
param_c = INI.duct_common;

% get the interactive user adjustments to parameters from GUI
% intercalated
param_i.ae_g_a = gui_parms.p_i.ae_g_a; % apical
%param_i.g_cacc = gui_parms.p_i.g_cacc;
param_i.g_cftr = gui_parms.p_i.g_cftr;
param_i.g_enac = gui_parms.p_i.g_enac; 
%param_i.g_bk = gui_parms.p_i.g_bk;
%param_i.nbc_g_a = gui_parms.p_i.nbc_g_a;
%param_i.nhe_g_a = gui_parms.p_i.nhe_g_a;
param_i.l_a = gui_parms.p_i.l_a;
param_i.ae_g_b = gui_parms.p_i.ae_g_b; % basal 
param_i.g_cl_b = gui_parms.p_i.g_cl_b;
%param_i.g_k_b = gui_parms.p_i.g_k_b;
param_i.g_na_b = gui_parms.p_i.g_na_b;
param_i.nka_alpha_b = gui_parms.p_i.nka_alpha_b;
param_i.nbc_g_b = gui_parms.p_i.nbc_g_b;
param_i.nhe_g_b = gui_parms.p_i.nhe_g_b;
%param_i.l_b = gui_parms.p_i.l_b;
param_i.g_p_cl = gui_parms.p_i.g_p_cl; % tight-junctional
%param_i.g_p_k = gui_parms.p_i.g_p_k;
%param_i.g_p_na = gui_parms.p_i.g_p_na;

% striated
param_s.ae_g_a = gui_parms.p_s.ae_g_a; % apical
%param_s.g_cacc = gui_parms.p_s.g_cacc;
param_s.g_cftr = gui_parms.p_s.g_cftr;
param_s.g_enac = gui_parms.p_s.g_enac; 
%param_s.g_bk = gui_parms.p_s.g_bk;
%param_s.nbc_g_a = gui_parms.p_s.nbc_g_a;
%param_s.nhe_g_a = gui_parms.p_s.nhe_g_a;
param_s.l_a = gui_parms.p_s.l_a;
param_s.ae_g_b = gui_parms.p_s.ae_g_b; % basal
param_s.g_cl_b = gui_parms.p_s.g_cl_b;
%param_s.g_k_b = gui_parms.p_s.g_k_b;
param_s.g_na_b = gui_parms.p_s.g_na_b;
param_s.nka_alpha_b = gui_parms.p_s.nka_alpha_b;
param_s.nbc_g_b = gui_parms.p_s.nbc_g_b;
param_s.nhe_g_b = gui_parms.p_s.nhe_g_b;
%param_s.l_b = gui_parms.p_s.l_b;
param_s.g_p_cl = gui_parms.p_s.g_p_cl; % tight-junctional
%param_s.g_p_na = gui_parms.p_s.g_p_na;
%param_s.g_p_k = gui_parms.p_s.g_p_k;

% common
%param_c.nhe_alpha_a = gui_parms.p_c.nhe_alpha_a;
%param_c.nhe_alpha_b = gui_parms.p_c.nhe_alpha_b;

mergestructs = @(x,y) cell2struct([struct2cell(x);struct2cell(y)],[fieldnames(x);fieldnames(y)]);

% striated parameters
param = mergestructs(param_s, param_c);
P_s = copy_param(param,'S');

P_s.ConI = Conc.Int;
P_s.ConP = Conc.PS;
P_s.PSflow = PSflow;

% intercalated parameters
param = mergestructs(param_i, param_c);
P_i = copy_param(param,'I');

P_i.ConI = Conc.Int;
P_i.ConP = Conc.PS;
P_i.PSflow = PSflow;

end

function P = copy_param(param,s)


% apical channels conductances 
P.G_ENaC = param.g_enac;% 2.5;

P.G_CFTR = param.g_cftr;% 10;

P.G_CaCC = param.g_cacc;% 10;

P.G_BK = param.g_bk;% 6;

% basolateral channels conductances 
P.G_K_B = param.g_k_b;% 0.5;
P.G_Cl_B = param.g_cl_b;
P.G_Na_B = param.g_na_b;

% apical or basolateral transporter rates
P.NBC = struct;
P.NBC.G_A = param.nbc_g_a; %
P.NBC.G_B = param.nbc_g_b; % 
P.NBC.K_na = param.nbc_k_na; 
P.NBC.K_hco = param.nbc_k_hco; 
P.NBC.R_lk = param.nbc_r_lk; 

P.AE = struct;
P.AE.G_A = param.ae_g_a; % 0.001;
P.AE.G_B = param.ae_g_b; %0.0001;
P.AE.k3_p = param.ae_k3_p; %5.86; % 1/s
P.AE.k3_m = param.ae_k3_m; %1.06e8; % 1/s
P.AE.k4_p = param.ae_k4_p; %9.3e7; % 1/s
P.AE.k4_m = param.ae_k4_m; %5.14; % 1/s
P.AE.K_cl = param.ae_k_cl; 
P.AE.K_hco = param.ae_k_hco; 

P.NHE = struct;
P.NHE.G_A = param.nhe_g_a; %0.0001;
P.NHE.G_B = param.nhe_g_b; %0.0001;
P.NHE.K_h = param.nhe_k_h; 
P.NHE.K_na = param.nhe_k_na; 

% CO2 permeability
P.p_CO = param.p_co; %50; % 1/s 

% CO2 bicarbonate buffering
P.buf = struct;
P.buf.k_p = param.buf_k_p; %/s
P.buf.k_m = param.buf_k_m; %/mMs

% sodium potassium pump rates
P.NKA = struct;
P.NKA.alpha_A = param.nka_alpha_a; % 0.7e-8; % mol/m2
P.NKA.alpha_B = param.nka_alpha_b; % 0.9e-8; % mol/m2

P.NKA.r = param.nka_r; % 1.305e-3; %mM-3s-1
P.NKA.beta = param.nka_beta; % 0.647e-4; %mM-1

% paracellular conductances
P.G_P_Na = param.g_p_na;   %S/m2
P.G_P_K = param.g_p_k;     %S/m2
P.G_P_Cl =  param.g_p_cl;   %S/m2

% water permeability across membranes
P.L_A = param.l_a; % 0.6e1; % um/s
P.L_B = param.l_b; % 0.6e1; % um/s

% universal physical constants
P.R = 8.13144621; % J/mol/K
P.T = 310; % K
P.F = 96485.3329; % C/mol
P.V_w = 18e12; % um^3/mol partial molar mass of water

% osmolarity adjusting constants
P.chi_C = param.chi_c; % 4e-14; % mol (40 mM * 1000 um3  = xxx e-18 mol)
P.phi_A = param.phi_a; % 0.2; % mM (fong 2016)
P.phi_B = param.phi_b; % 10.92; % mM (Mangos 1972)

% diffusion coefficient of ions in water: https://www.aqion.de/site/diffusion-coefficients
% [Na, K, Cl, HCO, H, CO]
P.D = [1300,1960,2030,1180,9310,1000]; % 9310 for H+
% D_na in tissue is 513 https://www-ncbi-nlm-nih-gov.ezproxy.auckland.ac.nz/pmc/articles/PMC3024886/
P.z = [1;1;-1;-1;1;0];

epsilon_r = 74.8; % relative permittivity of water at body temperature https://nvlpubs.nist.gov/nistpubs/jres/56/jresv56n1p1_a1b.pdf
epsilon_V = 8.85e-12; % s^4 A^2 kg^-1 m^-3 or farad/m, vacuum permittivity
q = 1.602e-19; % Coulomb, elementary charge
N_A = 6.022e23; % 1/mol, Avogadro's number
P.poisson = q*N_A/(epsilon_r*epsilon_V);
end