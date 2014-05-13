function [x,w,src_idx]=agglomerative_cluster(x,w,thresh,dist_fn,merge_fn,min_clusters)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% agglomerative clustering by Michael Anderson, UC Berkeley
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('min_clusters','var')
   min_clusters=1;
end

config.MAX_AGGLOMERATIVE_CLUSTER_ELEMS = 500;

if length(w)>config.MAX_AGGLOMERATIVE_CLUSTER_ELEMS
   [srt,srtd]=sort(w);
   weak_samples = srtd(1:(length(w)-config.MAX_AGGLOMERATIVE_CLUSTER_ELEMS));
   orig_idx=setdiff(1:length(w),weak_samples); % where elements are in orig order
   w(weak_samples) = [];
   x(weak_samples,:) = [];
else
   orig_idx=1:length(w);
end

% For each cluster, return a list of the original elements that comprise it
src_idx = cell(size(x,1),1);
for i=1:length(src_idx)
   src_idx{i}=uint32(orig_idx(i));
end

% Calculate distance matrix
distance_matrix = ones(size(x,1),size(x,1));
for i=1:size(x,1)
    d = dist_fn(x(i,:), x(i+1:size(x, 1),:));
    distance_matrix(i,:) = [ones(i,1)', d' ];
end

while 1
    % Now that I have the distances, find the global minimum
    [best_d,min_dist_ind] = min(distance_matrix(:));
    [best_i, best_j] = ind2sub(size(distance_matrix),min_dist_ind);
    best_pair = [best_i, best_j];

    % Stop when the min distance is large enough
    if best_d>thresh
       break;
    end

    % Might want to add something that breaks if size(x,1) < 2
    if size(x, 1) <= min_clusters
        break;
    end

    % merge i-th and j-th clusters
    i=best_pair(1);
    j=best_pair(2);

    % Come up with new bounding box and confidence value
    [x_ij,w_ij] = merge_fn(x(i,:),w(i), x(j,:),w(j),  src_idx{i},src_idx{j});
    x(i,:) = x_ij;
    w(i) = w_ij;
    src_idx{i} = [src_idx{i}; src_idx{j}];

    % Recalculate row/column
    d = dist_fn(x(i,:), x(i+1:size(x,1),:));
    distance_matrix(i,:) = [ones(i,1)' , d'];
    d = dist_fn(x(i,:), x(1:i-1,:));
    distance_matrix(:, i) = [d ; ones(size(x,1) - i + 1, 1)];

    % Delete j'th row/column
    m = 1 : size(x, 1);
    m_bin = (m ~= best_j);
    distance_matrix = distance_matrix(m_bin, m_bin);

    % Remove jth component from vectors
    x(j,:) = [];
    w(j) = [];
    src_idx(j) = [];
 end

