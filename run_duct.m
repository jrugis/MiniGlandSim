function [] = run_duct(parms_file,simplify_model,display_plots,acinus_data_file)
cd('duct');
disp('Executing main_script...');
main_script; % This a script, NOT a function. All variables remain in scope.
%save('my_duct_test');
disp('Executing dynamic_script...');
dynamic_script; % This a script, NOT a function. All variables remain in scope.
cd('..');
end
