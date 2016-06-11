function LOG = log_close
% LOG = log_close
% This funtion closes log files.

% close files for output messages
wfids = rac_cfg('get','logWFIds'); 
for i=1:length(wfids)
	if(wfids(i)>2) % do not close stdout
		fclose(wfids(i));
	end
end
rac_cfg('set','logWFIds',1); 
