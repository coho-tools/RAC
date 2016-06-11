% RAC_CLOSE: Release all RAC resources 
%   rac_close;
function rac_close
	disp('Close Java process');
	java_close;
	disp('Close logger'); 
	log_close;
	%rac_rmpath; % do not remove path
	disp('RAC resources have been released!');
end %function rac_close

function rac_rmpath
	rac_home = rac_info('rac_home'); 
	rac_dirs = rac_info('rac_dirs'); 
  disp('Remove RAC directories from Matlab search path');
  %disp('Remove the following directories from Matlab search path');
  for i=1:length(rac_dirs)
    dirname = [rac_home,'/',rac_dirs{i}];
    %disp(sprintf('  > %s',dirname));
    rmpath(dirname); 
  end
  % rmpath(rac_home);  % leave the rac_home to call rac_open
end %function rac_rmpath
