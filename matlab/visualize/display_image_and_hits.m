%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function display_image_and_hits(image_id, hits, params)
    img=load_image(image_id);
    query=sprintf('photo_fbid=%d',image_id);
    faces = dbfacer_query(query);
    people = dbperson_query(query);
    if exist('params','var') && isfield(params,'poselets_thresh')
       people = people.select(people.score>=params.poselets_thresh); 
    end
%    tags = get_free_tags(query);
    [label,overlap,truth_id] = match_hits_truths(people.bounds, people.score, faces.bounds, 0.3);

    imshow(img);
%    faces.select(truth_id).draw_bounds('y');
    faces.select(setdiff(1:faces.size,truth_id)).draw_bounds('r');
    people.select(label==1).draw_bounds('g', 0.5, '-', [1 0 0]);
    people.select(label~=1).draw_bounds('y', 0.5, '-', [1 0 0]);
%    tags.draw_bounds('b');
    title(sprintf('fbid=%d',image_id));
end