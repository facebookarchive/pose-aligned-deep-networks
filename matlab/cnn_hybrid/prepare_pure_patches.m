%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [train_range, val_range, test_range] = prepare_pure_patches(data, config)
%prepare patches for pure deep learning models
%return train_range val_range and test_range which are the batches numbers
%for the split

%CNN takes labels input -1 as uncertain and 0 as negative
attr_labels = data.attr_labels;
attr_labels(attr_labels>0) = 1;
attr_labels(attr_labels ==0) = 2;
attr_labels(attr_labels<0) = 0;
attr_labels(attr_labels ==2) = -1;

[train_range, mean_patches] = prepare_pure(data.ohits.select(data.train_idx), ...
                              attr_labels(data.train_idx,:), 0, config);
[val_range, ~] = prepare_pure(data.ohits.select(data.val_idx), ...
                  attr_labels(data.val_idx,:), max(train_range),config);
[test_range, ~] = prepare_pure(data.ohits.select(data.val_idx),...
                 attr_labels(data.test_idx,:), max(val_range), config);

save([config.CNN_PURE_PATCHES_DIR '/mean_patches.mat'], 'mean_patches');
save([config.CNN_PURE_PATCHES_DIR '/patches_split.mat'], 'train_range','val_range','test_range');
end

function [batch_range, mean_patches] = prepare_pure(ohits, attr_labels, batch_start, config)
%save the patches given the ohits and return batch range and mean patches
max_batch_size = 2000;
sum_patches = zeros(4, 64, 64, 3);
batch_range = [];
for batch_num = 1 : ceil(ohits.size / max_batch_size)
    fprintf('Processing pure patch %d \n', batch_num)
    idx = [ (batch_num - 1) * max_batch_size + 1 : min(batch_num* max_batch_size, ohits.size)];
    [fail_idx, patches] = extract_person_patches(config, ohits.select(idx), [64 128]);
    pure_poselet_patches = zeros(4,64,64,3,length(idx));
    pure_poselet_patches(1,:,:,:,:) = patches(1:64, :,:,:);
    pure_poselet_patches(2,:,:,:,:) = patches(33:96, :,:,:);
    pure_poselet_patches(3,:,:,:,:) = patches(65:128, :,:,:);
    [fail_idx, patches] = extract_person_patches(config, ohits.select(idx), [64 64]);
    pure_poselet_patches(4,:,:,:,:) = patches;
    sum_patches = sum_patches  + sum(pure_poselet_patches,5);
    patches = pure_poselet_patches;
    labels = attr_labels(idx,:);
    batch_range = [batch_range batch_num+batch_start];
    save([config.CNN_PURE_PATCHES_DIR '/patches_' num2str(batch_num + batch_start) '.mat'], 'patches');
    save([config.CNN_PURE_PATCHES_DIR '/labels_' num2str(batch_num + batch_start) '.mat'], 'labels');
end
mean_patches = sum_patches / ohits.size;
end