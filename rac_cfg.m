% function [val,status] = rac_cfg(op,varargin)
%   This file keeps a global structure to store info shared over RAC pkgs. 
%   It can be use to config RAC or store global data
%   It supports two operations: 
%     GET: 
%       S = rac_cfg('get');        % get the whole struct
%       value = rac_cfg('get',key) % get the value
%       {v1,v2,...} = rac_cfg('get',k1,k2,...) % get multiple values
%     SET:
%       S = rac_cfg('set',k1,v1,k2,v2,...);  
% 
%   RAC configs 
%     modelFunc: function handle for the dynamic system
%       values:   models = modelFunc(lp)
%                 Given a LP, return a LDI model or a cell of models. 
%                 See int_create for LDI model.
%       default:  @model_create
%     dataPath: path to save computation data
%       default: /var/tmp/<user>/coho/rac/data/
%     threadPath: unique path for this thread for storing related info
%       NOTE: this is read-only for user
%       default: rac_info('sys_path')
%     phOpt: opt for projectagon package. See ph_getOpt for detail.
%       default: ph_getOpt
%     lpSolver:  lp solver 
%       values:  'java', 'matlab', 'cplex', 'cplexjava', 'matlabjava'
%       default: 'java' (wo cplex) or 'cplexjava' (with cplex)
%     projSolver: projection solver
%       values:  'java', 'matlab', 'javamatlab', 'matlabjava'
%       default: 'javamatlab'
%     polySolver: polygon operation solver
%       values:  'java', 'matlab'(or 'saga'); 
%       default: 'java'
%     polyApproxEn: enable over approximation in polygon package
%       values:  1/0
%       default: 1
%     tol: tolerence (not used now)
%       default: 1e-6


function [val,status] = rac_cfg(op,varargin)
	% NOTE: Because of the Matlab 2013 version bug, I have to use global vars. 
  %       Please don't modify the value by other functions. 
	%       Persistent vars will be re-inited the first time when path changed.
  global RAC_CFG;
  if(isempty(RAC_CFG))
		RAC_CFG= rac_cfg_default;
		disp('init rac_cfg');
	end
  [val,status,update] = coho_struct(RAC_CFG,op,varargin{:});
  if(status==0&&update)
		rac_cfg_check(val);
		RAC_CFG = val; % save the update
	end
end % rac_cfg;

function cfg = rac_cfg_default
	% lp solver
	if(rac_info('has_cplex')) 
		lpSolver = 'cplexjava';
	else
		lpSolver = 'java';
	end

	% project solver
	projSolver = 'javamatlab';

	% polygon 
	polySolver = 'java';
	polyApproxEn = 1;

	% ph opt
	phOpt = ph_getOpt; 

	% model function
	modelFunc = @model_create;

  dataPath = ['/var/tmp/',rac_info('user'),'/coho/rac/data']; % the place to save output
  threadPath = rac_info('sys_path'); % thread unique path

	% tolerence. 
	tol = 1e-6;

  cfg = struct('lpSolver', lpSolver, 'projSolver', projSolver, ...
	             'polySolver', polySolver, 'polyApproxEn', polyApproxEn, ...
		           'phOpt', phOpt, 'modelFunc', modelFunc, ...
	 						 'dataPath', dataPath, 'threadPath',threadPath, 'tol', tol); 
end % rac_cfg_default;


function rac_cfg_check(val) 
	% check lpSolver
	if(~rac_info('has_cplex') && any(strcmpi(val.lpSolver,{'cplex','cplexjava'})) )
		error('CPLEX is not available, use Java solver or Matlab solver');
	end
	% check modelFunc
	if(~isa(val.modelFunc,'function_handle'))
		error('You must set modelFunc as a function handler');
	end
end % rac_cfg_check 
