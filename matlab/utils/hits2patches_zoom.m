%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
%%
function [patches, fail_idx] = hits2patches_zoom(hits,dims,zoom,model, sampling)
%add zoom feature for hits2patches 
%all_dims are the dimensionality for all poselets 
global config;
fail_idx =[];
patches = zeros([dims([2 1]) 3 hits.size],'uint8');
if hits.isempty
   return; 
end

for i = 1:length(model.svms)
    all_dims(model.svms{i}.svm2poselet,:) = repmat(model.svms{i}.dims, length(model.svms{i}.svm2poselet),1);
end

if ~exist('sampling','var') || isempty(sampling)
   sampling='bilinear'; 
end

parfor i=1:hits.size
    scale =  1/min(hits.bounds([3 4],i));
    pid = hits.poselet_id(i) + 1;    
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
         -all_dims(pid,[2 1])/(2*min(all_dims(pid,:)))-dims/2 1] * ...
         [zoom 0 0
         0 zoom 0
         0 0 1] * ...
         [1 0 0
         0 1 0
         dims*zoom/2 1];
                      
   src2unit_xforms(:,:,i) = double(unit2src_xform);
end

parfor h=1:hits.size
    img=load_image(hits.image_id(h), config);
    if ~isempty(img)
        patches(:,:,:,h) = transform_resize_crop(img, src2unit_xforms(:,:,h), dims, sampling, nan);
    else
        fail_idx = [fail_idx h];
    end
end
