%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level1_scores = test_level1(level1_model, test_idx, config)
%This function tests level1 classifier per poselet. 
parfor poselet_id = 1:config.N_poselet
    [level1_scores{poselet_id}.scores, level1_scores{poselet_id}.used] ...
      = test_attr_poselet(poselet_id,level1_model{poselet_id},test_idx,config);
end
end

function [poselet_scores, used] = test_attr_poselet(poselet_id, level1_model, test_idx, config)

fprintf('.');

[all_features, detection_score, used] = get_level1_features(poselet_id,test_idx,config);

num_attr = size(level1_model.svm_weights,1);
num_samples = size(all_features,1);
for attr_id=1:num_attr
     poselet_scores(:,attr_id) = level1_model.svm_weights(attr_id,1:(end-1))*all_features' ...
         + repmat(level1_model.svm_weights(attr_id,end),1,num_samples);
end
poselet_scores = 1./(1 + exp(poselet_scores));
poselet_scores = (poselet_scores - 0.5).*repmat(detection_score,[1 num_attr]);
end


