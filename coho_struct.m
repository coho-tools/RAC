function [val,status,update] = coho_struct(S,op,varargin)
% [val,status,update] = coho_struct(S,op,varargin)
% This function support operations for struct. 
% 1. check if S has fields or not
% 	has = coho_struct(S,'has',field1,...,fieldN); (or 'is','check')
% 2. get the list of fileds
% 	names = coho_struct(S,'fields'); (or 'names','filenames');
% 3. get fields 
% 	values = coho_struct(S,'get',field1,...,fieldN); (return a cell)
% 	value = coho_struct(S,'get',field);
% 	S = coho_struct(S,'get');
% 4. convert to a string (for display)
% 	str = coho_struct(S,'string',dispvalue); (or 'str','2string','2str','disp');
% 5. set fields
% 	S = coho_struct(S,'set',field1,value1,...,fieldN,valueN);
% 6. add fields
% 	S = coho_struct(S,'add',field1,value1,...,fieldN,valueN);
% 7. remove fields
% 	S = coho_struct(S,'remove',field1,...,fieldN); (or 'rm','delete')
% 8. merge two structures
%   S = coho_struct(S,'merge',S2)
% The default value of op is 'get'
%
% status = 0: val is valid, otherwise, val is invalid ([]). 
% 	status maybe nonzero for get/set/rm function if the field does not exist 
% 		or for rm function when fileds already exist
% 
% update = true if S is changed
	
	if(nargin<2), op = 'get'; end
	val = []; status = 0; update = false;

	switch(lower(op))
		case {'check','has','is'} % check if fields exist
			val = coho_checkField(S,varargin);
		case {'fieldnames','fileds','names'} % list of fileds
			val = fieldnames(S);
		case 'get' % get value of a field
			% valids = coho_checkField(S,varargin); % disable for performance reason
			%if(~all(valids))
			%	warning('non-exist fields found');
			%	status = 1; return;	
			%end
			nvar = length(varargin);
			switch(nvar)
				case 0 % return the struct
					val = S;
				case 1 % return a value
					%val = getfield(S,varargin{1});
					val = S.(varargin{1}); % dynamic filenames
				otherwise  % return a cell
					val = cell(nvar,1); 
					for i=1:nvar 
						val{i} = S.(varargin{i});
					end
			end
		case {'string','str','2string','2str','disp'} % disp the struct
			if(~isempty(varargin)) 
				dispvalue = varargin{1};
			else
				dispvalue = true;
			end
			names = fieldnames(S); 
			str = ''; 
			for i=1:length(names) 
				field = names{i}; 
				if(dispvalue) 
					value = S.(field);	
					if(ischar(value)) 
						vstr = value; 
					elseif(isnumeric(value)) 
						vstr = num2str(value); 
					else 
						vstr = 'struct or cell'; 
					end 
					str = sprintf('%s\t%s:\t%s\n',str,field,vstr); 
				else 
					str = sprintf('%s\t%s\n',str,field); 
				end 
				val = str; 
			end
		case {'set','add'} % set value of a field or add a new field
			if(mod(length(varargin),2)~=0) 
				error('number of parameters incorrect'); 
			end
			update = true;
%			valids = coho_checkField(S,varargin(1:2:end));
%			if(strcmpi(op,'set')&&~all(valids)) 
%			  % NOTE: it's OK to add & set.
%				%warning('non-exist fields found'); 
%				%status = 1; return;	
%			end
%			if(strcmpi(op,'add')&&any(valids))
%				warning('exist fields found');
%				status = 1; return;	
%			end
			nvar = length(varargin)/2;
			for i=1:nvar
				field = varargin{2*i-1};
				value = varargin{2*i}; 
				S.(field) = value;
			end	
			val = S; % return the new struct
		case {'remove','rm','delete'}
			update = true;
%			valids = coho_checkField(S,varargin);
%			if(~all(valids))
%				warning('non-exist field found');
%				status = 1; return;	
%			end	
			for i=1:length(varargin)
				S = rmfield(S,varargin{i});
			end
			val = S;
		otherwise
			error('Does not support');
	end

end % function coho_struct

function valids = coho_checkField(S,fields)
% valids = coho_checkField(S,fields)
% This function checks if the strucut S has fields
	valids = true(length(fields),1);
	for i=1:length(fields)
		valids(i) = isfield(S,fields{i});
	end
end % coho_checkField
