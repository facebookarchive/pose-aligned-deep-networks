%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function patches=extract_patches(hits, dims)
    image_ids = unique(hits.image_id);
    parfor i=1:length(image_ids)
       image{i} = load_image(image_ids(i)); 
    end
    
end