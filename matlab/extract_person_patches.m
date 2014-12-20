%%
%  Copyright (c) 2014, Facebook, Inc.
%  All rights reserved.
%
%  This source code is licensed under the BSD-style license found in the
%  LICENSE file in the root directory of this source tree. An additional grant
%  of patent rights can be found in the PATENTS file in the same directory.
%
%%
function  [fail_idx, patches] = extract_person_patches(config, hits, dims, ...
    width_zoom, height_zoom,y_offset)
%Cropping people bounds

assert(config.DATASET == config.DATASET_ICCV);
bounds = int32(hits.bounds);
bounds(3:4,:) = bounds(3:4,:) + bounds(1:2,:);
bounds(1,:) = max(1,bounds(1,:));
bounds(2,:) = max(1,bounds(2,:));
patches = zeros([dims 3 hits.size],'uint8');
tic;
parfor i=1:hits.size
    img = load_image(hits.image_id(i),config);
    img = img(bounds(2,i):min(size(img,1),bounds(4,i)), ...
        bounds(1,i):min(size(img,2),bounds(3,i)),:);
    patches(:,:,:,i) = imresize(img, dims);
end
toc;
fail_idx = [];
end



