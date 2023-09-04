function convert_data(duct_results_file)
cd('duct');
if ~isfile(duct_results_file)
    disp("File not found: ", duct_results_file);
    cd('..');
    return
end
load(duct_results_file);
data_post_processing();
cd('..');
