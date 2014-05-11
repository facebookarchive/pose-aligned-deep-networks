%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function result = report_ap(level1_scores, level2_scores, level3_scores, labels, data, config)

if config.DATASET ~= config.DATASET_ICCV
% gender vs facer
sel = ~isnan(data.facer_attr(data.test_idx,1));
facer_ap = get_precision_recall(-data.facer_attr(data.test_idx(sel),1), labels(sel,1));
l2_ap = get_precision_recall(level2_scores(sel,1), labels(sel,1));
interp_facer_ap = get_precision_recall(...
    [-data.facer_attr(data.test_idx(sel),1); zeros(sum(~sel),1)], ...
    [labels(sel,1); labels(~sel,1)]);
fprintf('Gender on %d faces L2: %4.2f%% Facer: %4.2f%% InterpFacer: %4.2f%%\n', ...
    sum(sel), l2_ap*100, facer_ap*100, interp_facer_ap*100);

sel = ~isnan(data.facer_attr(data.test_idx,2));
facer_ap = get_precision_recall(data.facer_attr(data.test_idx(sel),2), labels(sel,4));
l2_ap = get_precision_recall(level2_scores(sel,4), labels(sel,4));

interp_facer_ap = get_precision_recall(...
    [data.facer_attr(data.test_idx(sel),2); zeros(sum(~sel),1)], ...
    [labels(sel,4); labels(~sel,4)]);
fprintf('Glasses on %d faces L2: %4.2f%% Facer: %4.2f%% InterpFacer: %4.2f%%\n', ...
    sum(sel), l2_ap*100, facer_ap*100, interp_facer_ap*100);
end

for attr=1:size(labels,2)
    parfor p=1:length(level1_scores)
        lab = labels(level1_scores{p}.used, attr);
        level1_ap(p,attr) = get_precision_recall(level1_scores{p}.scores(:,attr), lab);
    end
end

for attr_id=1:size(labels,2)
    lab = labels(:,attr_id);
    idx = (lab~=0);
    level2_ap(attr_id) = get_precision_recall(level2_scores(idx,attr_id), lab(idx));
    level3_ap(attr_id) = get_precision_recall(level3_scores(idx,attr_id), lab(idx));
    baseline = sum(data.attr_labels(data.train_idx,attr_id)>0) / sum(data.attr_labels(data.train_idx,attr_id)~=0);
    qqq = sort(level2_scores(idx,attr_id));
    acc_thresh = qqq(round(length(qqq)*baseline));
    acclabels=nan(sum(idx),1);
    acclabels(level2_scores(idx,attr_id) < acc_thresh) = -1;
    acclabels(level2_scores(idx,attr_id) >= acc_thresh) = 1;

    accuracy = mean(acclabels==lab(idx));
    fprintf('%-20s  baseline: %4.2f%% mean_l1: %4.2f%%   L2: %4.2f%%   L3: %4.2f%% acc: %4.2f%%\n', ...
        config.ATTR_NAME{attr_id}, baseline*100, mean(level1_ap(:,attr_id))*100, level2_ap(attr_id)*100, level3_ap(attr_id)*100, accuracy*100);
end

result.level1_ap = level1_ap;
result.level2_ap = level2_ap;
result.level3_ap = level3_ap;
