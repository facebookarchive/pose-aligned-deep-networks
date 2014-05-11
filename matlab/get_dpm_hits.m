%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function dpm_phits = get_dpm_hits(config, dpm_model, ohits)
%input is the original data, do dpm detections 
load('dpm_parts_correction');
N_parts = 8;
total_phits = 0;
for i = 1:numel(dpm_parts)
    if ~isempty(dpm_parts{i})
        total_phits = total_phits +N_parts;
    end
end
% dpm_parts = cell(length(ohits.image_id), 1);
% total_phits = 0;
% N_parts = 8;
% [fail_idx, bounds] = extract_person_bounds(config, ohits);
% 
% parfor i = 1:length(ohits.image_id);
%     fprintf('DPM detection: %d/%d\n', i, length(ohits.image_id));
%     bbox = bounds(i,:);
%     im =load_image(ohits.image_id(i), config);
%     [dets, boxes] = imgdetect(im, dpm_model, dpm_model.thresh,bbox,0.65);
%     if ~isempty(boxes)
%         boxes = reduceboxes(dpm_model, boxes);
%         [dets boxes] = clipboxes(im, dets, boxes);
%         I = nms(dets, 0.5);
%         dpm_parts{i} = boxes(I(1),:);
%         total_phits = total_phits + N_parts;
%     else
%         dpm_parts{i} = [];
%     end 
% end

%save('dpm_parts_fb','dpm_parts','-v7.3');
% q = load('../DPM/human_weak_train.mat');
% N_TRN = numel(q.parts1);
% dpm_parts(1:N_TRN) = q.parts1;
% q = load('../DPM/human_weak_test.mat');
% N_TST = numel(q.parts1);
% dpm_parts(N_TRN+1: N_TRN+N_TST) = q.parts1;

bounds = zeros(4, total_phits);
poselet_id = zeros(total_phits,1); %corresponding to dpm ids (6*8 poselets in total)
score = zeros(total_phits,1); %need convert dpm score to logistic function or something
image_id = zeros(total_phits,1,'uint64');
cluster_id = zeros(total_phits,1);
cur_phits = 1;

for i = 1 : length(ohits.image_id)
    if ~isempty(dpm_parts{i})
        %create 8 poselet parts
        for p = 1:N_parts
            bounds(:, cur_phits) = dpm_parts{i}(1,p*4+1 : (p+1)*4)';
            bounds(3, cur_phits) = bounds(3, cur_phits) - bounds(1, cur_phits);
            bounds(4, cur_phits) = bounds(4, cur_phits) - bounds(2, cur_phits);
            poselet_id(cur_phits) = (dpm_parts{i}(1,end-1)-1) * N_parts + p - 1;
            %score(cur_phits) = 1/(1+ exp(-dpm_parts{i}(1,end))); 
            score(cur_phits) = 1;
            image_id(cur_phits) = ohits.image_id(i);
            cluster_id(cur_phits) = ohits.cluster_id(i);
           
            assert(~isempty(find(ohits.image_id == image_id(cur_phits))));
             cur_phits = cur_phits + 1;
        end
    end
end

%fit score to logistic function 

%create a dpm phits 
dpm_phits = hit_list(bounds, score, poselet_id, image_id, cluster_id);

end