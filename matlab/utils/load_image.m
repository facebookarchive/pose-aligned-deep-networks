%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function img=load_image(image_id, config)
% To load images based on the data set. 
switch config.DATASET
    case config.DATASET_ICCV
       if image_id <config.ICCV_TESTIMAGEIDS_OFFSET
          image_path= sprintf('%s/train/%05d.jpg',config.ICCV_DATASET_DIR,image_id);
       else
          image_path= sprintf('%s/test/%05d.jpg',config.ICCV_DATASET_DIR,image_id-config.ICCV_TESTIMAGEIDS_OFFSET);
       end
       img = imread(image_path);
       return;
    case config.DATASET_LFW
        image_path = sprintf('%s/%06d.jpg', config.LFW_DATASET_DIR, image_id);
        img = imread(image_path);
        return;
end

if ~exist('config','var')
    global config;
end
cache_name = sprintf('%s/%d.jpg',config.IMAGES_DIR,image_id);

if exist(cache_name,'file')
    try
        img=imread(cache_name);
        if size(img,3)==1
           img=repmat(img,[1 1 3]);
           imwrite(img,cache_name);
        end
        return;
    catch ex
       fprintf('Failed to load image %d from cache\n',image_id);
       delete(cache_name);
    end
end
fprintf('.');
cmd = sprintf('select url from poselets.%s where photo_fbid=''%d''',config.PHOTO_URLS_TABLE,image_id);
out = dbquery(cmd);
url = sscanf(out,'%s',1);
try
    img = imread(url);
catch ex
   fprintf('Failed to load fbid:%d with url:%s\n',image_id,url);
   img = [];
   return;
end
if size(img,3)==1
   img=repmat(img,[1 1 3]);
end
imwrite(img,cache_name);
end

