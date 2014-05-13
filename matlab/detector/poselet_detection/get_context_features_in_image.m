%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Given a set of hits coming from an image, returns a feature vector for
%%% each hit. The feature vector is of size NUM_POSELETS and the i'th element
%%% is the max score of all hits of type i compatible with the current hit.
%%% Two hits are compatible if their KL-divergence is less than a threshold.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [features,contrib_hits]=get_context_features_in_image(all_hyps,hits,config)

% They must all come from the same image
%assert(all(hits.image_id(2:end)==hits.image_id(1)));
dist_thresh = config.HYP_CLUSTER_THRESH;

features=zeros(hits.size,length(all_hyps),'single');
for h=1:hits.size
    features(h,hits.poselet_id(h))=hits.score(h); % at the feature itself to the context
end

hyps  = instantiate_hypotheses(all_hyps,hits);

if nargout>1
    % Also returns for each hit the indices of all hits closer than the
    % distance
    contrib_hits={};
    for h=1:hits.size
        contrib_hits{h}=h;
    end
    for h1=1:(hits.size-1)
        for h2=(h1+1):hits.size
           dst=hyps(h1).distance(hyps(h2),config);
           if dst<dist_thresh
               features(h1,hits.poselet_id(h2)) = max(features(h1,hits.poselet_id(h2)),hits.score(h2));
               features(h2,hits.poselet_id(h1)) = max(features(h2,hits.poselet_id(h1)),hits.score(h1));
               contrib_hits{h1}(end+1)=h2;
               contrib_hits{h2}(end+1)=h1;
           end
        end
    end
else
    for h1=1:(hits.size-1)
        for h2=(h1+1):hits.size
           dst=hyps(h1).distance(hyps(h2),config);
           if dst<dist_thresh
               features(h1,hits.poselet_id(h2)) = max(features(h1,hits.poselet_id(h2)),hits.score(h2));
               features(h2,hits.poselet_id(h1)) = max(features(h2,hits.poselet_id(h1)),hits.score(h1));
           end
        end
    end
end
end
