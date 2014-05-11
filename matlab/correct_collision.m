%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
all_image_ids = data.ohits.image_id;
collision_idx  = [];
%remove the collsion_set and rerun the collision_set then 
%find all the ohits.image_id not in data.phits.image_id rerun those
phits = data.phits;
for i = 1 : phits.size
    if isempty(find(all_image_ids == phits.image_id(i)))
        collision_idx = [collision_idx i];
    end
end

collision_ohits_idx = [];
for i = 1: length(all_image_ids)
    if isempty(find(phits.image_id == all_image_ids(i)))
        collision_ohits_idx = [collision_ohits_idx i];
    end
end
%delete collision and rerun collision_image_idx
right_phits = phits.select(setdiff([1:phits.size], collision_idx));
dpm_phits = get_dpm_hits(config,dpm_model, data.ohits.select(collision_ohits_idx));

%concatenate phits with dpm_phits
phits = right_phits.append(dpm_phits);