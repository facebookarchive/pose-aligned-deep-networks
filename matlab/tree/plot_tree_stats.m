%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function plot_tree_stats(root)
[statArray,tree_cost] = root.collect_stats(struct('parent',0,'dr',nan,'rr',nan,'pids',[], 'cost', nan, 'optcost', nan, 'is_fringe',0, 'is_optimal',0,'time',0), 1, 1, 1);
statArray = statArray(2:end);
parent = [statArray(:).parent]-1;
isleaf = ~ismember(1:length(parent), parent);

bf_cost = length(root.pids) * root.bin_dims(1);
fprintf('Tree cost: %f vs Brute force: %f. Speedup: %4.2f%%. Detection rate: %4.2f%%\n',tree_cost,bf_cost, 100*bf_cost/tree_cost, 100*mean([statArray(isleaf).dr]));
[x, y] = treelayout(parent);
figure; clf;
treeplot(parent); hold on;
for ii = 1:length(x)
    myStat = statArray(ii);
    if length(myStat.pids)>4
       pid_txt = sprintf('[%d]',length(myStat.pids));
    else
        pid_txt = num2str(myStat.pids);
    end
    assert(~(myStat.is_fringe && myStat.is_optimal));
    if myStat.is_fringe
        plot(x(ii), y(ii), 'o', 'Color', [0 1 0]);
    elseif myStat.is_optimal
        plot(x(ii), y(ii), 'o', 'Color', [0 0 1]);
    end
    text(x(ii),y(ii)+0.025, sprintf('pids=%s', pid_txt));
    text(x(ii),y(ii),sprintf('DR=%.1f%%',myStat.dr*100));
    text(x(ii),y(ii)-0.025,sprintf('RR=%.1f%%',myStat.rr*100));
    text(x(ii),y(ii)-0.05,sprintf('OptC=%.1f',myStat.optcost));
%    text(x(ii),y(ii)-0.075,sprintf('time=%.1f',myStat.time));
    text(x(ii),y(ii)-0.075,sprintf('C=%.1f',myStat.cost));
end
title(sprintf('Tree optimistic cost: %f. target dr: %f',root.cost, root.target_dr));
end

