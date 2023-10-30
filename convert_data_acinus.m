function convert_data_acinus(acinus_results_file)
cd('acinus');
if ~isfile(acinus_results_file)
    disp("File not found: ", acinus_results_file);
    cd('..');
    return
end
load(acinus_results_file);
%data_post_processing();
cd('..');
