function ph = ph_union(phs)
%function ph = ph_union(phs)
% This function compute the union of projectagons.
% The union is over-approximated by computing the union 
% 	of corresponding projection polygons
% 	phs: a cell of projectagons with same strucuture. 
%		(same dim and dims) 
%	ph.type = min(ph1,type,ph2.type,...,phn.type); 
% 	ph is not canonical

% remove empty projectagon
np = length(phs);
ise = false(np,1);
for i=1:np
	ise(i) = ph_isempty(phs{i});
end
phs = phs(~ise);
np = length(phs);
if(np==0), ph = []; return; end
if(np==1), ph = phs{1}; return; end

% check structure
phs = ph_promote(phs);
dim = phs{1}.dim; planes = phs{1}.planes; ns = phs{1}.ns;
%for i=2:np
%	if( phs{i}.dim~=dim || ~all(phs{i}.planes(:)==planes(:)) )
%		error('projectagons must have same structure');
%	end
%end

% compute type of ph
types = zeros(np,1);
for i=1:np
	types(i) = phs{i}.type;
end
type = min(types);

% compute union
switch(type)
	case 0 % concave
		polys = cell(ns,1); hulls = cell(ns,1);
		for i=1:ns
			ps = cell(np,1);
			for j=1:np
				ps{j} = phs{j}.polys{i};
			end
			polys{i} = poly_union(ps);
			hulls{i} = poly_convexHull(polys{i});
		end
		ph = ph_create(dim,planes,hulls,polys,type,false);
	case 1 % convex
		hulls = cell(ns,1);
		for i=1:ns
			pts = zeros(2,0);
			for j=1:np
				pts = [pts,phs{j}.hulls{i}];
			end
			hulls{i} = poly_convexHull(pts);
		end
		ph = ph_create(dim,planes,hulls,hulls,type,false);
	case 2 % bbox
		lbnd = zeros(dim,np); hbnd = zeros(dim,np);
		for i=1:np
			lbnd(:,i) = phs{i}.bbox(:,1);
			hbnd(:,i) = phs{i}.bbox(:,2);
		end
		bbox = [min(lbnd,[],2),max(hbnd,[],2)];
		ph = ph_createByBox(dim,planes,bbox);
	otherwise
		error('unknown projectagon type');
end
