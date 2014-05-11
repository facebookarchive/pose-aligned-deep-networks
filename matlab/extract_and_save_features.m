%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function extract_and_save_features(skin_gmm, config)
%extract features for prestored patches of poselet_id

for poselet_id = 1:config.N_poselet
    save_file = [config.FEATURES_DIR '/poselet_' num2str(poselet_id) '.mat'];
    if exist(save_file,'file')
       continue; 
    end
    fprintf('*******************Extract the %dth poselet features.********************\n',poselet_id);
    load(fullfile(config.PATCHES_DIR ,sprintf('poselet_%s',num2str(poselet_id))));
  
    parfor i=1:size(patches,4)
        patch = patches(:,:,:,i);
        features(i).skin_fea = get_skin_features(patch, skin_gmm, config);
        features(i).color_hist = get_color_histogram(patch,config);
        features(i).hog = patch2feature(patch,config);  
    end
   
    save(save_file,'features');
    clear features;
end
end

function chist = get_color_histogram(patch,config)
    hsv_patch = reshape(rgb2hsv(patch),[],3);
    chist = [hist(hsv_patch(:,1), config.ATTR_HIST_H_BINS) hist(hsv_patch(:,2), config.ATTR_HIST_S_BINS) ...
        hist(hsv_patch(:,3), config.ATTR_HIST_V_BINS)]/size(hsv_patch,1)*config.ATTR_COLORHIST_WEIGHT;
end

function skin_fea = get_skin_features(patch, skin_model,config)

skin_mask = min(1,(reshape(pdf(skin_model,img2lab_features(patch)),size(patch,1),[])/0.00001).^0.6);

cell_size = config.SKIN_CELL_SIZE;
for i = 1: ceil(size(skin_mask,1)/cell_size)
    for  j = 1:ceil(size(skin_mask,2)/cell_size)
        skin_mean(i,j) = mean(mean(skin_mask((i-1)*cell_size+1:min(i*cell_size,size(skin_mask,1)),...
                                             (j-1)*cell_size+1:min(j*cell_size,size(skin_mask,2)))));
    end
end

skin_fea = reshape(skin_mean,[1 size(skin_mean,1)*size(skin_mean,2)]);
end



function skin_fea = get_skin_features_masks(patch, skin_model, mask_hands, mask_legs, mask_neck)
skin_mask = min(1,(reshape(pdf(skin_model,img2lab_features(patch)),size(patch,1),[])/0.00001).^0.6);

skin_mask = skin_mask(4:end-3,4:end-3);
if sum(skin_mask(:)) < 0.000001
    skin_fea=[0 0 0];
    return;
end

skin_mask = skin_mask / sum(skin_mask(:));
skin_fea = [sum(sum(skin_mask.*mask_hands))*10000 sum(sum(skin_mask.*mask_legs))*10000 ...
    sum(sum(skin_mask.*mask_neck))*10000 ];
skin_fea(isnan(skin_fea)) = 0;
end



