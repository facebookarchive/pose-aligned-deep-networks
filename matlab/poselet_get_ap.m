%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function ap=poselet_get_ap(config, data, patches, phits, model_file, patch_dims)

% Computes the AP for a given DL classifier on a given poselet
if ~exist('patch_dims','var')
   patch_dims = config.CNN_PATCH_DIMS - 2 * config.CNN_FRINGE;
end
feedforward_mex(0, model_file, patch_dims(1), patch_dims(2));

if 0
     p = 59;
     patches = load(sprintf('%s/poselet_%d/patches.mat',config.CNN_PATCHES_DIR,p));
     phits = load(sprintf('%s/poselet_%d/phits.mat',config.CNN_PATCHES_DIR,p));
     model_file = sprintf('%s/poselet_%d.bin',config.CNN_MODELS_DIR,p);
     poselet_get_ap(config,data,patches.patches,phits,model_file,[24 24]);

     patches64 = load(sprintf('/home/lubomir/attributes/64/poselet_%d/patches.mat',p));
     phits64 = load(sprintf('/home/lubomir/attributes/64/poselet_%d/phits.mat',p));
     model_file = sprintf('/home/lubomir/attributes/64/poselet%d_4conv.bin',p);
     poselet_get_ap(config,data,patches64.patches,phits64,model_file,[56 56]);
end

f = config.CNN_FRINGE;
dims = [size(patches,1) - 2*f, size(patches,2) - 2*f];
crops = patches(f+(1:dims(1)),f+(1:dims(2)),:,:);
fprintf('Extracting training features...\n'); tic;
results = feedforward_mex(0, crops(:,:,:,phits.val_idx), f, f, config.CNN_FEATURE_LAYER);
val_features = results{1}'.*repmat(phits.phits.score(phits.val_idx),1,size(results{1},1));
[qq1, val_used]=ismember(phits.phits2allhits(phits.val_idx), data.val_idx);
assert(all(qq1));

fprintf('Extracting test features...\n');
layers{1} = config.CNN_FEATURE_LAYER;
for attr_id=1:size(data.attr_labels,2)
   layers{attr_id+1} = sprintf('probs_%s', config.ATTR_NAME{attr_id});
end
test_results = feedforward_mex(0, crops(:,:,:,phits.test_idx), f, f, layers);
test_features = test_results{1}'.*repmat(phits.phits.score(phits.test_idx),1,size(test_results{1},1));
[qq1, test_used]=ismember(phits.phits2allhits(phits.test_idx), data.test_idx);
assert(all(qq1));
toc;

fprintf('Training...\n');
for attr_id=1:size(data.attr_labels,2)
    val_labels = data.attr_labels(data.val_idx(val_used),attr_id);
    val_labels(val_labels<0) = -1;
    val_labels(val_labels>0) =  1;
    % train
    idx = find(val_labels~=0);
    svm_weights = liblinear_do_train(val_labels(idx), val_features(idx,:));

    % test
    assert(all(qq1));
    test_labels = data.attr_labels(data.test_idx(test_used),attr_id);
    idx = find(test_labels(:)~=0);
    test_labels = test_labels(idx);
    test_scores = svm_weights(1:(end-1))*test_features(idx,:)'+svm_weights(end);

    ap(attr_id) = get_precision_recall(test_scores, test_labels);

    test_scores = test_results{1+attr_id}(2,idx);
    ap2(attr_id) = get_precision_recall(test_scores, test_labels);
    
    fprintf('%4.2f/%4.2f ',ap(attr_id)*100, ap2(attr_id)*100);
end
fprintf('\nlocal3_neuron ap=%4.2f softmax ap=%4.2f \n',mean(ap*100),mean(ap2*100));

