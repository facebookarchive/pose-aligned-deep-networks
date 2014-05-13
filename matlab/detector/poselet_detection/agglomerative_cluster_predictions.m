function c_hits=agglomerative_cluster_predictions(src_hits,thresh,config,use_max)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Non-max suppression of object bounds via agglomerative clustering
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if src_hits.isempty
       c_hits=hit_list;
       return;
    end

    if ~exist('thresh','var')
        thresh=config.CLUSTER_HITS_CUTOFF;
    end

    bounds = src_hits.bounds;
    bounds(3:4,:) = bounds(3:4,:)+bounds(1:2,:);    % dims to max_pt

    if exist('use_max','var') && use_max
        mrg_fn = @rect_merge_fn_max;
    else
        mrg_fn = @rect_merge_fn;
    end

    [mbounds,mscores,msrc_idx] = agglomerative_cluster(bounds', src_hits.score, thresh, @rect_distfn, mrg_fn);

    mbounds(:,3:4) = mbounds(:,3:4)-mbounds(:,1:2);    % max_pt to dims

    N = length(mscores);

    % Average out the angles in the same cluster
    if isempty(src_hits.src_idx)
        src_idx=msrc_idx;
    else
        for k=1:N
            src_idx{k,1}=[];
            for c=1:length(msrc_idx{k})
               src_idx{k,1} = [src_idx{k,1} src_hits.src_idx{msrc_idx{k}(c)}];
            end
        end
    end

    c_hits=hit_list(mbounds',mscores,0,src_hits.image_id(1),src_idx);
end

function d = rect_distfn(u, vv)
    assert(size(u,1)==1);
    N = size(vv,1);

    u_area = repmat(prod(u(3:4)-u(1:2),2),N,1);
    vv_area = prod(vv(:,3:4)-vv(:,1:2),2);

    int_dims = max(0,min(repmat(u(3:4),N,1),vv(:,3:4))-max(repmat(u(1:2),N,1),vv(:,1:2)));
    int_area = prod(int_dims,2);

    % union over intersection
    d = 1-int_area./(u_area+vv_area - int_area);
end

function [rect_ij,w_ij] = rect_merge_fn(rect_i,w_i, rect_j,w_j, src_i,src_j)
    w_ij = w_i + w_j;
    alpha = w_i / w_ij;
    rect_ij = rect_i * alpha + rect_j * (1-alpha);
%    w_ij = max(w_i,w_j);
end

function [rect_ij,w_ij] = rect_merge_fn_max(rect_i,w_i, rect_j,w_j, src_i,src_j)
    w_ij = w_i + w_j;
    alpha = w_i / w_ij;
    rect_ij = rect_i * alpha + rect_j * (1-alpha);
    w_ij = max(w_i,w_j);
end


function [mean_angle,conf] = mean_angle(angles,weights)
    if ~exist('weights','var')
       weights = ones(length(angles),1);
    end
    x = cos(angles).*weights;
    y = sin(angles).*weights;
    mean_vec = [mean(x) mean(y)];
    mean_angle = atan2(mean_vec(2),mean_vec(1));
    conf = norm(mean_vec);
end
