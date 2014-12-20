%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [ap,level2_scores] = test_level2_cnn(level2_model,test_labels,test_features,test_gfeatures, config)
%test level2 cnn

is_score = (size(test_features{1}.features,2) == 1);
level2_features_test = generate_level2_features_cnn(test_features,test_gfeatures,config);
clear test_features;
for attr_id = 1:size(test_labels,2)
    %%%test%%%
    %ignore those whith labels = 0
    idx  = find(test_labels(:,attr_id) ~= 0);

    if is_score
        level2_scores{attr_id} = level2_model{attr_id}.svm_weights'*level2_features_test';
    else        
        level2_scores{attr_id} = level2_model{attr_id}.svm_weights(1:end-1)*level2_features_test'+...
            level2_model{attr_id}.svm_weights(end);
    end
    ap(attr_id)= get_precision_recall(level2_scores{attr_id}(idx),test_labels(idx,attr_id));
end

for attr_id=1:length(ap)
   fprintf('%4.2f & ',ap(attr_id)*100);
end
fprintf(' mean AP=%4.3f\n',mean(ap)*100);

end
