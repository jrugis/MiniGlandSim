function [] = run_duct(parms_file, gui_parms, acinus_data_file, results_label)
cd('duct');
disp('Executing main_script...');
main_script; % This a script, NOT a function. All variables remain in scope.
%save('my_duct_test');
disp('Executing dynamic_script...');
dynamic_script; % This a script, NOT a function. All variables remain in scope.
cd('..');
end
