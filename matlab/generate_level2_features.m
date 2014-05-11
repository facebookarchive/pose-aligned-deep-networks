%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level2_features = generate_level2_features(level1_scores)
%generate level2 features given level1 outputs
num_poselets = length(level1_scores);
num_attrs = size(level1_scores{1}.scores,2);
assert(num_attrs>0);

num_hyps = 0;
for p = 1:num_poselets
    num_hyps = max(num_hyps, max(level1_scores{p}.used));
end
level2_features = zeros(num_hyps,num_poselets,num_attrs);

for p = 1:num_poselets
    level2_features(level1_scores{p}.used,p,:) = level1_scores{p}.scores;
end
end
