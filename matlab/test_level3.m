%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level3_scores = test_level3(level3_model, level2_scores, labels)
%Test level3 context layer classifier
num_attr = size(level2_scores,2);
num_hyps = size(level2_scores,1);

level3_scores = zeros(num_hyps, num_attr);
for attr_id = 1 : num_attr   
    [~,~,l3s]= svmpredict(labels(:,attr_id), level2_scores, level3_model{attr_id}.model);
    level3_scores(:,attr_id) = l3s * level3_model{attr_id}.model.Label(1);
end

end
