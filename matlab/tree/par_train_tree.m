%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function root = par_train_tree(model, ar, examples, train_idx, val_idx, target_dr)

root = tree(model.svms{ar}.svm2poselet, model.svms{ar}.dims/8-1, 0, 1, 0);
   
stats.num_leaves = 0;
stats.num_checkpoints = 0;
stats.checkpoint_break = inf;

% Expand the grand children
children_dr = get_children_dr(target_dr, 0, model);

root = root.expand_node(model, examples, train_idx, val_idx, target_dr, children_dr, true, ...
    zeros(1,length(train_idx)), zeros(1,length(val_idx)), stats);
for i=1:length(root.next_states)
    for j=1:length(root.next_states{i}.children)
        allow_single_child = length(root.next_states{i}.children)>1;
        root.next_states{i}.children(j) = root.next_states{i}.children(j) ...
            .expand_node(model, examples, root.train_idx, root.val_idx, target_dr, children_dr, ...
            allow_single_child, root.train_score, root.val_score, stats);
    end
    % Assume the expansion did not make a subchild optimal.
    % This would complicate the logic
    assert(~all([root.next_states{i}.children(:).is_optimal]));
end

% collect array of grand children and
jobs = [];
for i=1:length(root.next_states)
    for j=1:length(root.next_states{i}.children)
        if root.next_states{i}.children(j).is_optimal
            continue;
        end
        for k=1:length(root.next_states{i}.children(j).next_states)
            % If these were optimal, their parent (children(j)) would be too
            assert(~all([root.next_states{i}.children(j).next_states{k}.children(:).is_optimal]));
            for l=1:length(root.next_states{i}.children(j).next_states{k}.children)
                if root.next_states{i}.children(j).next_states{k}.children(l).is_optimal
                   continue; 
                end
                jobs(end+1).node = root.next_states{i}.children(j).next_states{k}.children(l);
                jobs(end).allow_single_child = length(root.next_states{i}.children(j))>1;
                jobs(end).train_idx = root.next_states{i}.children(j).train_idx;
                jobs(end).val_idx = root.next_states{i}.children(j).val_idx;
                jobs(end).train_score = root.next_states{i}.children(j).train_score;
                jobs(end).val_score = root.next_states{i}.children(j).val_score;
                jobs(end).nodepath = [i j k l];
            end
        end
    end
end

fprintf('Expanded two levels for a total of %d leaves. Starting on %d jobs\n', length(jobs),matlabpool('size'));
tic;
% do the parallel tree evals
parfor i=1:length(jobs)
    jobs(i).node = jobs(i).node.find_optimal_tree(model, examples, ...
        jobs(i).train_idx, jobs(i).val_idx, children_dr, inf, jobs(i).allow_single_child, ...
        jobs(i).train_score, jobs(i).val_score, stats); 
    fprintf('%d ',i);
end

fprintf('Done in %f secs.\n',toc);

% put the computed nodes back in the tree
for i=1:length(jobs)
    np = jobs(i).nodepath;
    assert(jobs(i).node.is_optimal);
    root.next_states{np(1)}.children(np(2)).next_states{np(3)}.children(np(4)) = jobs(i).node;
end

% compute the cost and children
for i=1:length(root.next_states)
    for j=1:length(root.next_states{i}.children)
        root.next_states{i}.children(j) = make_optimal(root.next_states{i}.children(j));
    end
end
root = make_optimal(root);
end

% Assumes the next_states children are optimal. Recomputes its cost to be
% optimal
function node = make_optimal(node)
    if node.is_optimal
        return;
    end
    assert(isempty(node.children)); % the node should not have started exploring
    cost = nan(length(node.next_states),1);
    for i=1:length(node.next_states)
       assert(all([node.next_states{i}.children(:).is_optimal]));
       cost(i) = sum([node.next_states{i}.children(:).cost]);
    end
    [mincost,min_idx] = min(cost);
    node.cost = ~node.is_root + node.rr * mincost;
    if node.bf_cost < node.cost
       node.cost = node.bf_cost;
       node.dr = node.bf_dr;
       node.rr = node.bf_rr;
       node.children = [];
    else
       node.children = node.next_states{min_idx}.children;
    end
    node.is_optimal = true;
    node.time = etime(clock,node.time);
    node.next_states = {};
end

