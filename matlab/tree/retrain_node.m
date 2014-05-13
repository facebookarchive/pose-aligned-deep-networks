%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function retrain_node(parent, child_idx, model, examples)
    stats.num_leaves = 0;
    stats.num_checkpoints = 0;
    stats.checkpoint_break = inf;
    node = parent.children(child_idx);
    nodecopy = node;
    assert(node.is_optimal);
    node.is_optimal = false;
    node.train_idx = []; % to force it to expand
    allow_single_child = length(node.children)>1; % cheating: In the optimal did it converge to single? If so allow.
    node = node.find_optimal_tree(model, examples, parent.train_idx, parent.val_idx, node.target_dr, inf, ...
        allow_single_child, parent.train_score, parent.val_score, stats);    
    if ~isequal(node, nodecopy)
       disp('Not equal!');
       stop=0;
    else
        disp('Equal');
    end
end