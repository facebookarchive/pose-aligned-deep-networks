%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function bg = find_background_people(people)
% Returns a boolean vector indicating, for each face instance
% whether it is considered 'background'. Currently background faces
% are faces that are less than half of the size of the largest face.

bg = false(people.size,1);
DEBUG = 0;
FACE_SIZE_THRESH = 0.5;
image_ids = unique(people.image_id);
head_size = (people.bounds(3,:)+people.bounds(4,:))/2;
for image_id = image_ids'
   sel = find(people.image_id==image_id);
   bg_sel = head_size(sel) < max(head_size(sel))*FACE_SIZE_THRESH;
   if any(bg_sel)
      bg(sel(bg_sel)) = true;
      if DEBUG>0
         figure(1); clf;
         imshow(load_image(image_id));
         people.select(sel(~bg_sel)).draw_bounds('g');
         people.select(sel( bg_sel)).draw_bounds('r');
      end
   end
end

end

