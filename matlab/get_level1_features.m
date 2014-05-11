%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [all_features, detection_scores, used] = get_level1_features(poselet_id, sel_idx, config)
qqq=load(fullfile(config.PHITS_DIR,sprintf('poselet_%s',num2str(poselet_id))));
phits=qqq.phits;

qqq=load(fullfile(config.FEATURES_DIR,sprintf('poselet_%s',num2str(poselet_id))));
features=qqq.features;
clear qqq;

assert(length(features) == phits.size);

%[idx,q2] = ismember([phits.image_id phits.cluster_id], sel_idx,'rows');
[~,in_phits, used] = intersect([phits.image_id phits.cluster_id], sel_idx,'rows');
features = features(in_phits);
detection_scores = phits.select(in_phits).score;

feature_dim = size([features(1).skin_fea features(1).color_hist features(1).hog],2);
all_features = zeros(numel(features),feature_dim);  
for i = 1:numel(features)
    all_features(i,:) = [features(i).skin_fea features(i).color_hist features(i).hog];
end
