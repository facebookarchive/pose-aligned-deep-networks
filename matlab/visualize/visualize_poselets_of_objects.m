%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function visualize_poselets_of_objects(phits, thresh)
qqq=load('~engshare/fbcode_data/vision/poselets/categories/person/model.mat');
masks = qqq.fg_masks;
clear qqq;
ar = zeros(length(masks),2);
for p=1:length(masks)
   dims4 = size(masks{p})/4;
   masks{p} = imresize(masks{p}(dims4(1):(dims4(1)*3-1),dims4(2):(dims4(2)*3-1)),2);
   ar(p,[2 1]) = size(masks{p});
end
[ar,~,p2ar]=unique(ar,'rows');
    
for i=1:length(phits)
    phits(i) = phits(i).select(phits(i).score>thresh);
end
all_hits = hit_list;
hyp_idx = [];
for i=1:length(phits)
   all_hits = all_hits.append(phits(i)); 
   hyp_idx = cat(1,hyp_idx,repmat(i,phits(i).size,1));
end
all_hits.poselet_id=all_hits.poselet_id+1;
[all_p,~,p2selp] = unique(all_hits.poselet_id);

sel = [];
for ari=1:size(ar,1)
    ari_sel=find(p2ar(all_hits.poselet_id)==ari);
    patches{ari}=hits2patches(all_hits.select(ari_sel), ar(ari,:), 'bicubic');
    if 1
    for i=1:length(ari_sel)
       mask = masks{all_hits.poselet_id(ari_sel(i))};
       patches{ari}(:,:,:,i) = uint8(double(patches{ari}(:,:,:,i)).*repmat(mask,[1 1 3]));
    end
    end
    sel = cat(1,sel,ari_sel);
end
cpatches = combine_patches_of_different_sizes(patches);
[H W D N] = size(cpatches);
grid = zeros([H W D length(all_p)*length(phits)],'uint8');

for i=1:length(sel)
	grid(:,:,:,length(all_p)*(hyp_idx(sel(i))-1) + p2selp(sel(i))) = cpatches(:,:,:,i);
end
display_patches(grid,[],[length(phits) length(all_p)]);

end
