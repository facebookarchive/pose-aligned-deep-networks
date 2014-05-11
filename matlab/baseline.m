%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function ap = baseline(ohits,features, ohits_labels, train_split)
%Baseline of just using boundingbox features + linear SVM

%construct the feature vector
assert(~isempty(features));
feature_dim = size([feature(1).skin_fea feature(1).color_hist feature(1).hog],2);
all_features = zeros(numel(feature),feature_dim);
for i = 1:numel(feature)
    all_features(i,:) = [feature(i).skin_fea feature(i).color_hist feature(i).hog];
end


%only train
idx1 = find(ismember([ohits.image_id ohits.cluster_id],...
    [train_split.photo_fbids(train_split.train_idx) train_split.hyp_ids(train_split.train_idx)],'rows') ~=0);
idx2 = find(ismember([ohits.image_id ohits.cluster_id],...
    [train_split.photo_fbids(train_split.val_idx) train_split.hyp_ids(train_split.val_idx)],'rows') ~=0);
idx = union(idx1,idx2);
train_features = all_features(idx,:);
scores = - ohits.select(idx).score;
attr_labels = ohits_labels(idx,:);
num_attr = size(attr_labels,2);

svm_weights = cell(1,num_attr);

for attr_id=1:num_attr
    labels = attr_labels(:,attr_id);
    assert(any(labels>=-1) && any(labels<=1));
    detection_scores = scores + 0.001;
    detection_scores = detection_scores.*abs(labels);
    %make labels = 1 or -1 or 0
    label_idx = find(labels > 0);
    labels(label_idx) = 1;
    label_idx = find(labels < 0);
    labels(label_idx) = -1;
    %ignore those whith labels = 0
    idx  = find(labels ~= 0);
    svm_weights{attr_id} = liblinear_do_train(labels(idx),train_features(idx,:),detection_scores(idx));
end

%only test
idx = find(ismember([ohits.image_id ohits.cluster_id],...
    [train_split.photo_fbids(train_split.test_idx) train_split.hyp_ids(train_split.test_idx)],'rows') ~=0);
test_features = all_features(idx,:);
attr_labels = ohits_labels(idx,:);


num_samples = size(feature,1);
for attr_id=1:num_attr
    svm_scores(:,attr_id) = svm_weights{attr_id}(1:end-1)*test_features'+...
        repmat(svm_weights{attr_id}(end),1, num_samples);
    labels = attr_labels(:,attr_id);
    assert(any(labels>=-1) && any(labels<=1));
    %make labels = 1 or -1 or 0
    label_idx = find(labels > 0);
    labels(label_idx) = 1;
    label_idx = find(labels < 0);
    labels(label_idx) = -1;
    %ignore those whith labels = 0
    idx  = find(labels ~= 0);
    ap(attr_id) = get_precision_recall(svm_scores(idx,attr_id),labels(idx));
end
end


