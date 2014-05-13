%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
% Do max bipartite matching
% Returns for each hit:
%   truth_id: the index of its closest truth (or 0 if none)
%   overlap: the degree of overlap to the truth.
%   label:  0 if false positive (overlap < match_thresh)
%           1 if true positive (overlap >= match_thresh and no better match)
%          -1 if duplicate detection (overlap >= match_thresh but there
%                  is another hit for which overlap >= match_thresh and its score is higher
%  Currently the angles are ignored
function [label,overlap,truth_id] = match_hits_truths(hits, hit_scores, truths, match_thresh)    
    Nhits = length(hit_scores);
    Ntruths = size(truths,2);

    label = zeros(Nhits,1);
    overlap = zeros(Nhits,1);
    truth_id = zeros(Nhits,1);
    
    hit_scores = hit_scores/max(hit_scores);
    
    % Build a cost matrix
    weights = inf(Nhits,Ntruths);
    for h=1:Nhits
        op=bounds_overlap(hits(:,h), truths);
        weights(h,op>match_thresh) = 1-op(op>match_thresh)  +  (1-hit_scores(h));    
    end

    if all(isinf(weights(:)))
       return;
    end
    [matching,cost] = hungarian(weights);
    for h=1:Nhits
        fnd=find(matching(h,:));
        if isempty(fnd)
            continue;
        end
        assert(isscalar(fnd));
        label(h)=1;
        overlap(h) = bounds_overlap(hits(:,h),truths(:,fnd));
        truth_id(h)=fnd;
    end
end

