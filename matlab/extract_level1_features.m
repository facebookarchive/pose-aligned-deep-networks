%%
%  Copyright (c) 2014, Facebook, Inc.
%  All rights reserved.
%
%  This source code is licensed under the BSD-style license found in the
%  LICENSE file in the root directory of this source tree. An additional grant
%  of patent rights can be found in the PATENTS file in the same directory.
%
%%
function [val_features, test_features] = ...
    extract_level1_features(config, data)
% Evaluates features from CNNs on the training and validation examples

val_features = cell(config.N_poselet,1);
test_features = cell(config.N_poselet,1);
for p = 1:config.N_poselet
    fprintf('Processing poselet %d\n',p);
    model_file = sprintf('%s/model_p_%d.caffenet', config.CNN_MODEL_DIR, p);
    if ~exist(model_file,'file')
        continue;
    end
    hits_file = sprintf('%s/poselet_%d/phits.mat',config.CNN_PATCHES_DIR,p);
    
    phits = load(hits_file);
    matcaffe_init(config.USE_GPU, config.PANDA_DEF, model_file);
    
    load_patches = load(sprintf('%s/poselet_%d/patches.mat',...
        config.CNN_PATCHES_DIR, p));
    patches = load_patches.patches;
    
    % load mean
    d = load([config.CNN_MODEL_DIR '/mean_' num2str(p) '.mat']);
    % central crop and subtract mean
    mean_1 = d.mean;
    mean_1 = permute(mean_1, [2 1 3]);
    
    patches = single(patches) - repmat(mean_1,[1 1 1 size(patches,4)]);
    f = config.CNN_FRINGE;
    dims = [size(patches,1) - 2*f, size(patches,2) - 2*f];
    patches = patches(f + (1:dims(1)), f + (1:dims(2)),:,:);
    
    if ~isempty(phits.val_idx)
        % has to use 100 as batch size according to PANDA def
        fea = [];
        input = cell(1,1);
        for j = 1:ceil(length(phits.val_idx)/100)
            input{1} = single(zeros(dims(1), dims(2), 3, 100));
            idx = [100 * (j - 1) + 1 : min(length(phits.val_idx), 100 * j)];
            input{1}(:, :, :, 1:length(idx)) = ...
                patches(:, :, :, phits.val_idx(idx));
            results = caffe('forward', input);
            results{1} = permute(results{1}, [3 1 2 4]);
            fea = [fea reshape(results{1}(:,:,:,1:length(idx)), ...
                [576 length(idx)])];
            clear results;
        end
        % multiply with poselet detection score
        dscores = phits.phits.score(phits.val_idx);
        val_features{p}.features = fea' .* repmat(dscores,1,576);
        [qq1,val_features{p}.used] = ...
            ismember(phits.phits2allhits(phits.val_idx), data.val_idx);
        assert(all(qq1));
    end
    
    if ~isempty(phits.test_idx)
        fea = [];
        input = cell(1,1);
        for j = 1 : ceil(length(phits.test_idx) / 100)
            input{1} = single(zeros(dims(1), dims(2), 3, 100));
            idx = [100*(j-1)+1 : min(length(phits.test_idx), 100*j)];
            input{1}(:,:,:,1:length(idx)) =...
                patches(:,:,:,phits.test_idx(idx));
            results = caffe('forward',input);
            results{1} = permute(results{1}, [3 1 2 4]);
            fea = [fea reshape(results{1}(:,:,:,1:length(idx)), ...
                [576, length(idx)])];
            clear results;
        end
        dscores = phits.phits.score(phits.test_idx);
        test_features{p}.features = fea'.*repmat(dscores,1,576);
        [qq1,test_features{p}.used]=ismember(phits.phits2allhits(phits.test_idx), data.test_idx);
        assert(all(qq1));
    end
    caffe('reset');
end

end
