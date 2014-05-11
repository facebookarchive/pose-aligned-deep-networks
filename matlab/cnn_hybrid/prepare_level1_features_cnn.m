%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [val_features, test_features] = prepare_level1_features_cnn(config, data)
% Evaluates features from CNNs on the training and validation examples

val_features = cell(config.N_poselet,1);
test_features = cell(config.N_poselet,1);
parfor p=1:config.N_poselet
    fprintf('Processing poselet %d\n',p);
    model_file = sprintf('%s/poselet_%d.bin', config.CNN_MODELS_DIR, p);
    if ~exist(model_file,'file')
       continue; 
    end
    hits_file = sprintf('%s/poselet_%d/phits.mat',config.CNN_PATCHES_DIR,p);
    if ~exist(hits_file, 'file');
        assert(config.DATASET==config.DATASET_LFW);
        continue;
    end
    phits = load(hits_file);
    feedforward_mex(p, model_file, ...
        config.CNN_PATCH_DIMS(1) - 2 * config.CNN_FRINGE, ...
        config.CNN_PATCH_DIMS(2) - 2 * config.CNN_FRINGE);
    patches = load(sprintf('%s/poselet_%d/patches.mat',config.CNN_PATCHES_DIR,p));
    if ~isempty(phits.val_idx) && config.DATASET==config.DATASET_LFW
        results = feedforward(p, patches.patches(:,:,:,phits.val_idx), config);
        dscores = phits.phits.score(phits.val_idx);
        val_features{p}.features = results'.*repmat(dscores,1,size(results,1));
        [qq1,val_features{p}.used]=ismember(phits.phits2allhits(phits.val_idx), data.val_idx);
        assert(all(qq1));
    end

    if ~isempty(phits.test_idx) && config.DATASET==config.DATASET_LFW
        results = feedforward(p, patches.patches(:,:,:,phits.test_idx), config);
        dscores = phits.phits.score(phits.test_idx);
        test_features{p}.features = results'.*repmat(dscores,1,size(results,1));
        [qq1,test_features{p}.used]=ismember(phits.phits2allhits(phits.test_idx), data.test_idx);
        assert(all(qq1));
    end
end

end

function results = feedforward(p, patches, config)
    f = config.CNN_FRINGE;
    dims = [size(patches,1) - 2*f, size(patches,2) - 2*f];
    if config.CNN_MULTIVIEW
       pt = [0 0; 2*f 0; 0 2*f; 2*f 2*f; f f];             
    else
       pt = [f f]; 
    end
    num_views = size(pt,1);
    num_samples = num_views * (config.CNN_MIRROR+1);    
    layers{1} = config.CNN_FEATURE_LAYER;
    for attr_id=1:length(config.FB_ATTR_NAME)
       layers{attr_id+1} = sprintf('probs_%s', config.FB_ATTR_NAME{attr_id}); 
    end

    feat = [];
    attr_scores = [];
    for i=1:num_views
        crops = patches(pt(i,1)+(1:dims(1)), pt(i,2)+(1:dims(2)),:,:);
        results = feedforward_mex(p, crops, f, f, layers);
        if isempty(feat)
            feat = nan(size(results{1},1)+length(results)-1,size(patches,4),num_samples,'single');
            attr_scores = nan(length(config.FB_ATTR_NAME),size(patches,4),'single');
        end
        for attr_id=1:length(config.FB_ATTR_NAME)
           attr_scores(attr_id,:) = results{attr_id+1}(1,:);
        end
        feat(:,:,i) = [results{1}; attr_scores];
        if (config.CNN_MIRROR)
            results = feedforward_mex(p, crops(:,end:-1:1,:,:), f, f, layers);
            for attr_id=1:length(config.FB_ATTR_NAME)
               attr_scores(attr_id,:) = results{attr_id+1}(1,:);
            end
            feat(:,:,num_views+i) = [results{1}; attr_scores];
        end
    end
    results = mean(feat,3);
end

