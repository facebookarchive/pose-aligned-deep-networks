%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function data = get_iccv_data(config)

fid = fopen([config.ICCV_DATASET_DIR '/train/labels.txt'],'r');
qq = textscan(fid,'%s %f %f %f %f %d %d %d %d %d %d %d %d %d');
fclose(fid);
train_bounds = [qq{2} qq{3} qq{4} qq{5}];
train_labels = [qq{6} qq{7} qq{8} qq{9} qq{10} qq{11} qq{12} qq{13} qq{14}];
imageids = char(qq{1});
train_imageids = str2num(imageids(:,1:5));

fid = fopen([config.ICCV_DATASET_DIR '/test/labels.txt'],'r');
qq = textscan(fid,'%s %f %f %f %f %d %d %d %d %d %d %d %d %d');
fclose(fid);
test_bounds = [qq{2} qq{3} qq{4} qq{5}];
test_labels = [qq{6} qq{7} qq{8} qq{9} qq{10} qq{11} qq{12} qq{13} qq{14}];
imageids = char(qq{1});
test_imageids = config.ICCV_TESTIMAGEIDS_OFFSET+str2num(imageids(:,1:5));

data.ohits = hit_list([train_bounds' test_bounds'], 0, 0, [train_imageids; test_imageids],0);
data.attr_labels = [train_labels; test_labels];

fid = fopen([config.ICCV_DATASET_DIR '/trainvaltest.txt'],'r');
qq = textscan(fid,'%d %d');
fclose(fid);
assert(isequal(qq{1}',1:data.ohits.size));
data.train_idx = find(qq{2}==1);
data.val_idx = find(qq{2}==2);
data.test_idx = (length(train_imageids)+(1:length(test_imageids)))';
if 1
    % Stick to the original permutation of the val and test because it was
    % used when training the GPU models and we will need to recompute
    % everything if we want to change the permutation
    oldorder = load([config.ROOT_DIR '/oldvaltestorder.mat']);
    data.val_idx = oldorder.val_idx';
    data.test_idx = oldorder.test_idx';
end

% Patch the ICCV bounds
qqq=load([config.ICCV_DATASET_DIR '/iccv_bounds_patches.mat']);
assert(isequal(qqq.bad,find(isnan(data.ohits.bounds(1,:)))));
data.ohits.bounds(:,qqq.bad) = qqq.bounds';
assert(~any(isnan(data.ohits.bounds(:))));

res = dbquery(['select p.photo_fbid, p.hyp_id, p.poselet_id, p.xmin, p.ymin,' ...
    'p.width, p.height, p.score from ' config.POSELET_TABLE ' as p limit 10000000']);

assert(~isempty(res));
parse_string = '%s %d %d %d %d %d %d %f';
res_parse = textscan(res,parse_string);

image_strings = char(res_parse{1});
is_test = image_strings(:,end)==' ';
image_ids(is_test) = config.ICCV_TESTIMAGEIDS_OFFSET + str2num(image_strings(is_test,6:10));
image_ids(~is_test) = str2num(image_strings(~is_test,7:11));

data.phits = hit_list( ...
    [res_parse{4} res_parse{5} res_parse{6} res_parse{7}]', ...% bounds
    res_parse{8}, ...% score
    res_parse{3}, ...% poselet_id
    image_ids, ...% image_id
    res_parse{2} ...% cluster_id
    );
end




