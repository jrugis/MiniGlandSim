function [] = run_duct(parms_file,simplify_model,display_plots)
prev_path = pwd;
cd('~/Desktop/MiniGland');
disp('***** Executing main_script.m *****');
main_script; % This a script, NOT a function. All variables will remain in scope.
save('my_duct_test');
cd(prev_path);
end

