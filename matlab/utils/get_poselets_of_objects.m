%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function phits = get_poselets_of_objects(obj_hits)
    photo_list = sprintf('%u,',unique(obj_hits.image_id));
    photo_list(end) = [];
    tic;
    all_p = dbposelet_query(sprintf('photo_fbid in (%s) limit 1000000',photo_list));
    toc;
    for i=1:obj_hits.size
       phits(i)=all_p.select(all_p.image_id==obj_hits.image_id(i) &  all_p.cluster_id==obj_hits.cluster_id(i));       
    end
end