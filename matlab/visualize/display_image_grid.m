%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [h,dims_out,patch_dims] = display_image_grid(fbids, scale, labels, grid_dims)
global config;
N = length(fbids);
if N>200
   error('too many images to load');
end
if ~exist('labels','var')
   labels = [];
end

images = cell(N,1);
parfor i=1:N
    images{i}=imresize(load_image(fbids(i), config), scale);
end
patches = combine_patches_of_different_sizes(images);
if ~exist('grid_dims','var')
    [h,dims_out] = display_patches(patches, labels);
else
    [h,dims_out] = display_patches(patches, labels, grid_dims);
end
patch_dims = [size(patches,1) size(patches,2)];
end
