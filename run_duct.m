function [] = run_duct(parms_file,simplify_model,display_plots)
cd 'duct';
disp('***** Executing main_script.m *****');
main_script; % This a script, NOT a function. All variables will remain in scope.
save('my_duct_test');
cd '..'
end
