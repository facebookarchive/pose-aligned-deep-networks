%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Transforms the poselet-level hypotheses from poselet space to image
%%% space. Internal function.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hyps=instantiate_hypotheses(all_hyps,hits)
hyps = all_hyps(hits.poselet_id);
ctr = hits.bounds(1:2,:) + hits.bounds(3:4,:)/2;
for j=1:hits.size
    hyps(j) = hyps(j).apply_xform(ctr(:,j)', min(hits.bounds(3:4,j)));
end
end