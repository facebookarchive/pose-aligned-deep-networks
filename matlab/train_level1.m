%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level1_model = train_level1(train_indices, train_labels, config)
%This function trains first level classifier per poselet.
parfor p = 1:config.N_poselet
    level1_model{p} = train_attr_poselet(p,train_indices,train_labels, config);
end
end

function output = train_attr_poselet(poselet_id,train_indices,train_labels,config)
disp(sprintf('\n***TRAINING POSELET %d ***',poselet_id));

[all_features, scores, used] = get_level1_features(poselet_id,train_indices,config);
attr_labels = train_labels(used,:);
num_attr = size(attr_labels,2);

if(isempty(all_features))
    error('No training features');
end
output.svm_weights=nan(num_attr,size(all_features,2)+1);

for attr_id=1:num_attr
    labels = attr_labels(:,attr_id);
    assert(any(labels>=-1) && any(labels<=1));
    detection_scores = scores + 0.001; 
    detection_scores = detection_scores.*abs(labels);
    %ignore those whith labels = 0
    idx  = find(labels ~= 0);
    svm_weights=liblinear_and_logistic_train(all_features(idx,:),labels(idx,:),detection_scores(idx));
    output.svm_weights(attr_id,:) = single(svm_weights);
end
end

