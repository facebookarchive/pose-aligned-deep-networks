%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
classdef tree
    % A tree-based multiclass classifier
    properties
        stripe_id;% int. Index of the stripe for the root node (1..num stripes)
        pids;     % array of int (which poselets are covered by the subtree)
        bin_dims; % [H W] of the number of cells for the poselet. The feature vector of the poselet has length prod(bin_dims)*36
        weights;  % array of N+1 of single (N=stripe length)
        children; % array of B tree nodes
        
        % for debugging
        dr;
        rr;
        cost;      % optimistic estimate of the cost of evaluation of this subtree
        train_idx; % indices of all training examples that pass through the node
        val_idx;   % indices of all val examples that pass through the node
        train_score;
        val_score;
        bf_cost, bf_dr, bf_rr;
        level;
        target_dr;
        time;
        
        next_states; % array of (array of 1 tree node, array of 2 tree nodes, etc)
        is_optimal; % is the cost real or optimistic estimate? I.e. has the code been fully explored?
    end
    
    methods
        function t = tree(pids, bin_dims, stripe_id, opt_cost, level)
            t.pids = pids;
            t.stripe_id = stripe_id;
            t.bin_dims = bin_dims;
            t.weights = [];
            t.next_states = [];
            t.is_optimal = false;
            t.cost = opt_cost;
            t.bf_cost = length(t.pids) * t.bin_dims(1);
            t.bf_dr = 1;
            t.bf_rr = 1;
            assert(t.cost <= t.bf_cost); % is it possible?
            t.train_idx = [];
            t.val_idx = [];
            t.level = level;
            t.target_dr = 0;
            t.time=0;
            t.train_score=[];
            t.val_score=[];
            
            t.dr = 1;
            t.rr = 1;
            t.children = [];
         end
        
        function isr = is_root(t)
            isr = (t.stripe_id==0);
            assert(isr == (t.level==0));
        end
        
        function ise = is_expanded(t)
            ise = ~isempty(t.train_idx);
        end
        
        % Expanding a node means creating the clusters of potential children sets
        % Also sets its cost based on the optimal estimate
        function [t,stats] = expand_node(t, model, examples, train_idx, val_idx, target_dr, children_dr, allow_single_child, ...
                train_score, val_score, stats)
            assert(~t.is_expanded);
            
            t.time = clock;
            % throw away positive examples not members of t.pid
            sel = examples.labels(train_idx)<0 | ismember(examples.labels(train_idx), t.pids);
            train_idx = train_idx(sel);
            train_score = train_score(sel);
            sel = examples.labels(val_idx)<0 | ismember(examples.labels(val_idx), t.pids);
            val_idx = val_idx(sel);
            val_score = val_score(sel);
            t.target_dr = target_dr;

            % Compute the brute_force cost
            % Train the classifier, filter the examples through it and
            % store the filtered indices            
            if t.is_root
               tic; 
               t.train_idx = train_idx;
               t.val_idx = val_idx;
               t.train_score = zeros(1,length(train_idx));
               t.val_score = zeros(1,length(val_idx));
            else
                % Train the classifier
                mask = t.get_stripe_mask;
                train_f = [examples.features(mask, train_idx); train_score];
                val_f = [examples.features(mask, val_idx); val_score];
                
                t.weights = train_svm(train_f, examples.labels(train_idx));
                
                % compute bf_alpha_dr and the bf_cost
                bf_alpha_dr = filter_at_dr(t.weights, train_f, examples.labels(train_idx), target_dr);
                [~,bf_filtered_idx] = filter_at_dr(t.weights, val_f, examples.labels(val_idx), target_dr);
                t.bf_dr = sum(examples.labels(val_idx(bf_filtered_idx))>0) / sum(examples.labels(val_idx)>0);
                t.bf_rr = sum(examples.labels(val_idx(bf_filtered_idx))<0) / sum(examples.labels(val_idx)<0);
                t.bf_cost = 1 + bf_alpha_dr * length(t.pids) * t.bin_dims(1);

                % Set the threshold by target_dr/children_dr 
                [~,~,thresh] = filter_at_dr(t.weights, train_f, examples.labels(train_idx), target_dr/children_dr);
                t.weights(end) = t.weights(end)-thresh;

                % Filter the examples through the threshold
                
                train_score = t.weights(1:(end-1)) * train_f + t.weights(end);
                t.train_idx = train_idx(train_score>0);
                t.train_score = train_score(train_score>0);
                
                val_score = t.weights(1:(end-1)) * val_f + t.weights(end);
                t.val_idx = val_idx(val_score>0);
                t.val_score = val_score(val_score>0);
                t.dr = sum(examples.labels(t.val_idx)>0) / sum(examples.labels(val_idx)>0);
                t.rr = sum(examples.labels(t.val_idx)<0) / sum(examples.labels(val_idx)<0);
                
                pos_train_idx = t.train_idx(examples.labels(t.train_idx)>0);
                num_pos_train = histc(examples.labels(pos_train_idx),1:max(t.pids));
                rel = num_pos_train(t.pids);
                if min(rel)<10
                   fprintf('Pos train examples of poselet %d are only %d!\n',find(rel==min(rel),1),min(rel));
                end
                
                pos_val_idx = t.val_idx(examples.labels(t.val_idx)>0);
                num_pos_val = histc(examples.labels(pos_val_idx),1:max(t.pids));
                rel = num_pos_val(t.pids);
                if min(rel)<10
                   fprintf('Pos val examples of poselet %d are only %d!\n',find(rel==min(rel),1),min(rel));
                end
            end
                        
            % create the potential children
            % Partition the pids into one, two, three and four clusters.
            min_clusters = (1-allow_single_child) + 1;
            max_clusters = min(model.max_children,length(t.pids));
            if min_clusters>max_clusters
                % we are not allowed to have a single-child cluster
                % (because our parent is a single child) and we only have
                % one poselet, so we cannot have 2+ clusters. The only
                % option is brute-force after filtering through the weights
               assert(~t.is_root);
               t.cost = t.bf_cost;  % bf cost after evaluating the classifier
               t.dr = t.bf_dr;
               t.rr = t.bf_rr;
               t.next_states = {};
               t.is_optimal = true;
               return;
            end
            
            % Construct children fringe nodes and set their cost to the
            % optimistic estimate
            
            % TODO A better estimate is 1 + child.rr * mean_pos_examples *
            % t.bin_dims(1) but it involves training the SVMs of all
            % children
            child_opt_cost = 1;
            t.next_states = cell(max_clusters-min_clusters+1,1);
            for cn = min_clusters:max_clusters
                clusters = t.cluster_in_k_clusters(model, t.pids, cn); % TODO: Improve clustering to use the actual train examples that made it to here
                for cc = 1:length(clusters)
                    t.next_states{cn-min_clusters+1}.children(cc) = tree(clusters(cc).pids, t.bin_dims, clusters(cc).stripe_id, child_opt_cost, t.level+1);  
                    stats.num_leaves = stats.num_leaves+1;
                end
            end
            
            % t.cost could be recomputed here from the cost of the children and bf_cost.
            % We update it later so that it is updated in only one place
        end
        
        % Explores the tree (tries different choices for children and
        % thresholds) by expanding the most promising subtrees first.
        % Expansion terminates until the guaranteed best cost (t.cost) increases by cost_increase_quota
        % or we fail to do so. May be called repeatedly
        function [t,stats] = find_optimal_tree(t, model, examples, train_idx, val_idx, target_dr, cost_increase_quota, ...
                allow_single_child, train_score, val_score, stats)
            assert(~t.is_optimal);
            initial_cost = t.cost;

            if t.is_root
                children_dr = target_dr;
            else
                children_dr = get_children_dr(target_dr, t.level, model);                                    
            end

            % Expand the node if not expanded already. Expansion is done
            % once only
            if ~t.is_expanded
                [t,stats] = t.expand_node(model, examples, train_idx, val_idx, target_dr, children_dr, allow_single_child, train_score, val_score, stats);
                if t.is_optimal
                    t.time = etime(clock,t.time);
                   return; 
                end
            end
            clear train_idx val_idx train_score val_score;            
            
            while true
                % Find the possible child set with best cost and expand on it
                childset_cost = nan(length(t.next_states), 1);
                for pcs_idx = 1:length(t.next_states)
                    childset_cost(pcs_idx) = sum([t.next_states{pcs_idx}.children(:).cost]);
                end
                
                [srt,srtd] = sort(childset_cost);
                t.cost = 1 + t.rr*srt(1); % lower bound of our cost is 1 + lower bound of the best choice for child set
                                
                if t.bf_cost <= t.cost
                   t.cost = t.bf_cost;
                   t.dr = t.bf_dr;
                   t.rr = t.bf_rr;
                   t.is_optimal = true;
                   t.children = [];
                   t.next_states = {};
                    t.time = etime(clock,t.time);
                   return; % we cannot increase cost further. Our optimistic estimate is worse than bf
                end
                                
                % Make sure the children point to the optimal possible
                % child sets          
                best_childset_idx = srtd(1);
                t.children = t.next_states{best_childset_idx}.children;
                
                if all([t.children(:).is_optimal])
                    % The children of the best next state are all optimal.
                    % That means that its cost is the correct (not
                    % optimistic estimate) and we cannot do better. So we
                    % are optimal too. (but we are not better than bf_cost
                    % otherwise we would have bailed above
                    t.is_optimal = true;
                    t.next_states = {};
                    t.time = etime(clock,t.time);
                    return;
                end

                if (t.cost - initial_cost >= cost_increase_quota)
                    return; % We achieved our quota
                end
                
                if (t.is_root)
                   fprintf('Num leaves: %d. current best cost: %f\n',stats.num_leaves,t.cost); 
                   stats.num_checkpoints = stats.num_checkpoints + 1;
                   if mod(stats.num_checkpoints, stats.checkpoint_break)==0
                      plot_tree_stats(t);
                      keyboard;
                   end
                end
                                
                best_cost = srt(1);                
                IMPROVEMENT_OVER_BEST = 0.001; % ask for meaningful improvement, otherwise the algorithm will keep switcing constantly and will be too slow
                if length(t.next_states)==1
                    local_quota = cost_increase_quota; % We may have a single set if we have very few poselets
                else
                    local_quota = min(cost_increase_quota, srt(2) - best_cost+IMPROVEMENT_OVER_BEST);     % initialize it to the differece between the best and second-best       
                end
                
                % At least one child of each of the next_states should not
                % be optimal. If we have a possible child set that is
                % optimal, then that should be our children and we should
                % be optimal too
                assert(~all([t.next_states{best_childset_idx}.children(:).is_optimal]));
                for child_idx = 1:length(t.next_states{best_childset_idx}.children)
                    if t.next_states{best_childset_idx}.children(child_idx).is_optimal
                        continue;
                    end
                    
                    old_child_cost = t.next_states{best_childset_idx}.children(child_idx).cost;
                    allow_single_child = length(t.next_states{best_childset_idx})>1;
                    [t.next_states{best_childset_idx}.children(child_idx),stats] = ...
                       t.next_states{best_childset_idx}.children(child_idx).find_optimal_tree(...
                       model, examples, t.train_idx, t.val_idx, children_dr, local_quota, allow_single_child, ...
                       t.train_score, t.val_score, stats);
                    cost_diff = t.next_states{best_childset_idx}.children(child_idx).cost - old_child_cost;
                    assert(cost_diff >= 0);
                    local_quota = local_quota - cost_diff;
                    
                    if (local_quota < 0)                        
                        % The child increased its optimal cost estimate and
                        % that was enough for us to reach our quota.
                        break;
                    end                    
                end
            end            
        end
                        
        % Partitions the pids into a set of cn clusters
        % returns an array of size cn, each element of which is a struct with fields:
        %   pids: a list of pids belonging to that cluster
        %   stripe_id: index of the stripe
        function clusters = cluster_in_k_clusters(t, model, pids, cn)
            assert(cn <= length(pids));
            
            % greedily pick the best nelms and make clusters out of them
            remaining_pids = pids;
            for c_id = 1:cn
                % pick the number of elems in a cluster
                nelms = ceil(length(remaining_pids) / (cn-c_id+1));
                clusters(c_id) = t.get_cluster_of_size_n(nelms, remaining_pids, model);
                remaining_pids = setdiff(remaining_pids, clusters(c_id).pids);
            end
        end
        
        % May return cluster of smaller than n size, if length(pids) < n
        function cluster = get_cluster_of_size_n(t, n, pids, model)
            assert(n>0);
            n = min(n, length(pids));
            
            asp = model.pid2asp(pids(1));
            assert(all(model.pid2asp(pids)==asp));
            [~, relIdx] = ismember(pids, model.svms{asp}.svm2poselet);
            
            cluster_sm = cell(1, t.bin_dims(1));
            cluster_cost = nan(1, t.bin_dims(1));
            
            tt =model.svms{asp}.svms(1:end-1,:);
            normSvms = tt ./ repmat( sqrt(sum(tt.^2, 1)), size(tt,1), 1);
            for sm=1:t.bin_dims(1)
                mask = t.get_stripe_mask(sm);
                svms = normSvms(mask, relIdx);
                [subset, cluster_cost(sm)] = select_best_subset(svms, n, mask, model.features_corr);
                cluster_sm{sm} = pids(subset);
            end
            [~, minid] = min(cluster_cost);
            cluster.stripe_id = minid;
            cluster.pids = cluster_sm{minid};
        end
        
        % Evaluate the tree and return indices and associated poselet_ids
        % for features to fully evaluate
        % Input:
        %    features: [F x N] of float where F = 36*prod(bin_dims)
        function [pids,idx,cost] = eval_tree(t, features, sample_weights)
            [feat_size,N] = size(features);
            assert(feat_size == 36*prod(t.bin_dims)+1);
            if isempty(t.weights)
                % root node
                all_idx = (1:N);
                cost = 0;
                scores = zeros(N,1);
            else
                cost = sum(sample_weights);
                scores = t.eval_node(features);
                if ~any(scores>=0)
                   pids = [];
                   idx = [];
                   return;
                end
                features = features(:,scores>=0);
                all_idx = find(scores>=0);
                sample_weights = sample_weights(scores>=0);
                scores = scores(scores>=0);
            end
            if isempty(t.children)
                % terminal node?
                [idx_g, pids_g] = meshgrid(all_idx, t.pids);
                idx = idx_g(:)';
                pids = pids_g(:);
                cost = cost + sum(sample_weights) * t.bin_dims(1) * length(t.pids);
            else
                idx = [];
                pids = [];
                features(end,:) = scores;
                for i=1:length(t.children)
                    [c_pids, c_idx, c_cost] = t.children(i).eval_tree(features, sample_weights);
                    idx = cat(2, idx, all_idx(c_idx));
                    pids = cat(1, pids, c_pids);
                    cost = cost + c_cost;
                end
            end
        end
                
        function [statArray, tree_cost] = collect_stats(t, statArray, parentID, parent_dr, parent_rr)
            myID = length(statArray) + 1;
            cumul_rr = t.rr * parent_rr;
            cumul_dr = t.dr * parent_dr;
            is_fringe = ~t.is_root && isempty(t.weights) && ~t.is_optimal;
            myStat = struct('parent', parentID, 'dr', cumul_dr, 'rr', cumul_rr, 'pids', t.pids, 'cost',nan, 'optcost',t.cost,'is_fringe',is_fringe,'is_optimal',t.is_optimal,'time',t.time);
            statArray = [statArray myStat];
                        
            if isempty(t.children) || is_fringe
                % Terminal node - bf
                children_cost_per_example = length(t.pids) * t.bin_dims(1);
            else
                cost = zeros(length(t.children),1);
                for i = 1:length(t.children)
                    [statArray,cost(i)] = t.children(i).collect_stats(statArray, myID, cumul_dr, cumul_rr);
                end
                children_cost_per_example = sum(cost);
            end
            
            % cost of evaluating our weights (1 for all but the root) +
            % weighted cost of children
            statArray(myID).cost = ~isempty(t.weights) + t.rr * children_cost_per_example;
            tree_cost = statArray(myID).cost;
        end
        
        function scores = eval_node(t, full_features)
            assert(~isempty(t.weights)); % Don't call it on the root node
            mask = t.get_stripe_mask_hw;
            scores = t.weights(1:(end-1)) * full_features(mask,:) + t.weights(end);
        end
                
        function mask = get_stripe_mask(t, stripe_id)
            if nargin<2
                stripe_id = t.stripe_id;
            end
            mask = false([36 t.bin_dims]);
            mask(:,stripe_id,:) = true;
            mask=mask(:);
        end
        function mask = get_stripe_mask_hw(t, stripe_id)
            if nargin<2
               stripe_id = t.stripe_id; 
            end
            mask = [t.get_stripe_mask(stripe_id); true];
        end
    end
end

function weights = train_svm(features, labels)
    frac_pos = mean(labels>0);
    neg_weight=(1-frac_pos) / frac_pos;
    hw = features(end,:);
    assert(length(hw) == length(labels));
    stdhw = std(hw);
    hw =  (hw - mean(hw)) / (stdhw + 1e-10);
    features(end,:) = hw;
    weights = liblinear_do_train((labels>0)*2-1, features', [], neg_weight);
    weights(end-1) = weights(end-1)*stdhw;            
end

function [alpha, filtered_idx, thresh] = filter_at_dr(weights, features, labels, target_dr)
    scores = weights(1:(end-1)) * features + weights(end);
    thresh = prctile(scores(labels>0), (1-target_dr)*100);
    filtered_idx = (scores>=thresh);
    alpha = mean(filtered_idx); % TODO: consider removing
end

