%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function append_to_attribute_table(table_name, attr_scores, photo_fbids, hyp_ids, ohits,gt_labels)

ATTR_NAME ={'is_male','has_long_hair','wear_hat','wear_glasses',...
    'wear_dress','wear_sunglasses','wear_short_sleeves','is_baby'};
assert(numel(attr_scores) == numel(ATTR_NAME));
%normalize attr_scores to be -1 to 1
for i = 1:numel(attr_scores)
    attr_scores{i} = 1./(1+exp(-attr_scores{i})) - 0.5;
end

ohits_bounds = ohits.bounds';
ohits_scores = ohits.score;

for i = 1:ceil(ohits.size/100)
    insert_values = [];
    i
    for j = 1:100
        id = (i-1) * 100 + j;
        if(id<=ohits.size)
        insert_value = sprintf('(%u, %d, %d, %d, %d, %d, %f, %d, %f, %d, %f, %d, %f, %d, %f, %d,%f,%d, %f, %d, %f, %d, %f),',photo_fbids(id), hyp_ids(id),...
            ohits_bounds(id,1), ohits_bounds(id,2), ohits_bounds(id,3), ohits_bounds(id,4) ,ohits_scores(id),...
            1, attr_scores{1}(id), 1 ,attr_scores{2}(id), 1, attr_scores{3}(id), 1, attr_scores{4}(id), ...
            1, attr_scores{5}(id), 1, attr_scores{6}(id), 1, attr_scores{7}(id), 1, attr_scores{8}(id)); 
        insert_values = [insert_values insert_value];
        end
    end
    insert_values(end)=[];
    
    dbquery(['INSERT ignore INTO ' table_name ' VALUES ' insert_values]);
end


end

