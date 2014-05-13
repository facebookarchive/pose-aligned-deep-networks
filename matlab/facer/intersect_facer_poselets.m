%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function intersect_facer_poselets(photo_ids)

% Intersects facer faceboxes with poselet people and stores the result in
% people_faceboxes_match table.

% BEFORE RUNNING do:
% create table people_faceboxes_match (
%   photo_fbid varchar(20) not null,
%   hyp_id int not null,
%   facebox_id bigint not null,
%   CONSTRAINT pk PRIMARY KEY (photo_fbid, hyp_id)
% );
%
% AFTER RUNNING, put the matches into object_hits_person_head:
%
% UPDATE object_hits_person_head
% SET object_hits_person_head.facebox_id=null;
% 
% UPDATE object_hits_person_head
% INNER JOIN people_faceboxes_match ON 
%    object_hits_person_head.photo_fbid=people_faceboxes_match.photo_fbid AND
%    object_hits_person_head.hyp_id=people_faceboxes_match.hyp_id
% SET object_hits_person_head.facebox_id=people_faceboxes_match.facebox_id 
%
%UPDATE faceboxes
%INNER JOIN people_faceboxes_match ON 
%   faceboxes.facebox_id=people_faceboxes_match.facebox_id 
%   SET faceboxes.hyp_id=people_faceboxes_match.hyp_id;

if ~exist('photo_ids','var')
    photo_ids=sscanf(dbquery('select photo_fbid from photo_urls where facedetect_run=true limit 1000000'),'%lu');
end

step = 20;
DEBUG = 0;
parfor i=1:ceil(length(photo_ids)/step)
    image_ids = photo_ids(((i-1)*step+1):min(length(photo_ids),i*step));
    
    in_str = sprintf('%u,',image_ids);
    in_str(end)=[];
    
    faces = dbfacer_query(sprintf('photo_fbid IN (%s) LIMIT 100000',in_str));
    people = dbperson_query(sprintf('photo_fbid IN (%s) LIMIT 100000',in_str));
    cmd = 'INSERT IGNORE INTO people_faceboxes_match (photo_fbid, hyp_id, facebox_id) VALUES ';
    inserted=false;
    for j=image_ids'
        people_in_img = people.select(people.image_id==j);
        if people_in_img.isempty
            continue;
        end
        faces_in_img = faces.select(faces.image_id==j);
        [label,overlap,truth_id] = match_hits_truths(people_in_img.bounds, people_in_img.score, faces_in_img.bounds, 0.3);
        if DEBUG>0
            img = load_image(j);
            imshow(img);
            faces_in_img.draw_bounds('r');
            people_in_img.select(label==1).draw_bounds('g');
            people_in_img.select(label~=1).draw_bounds('b');
            title(sprintf('fbid=%d',j));
            disp(overlap);
            pause;
        end
        for p=1:people_in_img.size
            fbid=0;
            if truth_id(p)>0
               fbid=faces_in_img.facebox_id(truth_id(p)); 
            end
            cmd = [cmd sprintf('(%u, %d, %u),', people_in_img.image_id(p), people_in_img.src_idx(p), fbid)];
            inserted=true;
        end
    end
    if inserted
        cmd(end)=[]; % remove the last coma.
        dbupdate(cmd);
        disp(i);
    end
end
end

