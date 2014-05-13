%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function matches = match_freetags_with_people(tags, heads)
% Matches free user tags with bounding boxes of poselet-detected heads

DEBUG = 0;

matches = zeros(tags.size,1);
image_ids = intersect(tags.image_id, heads.image_id);
for image_id = image_ids'
    head_sel=find(heads.image_id==image_id);
    tag_sel = find(tags.image_id==image_id);
    tagcoords = tags.bounds(1:2,tag_sel) + tags.bounds(3:4,tag_sel)/2;
    img_matches = match_tags_with_heads(tagcoords, heads.bounds(:,head_sel));
    matches(tag_sel(img_matches>0)) = head_sel(img_matches(img_matches>0));
    if DEBUG>0
       figure(1); clf;
       imshow(load_image(image_id));
       heads.select(head_sel).draw_bounds('g');
       hold on;
       color = [img_matches==0 img_matches>0 img_matches<0];
       scatter(tagcoords(1,:),tagcoords(2,:),100*ones(size(tagcoords,2),1), color,'filled');
       tags.select(tag_sel).draw_bounds('b');
    end
end
end

% Returns array of size size(tagcoords,2)
% Each value is either 0 (unmatched) or index in heads corresponding to the
% match
function matches = match_tags_with_heads(tagcoords, heads)
    Nheads = size(heads,2);
    Ntags = size(tagcoords,2);
    matches = zeros(Ntags,1);

    % Build a cost matrix
    weights = inf(Ntags,Nheads);
    for t=1:Ntags
        weights(t,:) = tag_head_dist(tagcoords(:,t), heads);
    end
    weights(weights>1) = inf;

    if all(isinf(weights(:)))
       return;
    end
    matching_mat = hungarian(weights);
    for t=1:Ntags
        fnd=find(matching_mat(t,:));
        if isempty(fnd)
            continue;
        end
        assert(isscalar(fnd));
        matches(t) = fnd;
    end
end

function wdst = tag_head_dist(tag_coords, heads)
    N = size(heads,2);
    head_ctr = heads(1:2,:) + heads(3:4,:).*repmat([0.5;1],1,N);
    head_sz = 1./mean(heads(3:4,:));

    dst = sqrt(sum((repmat(tag_coords, 1, N) - head_ctr).^2));
    wdst = dst.*head_sz;
end
