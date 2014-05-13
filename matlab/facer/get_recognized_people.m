%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [hits,ids] = get_recognized_people
out = dbquery(['SELECT object_hits_person_head.*,faceboxes.subject_id'...
    ' FROM faceboxes, object_hits_person_head' ...
    ' WHERE faceboxes.subject_id>0'... 
    ' AND object_hits_person_head.facebox_id=faceboxes.facebox_id'...
    ' LIMIT 1000000']);
 
data = textscan(out, '%d %u64 %d %d %d %d %d %f %s %u64');
hits = db_parse_into_objects_hitlist(data(1:8));
ids = data{10};

