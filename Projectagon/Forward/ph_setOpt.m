function opt = ph_setOpt(opt,varargin)
if(nargin<1)
	disp('TODO usage of opt');
end 
opt = coho_struct(opt,'set',varargin{:}); 
ph_checkOpt(opt);
