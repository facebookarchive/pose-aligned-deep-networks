%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function patches = hits2patchesOLD(hits,dims,sampling)
global config;
patches = zeros([dims([2 1]) 3 hits.size],'uint8');
if hits.isempty
   return; 
end
if ~exist('sampling','var') || isempty(sampling)
   sampling='bilinear'; 
end

[~,foo,hit2img] = unique(hits.image_id,'legacy');
image_ids=hits.image_id(foo); % workaround for matlab bug!

N = length(image_ids);
image = cell(N,1);
parfor i=1:N
    image{i} = load_image(image_ids(i), config);
end


parfor i=1:hits.size
    scale = 1/min(hits.bounds([3 4],i));
    tr = hits.bounds([1 2],i)';
    unit2src_xform = ...
        [1 0 0
         0 1 0
         -tr 1] * ...
         [scale 0 0
          0 scale 0
          0 0 1] * ...
        [1 0 0
         0 1 0
         -dims/(2*min(dims)) 1];
           
   src2unit_xforms(:,:,i) = double(unit2src_xform);
end

patches = zeros([dims(2) dims(1) 3 hits.size],'uint8');
parfor h=1:hits.size
    img=image{hit2img(h)};
    if ~isempty(img)
        try
            patches(:,:,:,h) = transform_resize_crop(img, src2unit_xforms(:,:,h), dims, sampling, nan);
        catch
            patches(:,:,:,h) = imresize(image{h}, [dims(2) dims(1)]);
        end
    end
end
