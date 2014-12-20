%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level2_model=train_level2_cnn(train_labels, train_features, ...
    train_gfeatures, config)

level2_features_val = generate_level2_features_cnn(train_features,train_gfeatures,config);
clear train_features

tic;
fprintf('Training attribute classifier');
for attr_id = 1:size(train_labels,2)
    fprintf('%s ',config.ATTR_NAME{attr_id});
    %ignore those with labels = 0
    idx  = find(train_labels(:,attr_id) ~= 0);
    labels = (train_labels(idx,attr_id)>0)*2-1;
    level2_model{attr_id}.svm_weights = liblinear_do_train(labels,level2_features_val(idx,:));
end
fprintf('\n');
toc;
end

