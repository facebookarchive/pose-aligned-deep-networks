%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level2_scores = test_level2(level2_model,level1_scores, config)

all_scores = generate_level2_features(level1_scores);
all_scores(:,~config.used_poselets) = 0;

%calculate the score of svm
for attr_id=1:size(all_scores,3)
    level2_scores(:,attr_id)= level2_model{attr_id}.svm_weights(1:(end-1))*all_scores(:,:,attr_id)'...
        + repmat(level2_model{attr_id}.svm_weights(end),1,size(all_scores,1));
    level2_scores(:,attr_id) = 1./(1+exp(level2_scores(:,attr_id)));    
end

end
