%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function ap = eval_pure(pure_bin_file,  config)
%evaluate the pure deep learning model
load([config.CNN_PURE_PATCHES_DIR '/patches_split.mat']);
feedforward_mex(0, pure_bin_file, 56,56);
[train_features, train_labels] = get_pure_features(train_range, config);
[val_features, val_labels] = get_pure_features(val_range, config);
[test_features, test_labels] = get_pure_features(test_range, config);

%merge train and validation
train_features = [train_features; val_features];
train_labels = [train_labels; val_labels];

%train linear SVM
train_feature = power_sacle(train_feature);
num_attrs = numel(config.ATTR_NAME);
for attr_id = 1 : num_attrs
    idx  = find(labels ~= -1);
    fprintf('Train attribute  %d ... ...\n',attr_id);
    pure_model{attr_id}.svm_weights = liblinear_do_train(train_labels(idx,attr_id),train_features(idx,:));
end

test_features = power_scale(test_features);

for attr_id = 1 : num_attrs
    fprintf('Test attribute %d\n', attr_id);
    idx = find(labels ~= -1);
    pure_scores{attr_id} = pure_model{attr_id}.svm_weights(1:end-1)*test_features'+...
        pure_model{attr_id}.svm_weights(end);
    ap(attr_id)= get_precision_recall(pure_scores{attr_id}(idx),test_labels(idx,attr_id));
end
end

function [all_features, all_labels] = get_pure_features(all_range,config)
all_features = [];
all_labels = [];
for i = all_range
    load([config.CNN_PURE_PATCHES_DIR '/patches_' num2str(i) '.mat']);
    N_imgs = size(patches,5);
    patches = permute(patches, [4 1 2 3 5]);
    patches = patches(:,:,5:60,5:60,:);
    patches = reshape(patches, [3*4 56 56 N_imgs]);
    patches = permute(patches, [2 3 1 4]);
    results = feedforward_mex(0, patches, 4, 4, 'fcc');
    all_features = [all_features; results{1}'];
    load([config.CNN_PURE_PATCHES_DIR '/labels_' num2str(i) '.mat']);
    all_labels = [all_labels; labels];
end
end

function power_scale(features)
ppp = 0.3;
for i = 1:size(features,1)
    features(i,:) = sign(features(i,:)).*abs(features(i,:)).^ppp;
end
fprintf('Normalization: power %f\n',ppp);
end

