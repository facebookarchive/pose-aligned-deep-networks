%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function visualize_results(data,scores,config,visualize_type)

ohits = data.ohits.select(data.test_idx);
labels = data.attr_labels(data.test_idx,:);
assert(ohits.size == length(scores{1}));
NUM2SHOW = 10;
DIMS = [100 250];
HEIGHT = 235;

switch visualize_type
case 0
    % Find highest scoring for attribute
    for attr_id = 1:size(data.attr_labels,2)
       [srt,srtd] = sort(scores{attr_id});
       patches = hits2patches(ohits.select(srtd(1:NUM2SHOW)), DIMS);
       aid = attr_id;
       figure(aid*2);
       display_patches(patches,[],[1 NUM2SHOW]);
       title(sprintf('Lowest scoring for %s', config.ATTR_NAME{attr_id}));
       set(aid*2, 'position', [20 1200-(HEIGHT+50)*(aid-1) 900 HEIGHT]);

       [srt,srtd] = sort(-scores{attr_id});
       patches = hits2patches(ohits.select(srtd(1:NUM2SHOW)), DIMS);
       figure(aid*2+1);
       display_patches(patches,[],[1 NUM2SHOW]);
       title(sprintf('Highest scoring for %s', config.ATTR_NAME{attr_id}));
       set(aid*2+1, 'position', [1200 1200-(HEIGHT+50)*(aid-1) 900 HEIGHT]);
    end

case 1
    % Find the most misclassified examples
    for attr_id = 1:size(data.attr_labels,2)
       [srt,srtd] = sort(scores{attr_id});
       lab = labels(srtd, attr_id);
       srtd(lab<=0) = [];
       patches = hits2patches(ohits.select(srtd(1:NUM2SHOW)), DIMS);
       figure(attr_id*2);
       display_patches(patches,[],[1 NUM2SHOW]);
       title(sprintf('Predicted not be %s but ground truth is %s', config.ATTR_NAME{attr_id}, config.ATTR_NAME{attr_id}));
       set(attr_id*2, 'position', [20 1200-(HEIGHT+50)*(attr_id-1) 900 HEIGHT]);

       [srt,srtd] = sort(-scores{attr_id});
       lab = labels(srtd, attr_id);
       srtd(lab>=0) = [];
       patches = hits2patches(ohits.select(srtd(1:NUM2SHOW)), DIMS);
       figure(attr_id*2+1);
       display_patches(patches,[],[1 NUM2SHOW]);
       title(sprintf('Predicted to be %s but ground truth is not %s', config.ATTR_NAME{attr_id}, config.ATTR_NAME{attr_id}));
       set(attr_id*2+1, 'position', [1200 1200-(HEIGHT+50)*(attr_id-1) 900 HEIGHT]);
    end
end
