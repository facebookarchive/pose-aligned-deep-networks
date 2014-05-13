%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function ohits=get_objects_of_hits(phits)
    ohits = hit_list;
    for i=1:phits.size
        h = dbobject_query(sprintf('photo_fbid=%d and hyp_id=%d',phits.image_id(i), phits.cluster_id(i)));
        ohits=ohits.append(h);
        disp(i);
    end
end