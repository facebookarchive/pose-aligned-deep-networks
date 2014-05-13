%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [hits,facebox_ids,facebox_scores] = get_people_with_low_facer_confidence
out = dbquery(['SELECT object_hits_person_head.*,faceboxes.score FROM object_hits_person_head,faceboxes' ...
    ' WHERE object_hits_person_head.facebox_id=faceboxes.facebox_id'...
    ' AND faceboxes.score<=0.5'...
    ' LIMIT 1000000']);

data = textscan(out, '%d %u64 %d %d %d %d %d %f %u64 %f');
hits = db_parse_into_objects_hitlist(data(1:8));
facebox_ids = data{9};
facebox_scores = data{10};
