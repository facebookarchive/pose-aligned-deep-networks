%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function data = get_lfw_data(config)

fid = fopen([config.LFW_DATASET_DIR '/ordered_gender_annotations.txt'],'r');
if fid ==0
    disp('run the perl scripts create_train_test.pl and order_lfw.pl first');
end
qq = textscan(fid,'%s %s %d %d %f');
fclose(fid);

%% set train, validation and test indices
data.train_idx = [];
data.val_idx = find(qq{3}==2);
data.test_idx = find(qq{3}==3 | qq{3}==1);
data.attr_labels = [qq{4}];
data.lfw_ids = qq{2};

total_files = length(data.attr_labels);
zero_vec =  zeros(total_files,1);

%% Get object hits
res = dbquery(['select o.photo_fbid, o.hyp_id, o.xmin, o.ymin,' ...
    'o.width, o.height, o.score from ' config.OBJECT_TABLE ' as o limit 10000000']);

assert(~isempty(res));
parse_string = '%s %d %d %d %d %d %f';
res_parse_obj = textscan(res,parse_string);

imageids = char(res_parse_obj{1});
image_ids_obj = str2num(imageids(:,1:6));
hyp_ids = [res_parse_obj{2}];
rects = [res_parse_obj{3} res_parse_obj{4} res_parse_obj{5} res_parse_obj{6}];
scores = [res_parse_obj{7}];

%% set phits
res = dbquery(['select p.photo_fbid, p.hyp_id, p.poselet_id, p.xmin, p.ymin,' ...
    'p.width, p.height, p.score from ' config.POSELET_TABLE ' as p limit 10000000']);

assert(~isempty(res));
parse_string = '%s %d %d %d %d %d %d %f';
res_parse = textscan(res,parse_string);

imageids = char(res_parse{1});
image_ids = str2num(imageids(:,1:6));

phits = hit_list( ...
    [res_parse{4} res_parse{5} res_parse{6} res_parse{7}]', ...% bounds
    res_parse{8}, ...% score
    res_parse{3}, ...% poselet_id
    image_ids, ...% image_id
    res_parse{2} ...% cluster_id
    );

selected = zeros(total_files,2);
selected_rects = zeros(total_files, 4);
for i = 1:total_files
    current_ids = find(image_ids_obj==i);
    if isempty(current_ids)
        selected_rects(i,:) = [0 0 250 250];
        selected(i, :) = [0 0];
        continue;
    end
    current_scores = scores(current_ids);
    [a b] = sort(current_scores, 'descend');
    current_all_rects = double(rects(current_ids,:));
    current_rects = current_all_rects(b,:);
    ind = 1;
    % pick the rectangle in descending order of confidence and the
    % rectangle size has minimum dimensions. Break once we find such a
    % rectangle
    while ind < size(b,1)
      if current_rects(ind,3) > 60 && current_rects(ind,4) > 60
        break;
      else
        ind = ind + 1;
      end
    end
    hyp_id = hyp_ids(current_ids(ind));
    selected(i, :) = [i hyp_id];
    selected_rects(i,:) = current_rects(ind, :);
end

all = [image_ids  res_parse{2}];
[q1,q2] = ismember(all, selected, 'rows');

%% set ohits
data.ohits = hit_list(selected_rects', zero_vec, zero_vec, (1:total_files)', zero_vec);
data.phits = phits.select(find(q1==1));

end




