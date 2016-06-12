 %RAC_OPEN: Initialization RAC 
 %  rac_open;
function rac_open(debug)
	if(nargin<1||isempty(debug))
		debug = 0;
	end

	disp('Starting RAC ......'); 

	% error and warnings
	if(debug)
		dbstop if error;
	else
		warning off all;
	end

	% Add path
	rac_addpath;


  % Create a unique sys dir
  disp('Create system directory for RAC'); 
  utils_system('mkdir',rac_info('sys_path')); 
  cmd = sprintf('mktemp -d %s/%s_XXX',rac_info('sys_path'),datestr(now,'yy-mm-dd')); 
  [threadPath,status] = utils_system('cmd',cmd);
  if(status)
    error(['Can not create a unique  directory for RAC']); 
  end
  rac_cfg('set','threadPath',threadPath);
  fprintf('  A unique dir %s has been create for this RAC thread.',threadPath); 

	% Open Logger
	disp('Open an logger to record message'); 
	if(debug)
		log_open([threadPath,'/log']);
	else
	  log_open; 
	end

  % Open JANS
	disp('Open JANS'); 
  jans_open(debug)


	disp('RAC initialization complete!');
end %function rac_open


function rac_addpath
	rac_home = rac_info('rac_home'); 
	rac_dirs = rac_info('rac_dirs'); 
  disp('Add RAC directories into Matlab search path');
  %disp('Add the following directories into Matlab search path');
  for i=1:length(rac_dirs)
    dirname = [rac_home,'/',rac_dirs{i}];
    %disp(sprintf('  > %s',dirname));
    addpath(dirname); 
  end
  addpath(rac_home); 
end %function rac_addpath
