%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [val_patches,test_patches] = prepare_level1_global_patches(config, data)
fprintf('Extracting patches\n');
patch_dims = config.CNN_GLOBAL_MODEL_DIMS .* [2 1];
if 0 && config.DATASET == config.DATASET_ICCV
    % This is the old way of extracting global patches written by Lubomir
    % It may work better if we disable the mirroring. This codepath is
    % disabled for compatibility with the CVPR submission
  crop_dims = config.CNN_GLOBAL_MODEL_DIMS .* [2.5 1];
  val_patches_full = hits2patches(data.ohits.select(data.val_idx),crop_dims([2 1]));
  val_patches = zeros([patch_dims 3 size(val_patches_full,4)],'uint8');
  parfor i=1:size(val_patches_full,4)
    val_patches(:,:,:,i) = imresize(val_patches_full(:,:,:,i), patch_dims);
  end
  test_patches_full = hits2patches(data.ohits.select(data.test_idx),crop_dims([2 1]));
  test_patches = zeros([patch_dims 3 size(test_patches_full,4)],'uint8');
  parfor i=1:size(test_patches_full,4)
    test_patches(:,:,:,i) = imresize(test_patches_full(:,:,:,i), patch_dims);
  end
else
    [~, val_patches] = extract_person_patches(config,data.ohits.select(data.val_idx),patch_dims);
    [~, test_patches] = extract_person_patches(config,data.ohits.select(data.test_idx),patch_dims);
end
end


