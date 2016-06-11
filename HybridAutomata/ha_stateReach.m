function [state,reachData] = ha_stateReach(state,init,ginv)
% [state,reachData] = ha_stateReach(state,init,ginv)
% This function computes the reachable region of a state
% Parameters: 
%   state: the hybrid automata state to performe reachability computation
%   init:  initial regions.
%   ginv:  global invariant, empty by default. 
% Returns: 
%   state: updated automata, state.slices are filled.
%   reachData: reachable data, usually large, so not added to state
%     sets: all reachable sets 
%     tubes: all reachable tubes
%     timeSteps: all forward time steps
%     faces: intersection of projectagon and invaraint constraints.
%            The last one is for gate 0, i.e. reachable tubes.

if(nargin<2), error('not enough parameters'); end;
if(nargin<3), ginv = []; end;

%% Get state information
name = state.name; modelFunc = state.modelFunc; 
inv = state.inv; phOpt = state.phOpt; 
% gates
sgates = state.sgates; ng = state.ng; nsg = length(sgates);
% non-empty callbacks 
exitCond = state.callBacks.exitCond; sliceCond = state.callBacks.sliceCond;
% maybe empty callbacks
beforeComp = state.callBacks.beforeComp; afterComp = state.callBacks.afterComp;
beforeStep = state.callBacks.beforeStep; afterStep = state.callBacks.afterStep;
% parse phOpt;
phType = []; phPlanes = []; fwdOpt = []; 
if(isfield(phOpt,'type')), phType = phOpt.type; end;
if(isfield(phOpt,'planes')), phPlanes = phOpt.planes; end;
if(isfield(phOpt,'fwdOpt')), fwdOpt = phOpt.fwdOpt; end; 
if(isempty(fwdOpt)), fwdOpt = ph_getOpt; end % set default fwdOpt

% Prepare global info
% get tol 
tol = rac_cfg('get','tol');
% set modelFunc
rac_cfg('set','modelFunc',modelFunc); 

% Prepare for slicing
% set state constraints
binv = lp_bloat(inv,tol); % bloat outward for slicing
fwdOpt.constraintLP = lp_and(fwdOpt.constraintLP,lp_and(ginv,binv)); 
% compute LP for slicing
faceLPs = cell(nsg,1); % for virtual gate 0
for i=1:nsg
	gid = sgates(i);
	if(gid==0) % for virtual gate 0, no lp to intersect
		faceLPs{i} = [];
	else
	  lp = lp_create(-inv.A(gid,:),-inv.b(gid));
	  faceLPs{i} = lp_bloat(lp,tol); % bloat inward
	end
end

% Compute initial region 
initPh = init;
% update projectagon type
if(~isempty(phType))
	initPh = ph_convert(initPh,phType); 
end
if(~isempty(phPlanes))
	initPh = ph_chplanes(initPh,phPlanes);
end
% trim it by lp
initPh = ph_canon(initPh,lp_and(ginv,inv)); % no slice, no bloat
if(ph_isempty(initPh))
	log_write(sprintf('Empty inital region for state %s, skip the computation',state.name),true);
  reachData = struct('sets',cell(0,1),'tubes',cell(0,1),'timeSteps',[],'faces',cell(nsg,1));
	return;
end
% execute user provided functions when entering the states
if(~isempty(beforeComp))
	info.initPh = initPh;
  beforeComp(info);
end

% Perform reachability computation
N = 1000; sets = cell(N,1); tubes = cell(N,1);
timeSteps=zeros(N,1); faces = cell(nsg,1);  
startT = cputime; saveT = cputime; fwdT = 0; compT = 0;
ph = initPh; prevPh = []; complete= false; fwdStep = 0; 
while(~complete)
	fwdStep = fwdStep+1;
	log_write(sprintf('Computing forward reachable region of step %d from time %d',fwdStep,fwdT));

	% Compute forward reachable sets and tubes 
	if(~isempty(beforeStep)) % Callback before each fwdStep
		stepData = struct('ph',ph,'prevPh',prevPh,'fwdStep',fwdStep,'fwdT',fwdT,'compT',compT);
	  ph = beforeStep(stepData); 
	end
	if(ph_isempty(ph)) 
		error('Exception in state %s, projectagon to be advanced is empty.',name); 
	end
	% foward reachable sets and tubes
	[nextPh,prevPh,fwdOpt,tube] = ph_advanceSafe(ph,fwdOpt); % prevPh = ph+fwdInfo
	ph = ph_canon(nextPh,inv); % ph trimmed by invariant. 
	sets{fwdStep} = ph; tubes{fwdStep} = tube; 
	timeSteps(fwdStep)=prevPh.fwd.timeStep; fwdT=fwdT+prevPh.fwd.timeStep; 
	compT = cputime-startT;
	stepData = struct('ph',ph,'prevPh',prevPh,'fwdStep',fwdStep,'fwdT',fwdT,'compT',compT);
	if(~isempty(afterStep)) % Callback after each fwdStep 
	  ph = afterStep(stepData); 
	end

	complete = exitCond(stepData); % is the computation done? 

  % compute the intersection slices for each gate 
	stepData.complete = complete; % compute the slice or not?
	ds = sliceCond(stepData);
	assert(numel(ds)==1 || numel(ds)==ng+1);
	if(length(ds)==1), ds = repmat(ds,ng+1,1); end;
	for i = 1:nsg
		gid = sgates(i); 
		if(gid==0), gid = ng+1; end;
	  if(ds(gid))
		  face = ph_intersectLP(tube,faceLPs{i}); 
		  faces{i}{end+1} = ph_simplify(face);  % canonical 
	  end
  end

	% save temporal file per hour 
	if((cputime-saveT)>=3600) 
	  path = rac_cfg('get','threadPath');
		log_write(sprintf('Writing projectagons on to %s',path));
		saveT = cputime;
	end
end
sets = [{initPh};sets(1:fwdStep)]; % add the initial region
tubes = tubes(1:fwdStep); timeSteps = timeSteps(1:fwdStep);

% save slices for initial region of other states
for i=1:nsg  % the end is for gate 0
	slice = ph_canon(ph_simplify(ph_union(faces{i})));
	gid = sgates(i); 
	if(gid==0), gid=ng+1; end;
	state.slices{gid} = slice;
	if(isempty(slice)) 
		log_write(sprintf('The slice on gate %s:%d is empty',name,gid));
	end
end

reachData = struct('sets',{sets},'tubes',{tubes},'timeSteps',timeSteps,'faces',{faces},'compT',compT);
% execute user provided functions when leaving the state
if(~isempty(afterComp)) 
  afterComp(reachData); 
end
