%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level2_model = train_level2(level1_scores, attr_labels, config)
%This function trains the second level classifier using validation data.
%attr_labels are [hyp num_attr], values are in [-1, 1].
num_attr = size(attr_labels,2);

train_scores = generate_level2_features(level1_scores);
train_scores(:,~config.used_poselets) = 0;

parfor attr_id = 1:num_attr
    labels = attr_labels(:,attr_id);
%    train_scores(:,:,attr_id) = train_scores(:,:,attr_id) .* repmat(abs(labels),1,150);
    %make labels = 1 or -1 or 0
    labels(labels > 0) = 1;
    labels(labels < 0) = -1;
    %ignore those whith labels = 0
    idx  = find(labels ~= 0);
    
    % Train max-margin
    svm_weights =  cvx_weights_train(train_scores(idx,:,attr_id), labels(idx,:), 1);

    % Train a logistic
    svm_scores = train_scores(idx,:,attr_id)*svm_weights;
    NN = sum(labels<0);
    NP = sum(labels>0);
    pw = sqrt(NN/(NP+1));
    md=liblinear_train(labels(idx,:),svm_scores,sprintf('-s 0 -q -B 1 -w1 %f',pw));
    logit_coeffs = md.w*md.Label(2);
    svm_weights = svm_weights * logit_coeffs(1);
    svm_weights = [svm_weights; logit_coeffs(2)];

    level2_model{attr_id}.svm_weights = svm_weights';
end
end



