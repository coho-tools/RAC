%   wfids = log_open
%   This function open files to write log

function wfids = log_open(file)
if(  rac_cfg('has','logWFIds') && ...
		~isempty(rac_cfg('get','logWFIds')) && ...
		any(rac_cfg('get','logWFIds')>1)  )
	log_close; % close old file first;
end

wfids = 1;
if(nargin>=1&~isempty(file))
	wfids(2) = fopen(file,'w');
end

rac_cfg('set','logWFIds',wfids);
