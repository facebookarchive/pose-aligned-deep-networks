%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [fail_idx, bounds] = extract_person_bounds(config, hits, ...
                                width_zoom, height_zoom,y_offset)
%Cropping people bounds for decaf and for dpd
if config.DATASET == config.DATASET_FB || config.DATASET == config.DATASET_FB_DPM
    if ~exist('width_zoom','var')
        width_zoom = 2;
    end
    if ~exist('height_zoom','var')
        height_zoom = 4;
    end
    if ~exist('y_offset','var')
        y_offset = 1.2;
    end

    image_ids=hits.image_id;
    N = length(image_ids);
    ctr_x = hits.bounds(1,:) + hits.bounds(3,:) * 0.5;
    ctr_y = hits.bounds(2,:) + hits.bounds(4,:) * (0.5 + y_offset);
    width = hits.bounds(3,:) * width_zoom;
    height = hits.bounds(4,:) * height_zoom;

    x1 = max(1, round(ctr_x - width / 2));
    y1 = max(1, round(ctr_y - height / 2));
    fail_idx = [];
    bounds = zeros(N,4);
    parfor i = 1:N
        img = load_image(image_ids(i), config);
        [h, w,~] = size(img);
        x_max = min(round(ctr_x(i) + 0.5 * width(i)), w);
        y_max = min(round(ctr_y(i) + 0.5 * height(i)), h);

        if(x1(i) > x_max || y1(i) > y_max)
            fail_idx = [fail_idx i];
        else
            bounds(i,:) = [x1(i) y1(i) x_max y_max];
        end
        
        if mod(i,round(N/100))==0
           fprintf('.');
        end
    end
else
    %assert(config.DATASET == config.DATASET_ICCV);
    bounds = int32(hits.bounds);
    bounds(3:4,:) = bounds(3:4,:) + bounds(1:2,:);
    bounds(1,:) = max(1,bounds(1,:));
    bounds(2,:) = max(1,bounds(2,:));
    patches = zeros([dims 3 hits.size],'uint8');
    tic;
    parfor i=1:hits.size
       img = load_image(hits.image_id(i),config);
       img = img(bounds(2,i):min(size(img,1),bounds(4,i)), bounds(1,i):min(size(img,2),bounds(3,i)),:);
       patches(:,:,:,i) = imresize(img, dims);
    end
    toc;
    fail_idx = [];
end
end


