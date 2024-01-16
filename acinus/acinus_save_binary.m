function acinus_save_binary(tim, Ca, pV)

%        // read in acinus fixed data
%        a_fs = new FileStream(a_path, FileMode.Open);
%        a_nnodes = get_count(a_fs);                 // number of acinus nodes           
%        a_ntsteps = get_count(a_fs);                // number of acinus timesteps           
%        a_nodes = get_coordinate(a_fs, a_nnodes);   // acinus node coordinates
%        a_sTimes = get_floats(a_fs, a_ntsteps);       // acinus simulation times
%
%        // read in acinus simulation data
%        a_data_head = a_fs.Position;
%        a_dyn_data = get_floats(a_fs, a_nnodes);
%        a_prev_tstep = -1;  // to force initial data display 


tim = tim(:,1:2:end-2); % temporal downsample
tsteps = size(tim,2);
nnodes = size(pV,1);
Ca = Ca(:,1:2:end-2);   % temporal downsample

% write fixed acinus cell data to bin file for unity
fbin = fopen("_4Unity_acinus.bin", "w");
fwrite(fbin, nnodes, 'int');             % number of nodes
fwrite(fbin, tsteps, 'int');             % number of time steps
fwrite(fbin, transpose(pV), 'single');   % acinus cell node coordinates
fwrite(fbin, transpose(tim), 'single');  % acinus simulation times
fwrite(fbin, Ca, 'single');   % acinus cell calcium data
%fwrite(fbin, transpose(Ca), 'single');   % acinus cell calcium data
fclose(fbin);

