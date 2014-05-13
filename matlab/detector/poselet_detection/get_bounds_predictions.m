%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Returns the bounds predictions predicted by a set of poselets
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bounds_predictions = get_bounds_predictions(smallq_hits,model,use_meanshift)    
    if ~exist('use_meanshift','var')
       use_meanshift=false; 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%  Compute the object bounds Hough vote of each poselet hit and cluster them using
    %%%  agglomerative clustering
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    for i=1:smallq_hits.size
       bounds(i,:) =  predict_bounds(smallq_hits.bounds(:,i)',model.hough_votes(smallq_hits.poselet_id(i)));
    end

    hits_scale = smallq_hits.bounds(3,:)';
    sigma = reshape([model.hough_votes(smallq_hits.poselet_id).obj_bounds_var],4,[])'.*repmat(hits_scale, 1,4);
    xmin = get_meanshift_mode(bounds(:,1),sigma(:,1),smallq_hits.score,use_meanshift);
    ymin = get_meanshift_mode(bounds(:,2),sigma(:,2),smallq_hits.score,use_meanshift);
    xmax = get_meanshift_mode(bounds(:,1)+bounds(:,3),sigma(:,3),smallq_hits.score,use_meanshift);
    ymax = get_meanshift_mode(bounds(:,2)+bounds(:,4),sigma(:,4),smallq_hits.score,use_meanshift);

    bounds_predictions = hit_list([xmin ymin xmax-xmin ymax-ymin]',score_hypothesis(smallq_hits,model),0,smallq_hits.image_id(1));
end

% Linear combination of the scores and the learned weights
function score = score_hypothesis(poselet_hits,model)
    scores = zeros(length(model.wts),1);
    scores(poselet_hits.poselet_id) = poselet_hits.score;
    poselet_count = histc(poselet_hits.poselet_id, 1:length(model.wts));

    if max(poselet_count)>1
        for q=find(poselet_count>1)'
            scores(q) = max(poselet_hits.score(poselet_hits.poselet_id==q));
        end
    end

    score = sum(scores.*model.wts);
end
