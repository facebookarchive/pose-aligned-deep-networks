%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function features = prepare_level1_global_features(patches, config)
dims = config.CNN_GLOBAL_MODEL_DIMS;
crop_dims = dims - 2 * config.CNN_GLOBAL_FRINGE;
N = size(patches,4);

% Change the input_dim to be 100 in the deploy.prototxt
matcaffe_init(config.USE_GPU, config.GLOBAL_DEF, config.GLOBAL_MODEL);

d = load(config.GLOBAL_MEAN_FILE);
IMAGE_MEAN = d.image_mean;

% permute from RGB to BGR (IMAGE_MEAN is already BGR)
patches = patches(:, :, [3 2 1], :);
features = zeros(N, 4096 * 2);
input = cell(1, 1);
for i = 1 : ceil(N/ 100)
    fprintf('Extract global features for batch %d\n',i);
    idx = [100 * (i - 1) + 1 : min(N, 100 * i)];
    input{1} = single(zeros(crop_dims(1), crop_dims(2), 3, 100));
    % the top half
    patches_1 = single(patches(1:dims(1),:,:,idx)) - repmat(IMAGE_MEAN, [1 1 1 length(idx)]);
    % flip width and height to make width the fastest dimension
    patches_1 = permute(patches_1, [2 1 3 4]);
    input{1}(:, :, :, 1:length(idx)) = patches_1(config.CNN_GLOBAL_FRINGE + (1:crop_dims(1)), ...
             config.CNN_GLOBAL_FRINGE + (1:crop_dims(2)), :, :);
    results = caffe('forward', input);
    fea_top = reshape(results{1}, [4096 100]);
    clear results;
    fea_top = fea_top(:, 1:length(idx));
    
    % the bottom half
    patches_2 = single(patches((dims(1)+1): (dims(1)*2),:,:,idx)) - repmat(IMAGE_MEAN, [1 1 1 length(idx)]);
    patches_2 = permute(patches_2, [2 1 3 4]);
    input{1}(:, :, :, 1:length(idx)) = patches_2(config.CNN_GLOBAL_FRINGE + (1:crop_dims(1)),...
        config.CNN_GLOBAL_FRINGE + (1:crop_dims(2)), :, :);
    results = caffe('forward', input);
    fea_bottom = reshape(results{1}, [4096 100]);
    fea_bottom = fea_bottom(:, 1:length(idx));
    features(idx, :)  = [fea_top' fea_bottom'];
end

