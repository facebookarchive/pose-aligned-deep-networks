%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function result = get_recognized_people_poselets(photo_fbids)
%Get poselet hits, object hits and subject_id for all recognized users
%If total photo not empty, just return those with photo_fbids
if isempty(photo_fbids)
    out = dbquery('select * from object_poselet_facebox_hit where subject_id!=0 limit 100000000');
else
    photo_query = sprintf('%d, ', photo_fbids);
    photo_query(end-1:end)='';
    out = dbquery(['select * from object_poselet_facebox_hit where subject_id!=0 and photo_fbid in (' photo_query ') limit 10000000']);
end

if isempty(out)
   phits = hit_list;
else
    data = textscan(out, '%d %u64 %d %d %d %d %d %d %f %d %d %d %d %f %u64 %u64');
    phits = hit_list( ...
        [data{10} data{11} data{12} data{13}]', ...% bounds
        data{14}, ...% score
        data{4}, ...% poselet_id
        data{2}, ...% image_id
        data{3} ...% cluster_id
     );
    ohits = hit_list( ...
        [data{5} data{6} data{7} data{8}]', ... %bounds
        data{9}, ... %score
        data{4}, ... %poselet_id
        data{2}, ... image_id
        data{3} ... %cluster_id
    );
    subject_id = data{16};
    facebox_id = data{15};
    result.phits = phits;
    result.ohits = ohits;
    result.facebox_id = facebox_id;
    result.subject_id = subject_id;
end


