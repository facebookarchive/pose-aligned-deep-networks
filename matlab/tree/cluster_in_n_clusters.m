%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [clusters, stripeArray, subtrees]= cluster_in_n_clusters(model, pids, cn)
    % root is a of the hierarchical clustering tree.
    % cluster_in_n_cluster returns a cell array of size cn
    P = find_node_with_pids(model.svms{model.pid2asp(pids(1))}.clustering_tree, pids);
    assert(~isempty(P));
    assert(cn>0);
    if isempty(P.children) % leaf node!
       clusters = {P.pids}; 
       subtrees = P;
       assert(~isempty(P.distance)); % make sure singletons have distances too
       stripeArray = subtrees.stripe_I;
       return;
    end
    
    if cn == 1, 
        clusters={P.pids};
        subtrees=P;
        stripeArray = subtrees.stripe_I;
        return; 
    end
    if cn >= 2,
        % repeatedly expand the subtree list by replacing a node with the largest distance into its children 
        unexplored = true(1, length(P.children));
        subtrees = P.children;
        while length(subtrees)<cn
            valid_distance = [subtrees(unexplored).distance];
            if isempty(valid_distance), break; end % can't expand anymore
            [~,relidx] = max(valid_distance); % get relative idx of max among the unexplored nodes
            unexplored_idx = find(unexplored);
            this_idx = unexplored_idx(relidx);  % get absolute idx (w.r.t subtrees)
            if ~isempty(subtrees(this_idx).children) 
                % this node is not a singleton, add its children
               subtrees = cat(2, subtrees, subtrees(this_idx).children);
               unexplored = cat(2, unexplored, true(1, length(subtrees(this_idx).children)));
               % and remove this node
               subtrees(this_idx) = [];
               unexplored(this_idx) = [];
            else
                % this node is a singleton, mark this node as explored
                unexplored(this_idx) = false; 
            end
        end
        cn = length(subtrees);
        clusters = cell(cn,1);
        stripeArray = nan(cn, 1);
        for ci=1:cn
           clusters{ci} = subtrees(ci).pids; 
           stripeArray(ci) = subtrees(ci).stripe_I;
        end
    end
    
end

function node = find_node_with_pids(node, pids)
    setequal = @(a,b) isempty(setdiff(a,b)) && isempty(setdiff(b,a));
    if all(ismember(pids, node.pids))
        if setequal(pids, node.pids)
            return;
        else
            for i = 1:length(node.children)
                child = find_node_with_pids(node.children(i), pids); 
                if ~isempty(child), 
                    node = child;
                    return;
                end
            end
        end
    end
    node = []; 
end

        