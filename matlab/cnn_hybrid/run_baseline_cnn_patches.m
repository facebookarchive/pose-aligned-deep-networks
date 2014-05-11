%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
%%%TRAIN LEVEL1%%%
for poselet_id = 1:50
    poselet_id
    patches = patches_comb{poselet_id};
    labels = labels_comb{poselet_id};
    phits = level1_phits{poselet_id};
    load(['cnn_patch_features/poselet_' num2str(poselet_id)])
    %features = extract_features_from_patch(patches,skin_gmm,config);
    %only train
    idx = ismember(phits.image_id, train_split.photo_fbids(train_split.train_idx)) &...
        ismember(phits.cluster_id, train_split.hyp_ids(train_split.train_idx));
    features = features(idx);
    scores = phits.select(idx).score;
    attr_labels = labels(idx);
    num_attr = size(attr_labels,2);
    
    if(isempty(features))
        output=[];
        return;
    end
    
    feature_dim = size([features(1).skin_fea features(1).color_hist features(1).hog],2);
    all_features = zeros(numel(features),feature_dim);
    for i = 1:numel(features)
        all_features(i,:) = [features(i).skin_fea features(i).color_hist features(i).hog];
    end
    
    output{poselet_id}.svm_weights=nan(num_attr,size(all_features,2)+1);
    
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
        svm_weights=liblinear_and_logistic_train(all_features(idx,:),labels(idx,:),detection_scores(idx));
        output{poselet_id}.svm_weights(attr_id,:) = single(svm_weights);
    end
end

%%%TEST LEVEL1%%%
for poselet_id = 1:50
    load(['cnn_patch_features/poselet_' num2str(poselet_id)])
    disp(sprintf('\n*** POSELET %d ***',poselet_id));
    
    if(isempty(features) || isempty(output{poselet_id}))
        poselet_scores=[];
        return;
    end
    
    feature_dim = size([features(1).skin_fea features(1).color_hist features(1).hog],2);
    all_features = zeros(numel(features),feature_dim);
    for i = 1:numel(features)
        all_features(i,:) = [features(i).skin_fea features(i).color_hist features(i).hog];
    end
    
    num_attr = size(output{poselet_id}.svm_weights,1);
    num_samples = size(all_features,1);
    for attr_id=1:num_attr
        poselet_scores(:,attr_id) = output{poselet_id}.svm_weights(attr_id,1:(end-1))*all_features' ...
            + repmat(output{poselet_id}.svm_weights(attr_id,end),1,num_samples);
    end
    level1_scores{poselet_id} = 1./(1 + exp(poselet_scores));
    clear poselet_scores;
end


 attr_labels = get_attr_labels(config.TABLE, config.ATTR_NAME, train_split.photo_fbids, train_split.hyp_ids);
%%%TRAIN LEVEL2%%%%
select_photo_fbids = train_split.photo_fbids(train_split.val_idx);
select_hyp_ids = train_split.hyp_ids(train_split.val_idx);
level2_features = zeros(length(select_photo_fbids),50,num_attr);
for poselet_id = 1: 50
    phits = level1_phits{poselet_id};
    %only selected
    idx = ismember(phits.image_id, select_photo_fbids) & ismember(phits.cluster_id, select_hyp_ids);
    image_ids = phits.select(idx).image_id;
    hyp_ids = phits.select(idx).cluster_id;
    detection_scores = phits.select(idx).score;
    scores = level1_scores{poselet_id}(idx);
    
    for i = 1:length(scores)
        idx =find(select_photo_fbids == image_ids(i) & ...
            select_hyp_ids == hyp_ids(i));
        level2_features(idx,poselet_id,:) = (scores(i,:)-0.5)*detection_scores(i);
    end
end

for attr_id = 1:num_attr
    labels = attr_labels(train_split.val_idx,attr_id);
    level2_features(:,:,attr_id) = level2_features(:,:,attr_id) .* repmat(abs(labels),1,50);
    %make labels = 1 or -1 or 0
    label_idx = find(labels > 0);
    labels(label_idx) = 1;
    label_idx = find(labels < 0);
    labels(label_idx) = -1;
    %ignore those whith labels = 0
    idx  = find(labels ~= 0);
    svm_weights =  cvx_weights_train(level2_features(idx,:,attr_id), labels(idx,:), 1);
    level2_model{attr_id}.svm_weights = svm_weights';
end

%%%TEST LEVEL2%%%%
select_photo_fbids = train_split.photo_fbids(train_split.test_idx);
select_hyp_ids = train_split.hyp_ids(train_split.test_idx);
level2_features = zeros(length(select_photo_fbids),50,num_attr);
for poselet_id = 1: 50
    phits = level1_phits{poselet_id};
    %only selected
    idx = ismember(phits.image_id, select_photo_fbids) & ismember(phits.cluster_id, select_hyp_ids);
    image_ids = phits.select(idx).image_id;
    hyp_ids = phits.select(idx).cluster_id;
    detection_scores = phits.select(idx).score;
    scores = level1_scores{poselet_id}(idx);
    
    for i = 1:length(scores)
        idx =find(select_photo_fbids == image_ids(i) & ...
            select_hyp_ids == hyp_ids(i));
        level2_features(idx,poselet_id,:) = (scores(i,:)-0.5)*detection_scores(i);
    end
end

for attr_id=1:num_attr
    labels = attr_labels(train_split.test_idx,attr_id);
    %make labels = 1 or -1 or 0
    label_idx = find(labels > 0);
    labels(label_idx) = 1;
    label_idx = find(labels < 0);
    labels(label_idx) = -1;
    %ignore those whith labels = 0
    idx  = find(labels ~= 0);
    num_samples = size(level2_features(idx,:),1);
    
    level2_scores(:,attr_id) = level2_model{attr_id}.svm_weights(attr_id,:)*level2_features(idx,:,attr_id)';
    ap(attr_id) = get_precision_recall(level2_scores(:,attr_id),labels(idx));
    
end

