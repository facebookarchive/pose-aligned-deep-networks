%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [faces,hyp_id] = dbfacer_query(query)
% Returns faceboxes generated from Facer.

out = dbquery(sprintf('select * from poselets.faceboxes where %s',query));
if isempty(out)
   faces = face_list;
   hyp_id = [];
else
    data = textscan(out, '%u64 %u64 %d %d %d %d %f %u64 %f %f %f %s %s');
    bounds = double([data{3} data{4} data{5} data{6}]');

    faces = face_list( ...
        bounds, ...% bounds
        data{7}, ...% score
        data{1}, ...% facebox_id
        data{2}, ...% image_id
        data{8}, ...% subject_id
        data{11},...% gender
        data{9}, ...% smiling
        data{10} ...% glasses
    );
    faces = scale_hits(faces, [0.67;0.85]*1.4);
    hyp_id = nan(length(data{12}),1);
    nonnull = ~ismember(data{12},'NULL');
    hyp_id(nonnull) = str2num(char(data{12}(nonnull)));
end
