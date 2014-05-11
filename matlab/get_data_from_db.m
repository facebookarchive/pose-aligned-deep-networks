%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function data = get_data_from_db(config)
% Returns the poselet hits, object hits and attribute labels for all
% hypotheses in attr_table
attr_num = numel(config.ATTR_NAME);
attr_query = [];
for i = 1:attr_num
attr_query = [attr_query 'a.' config.ATTR_NAME{i} '_value, '];
end
attr_query(end-1:end) = '';

res = dbquery(['select a.photo_fbid, a.hyp_id, a.xmin, a.ymin, a.width,'...
    'a.height, a.score, p.poselet_id, p.xmin, '...
    'p.ymin, p.width, p.height, p.score, ' attr_query ' from ' config.TABLE ' as a, ' ...
    config.POSELET_TABLE ' as p where a.photo_fbid = p.photo_fbid and '...
    'a.hyp_id = p.hyp_id limit 10000000']);

assert(~isempty(res));

parse_string = '%u64 %d %d %d %d %d %f %d %d %d %d %d %f';
for i = 1:attr_num
    parse_string = [parse_string ' %f'];
end
res_parse = textscan(res,parse_string);

data.phits = hit_list( ...
    [res_parse{9} res_parse{10} res_parse{11} res_parse{12}]', ...% bounds
    res_parse{13}, ...% score
    res_parse{8}, ...% poselet_id
    res_parse{1}, ...% image_id
    res_parse{2} ...% cluster_id
 );
[~,o2p,data.poselet2object] = unique([res_parse{1} res_parse{2}],'rows');

data.ohits = hit_list( ...
    [res_parse{3}(o2p) res_parse{4}(o2p) res_parse{5}(o2p) res_parse{6}(o2p)]', ... %bounds
    res_parse{7}(o2p), ... %score
    0, ... %poselet_id
    res_parse{1}(o2p), ... image_id
    res_parse{2}(o2p) ... %cluster_id
);
data.attr_labels = nan(data.ohits.size, length(config.ATTR_NAME));
for i = 1:length(config.ATTR_NAME)
    data.attr_labels(:,i) = res_parse{13+i}(o2p);
end

% Get the facer stuff
res = dbquery(['select f.photo_fbid, f.hyp_id, f.score, f.subject_id, f.gender, f.glasses, f.smile '...
    'from ' config.FACER_TABLE ' as f, ' ...
    config.TABLE ' as a where f.photo_fbid = a.photo_fbid and '...
    'f.hyp_id = a.hyp_id limit 100000']);

assert(~isempty(res));

res_parse = textscan(res, '%u64 %d %f %u64 %f %f %f');
data.subject_id = zeros(data.ohits.size,1,'uint64');
data.facer_attr = nan(data.ohits.size,3);
data.facer_score = nan(data.ohits.size,3);
[~,match] = ismember([data.ohits.image_id data.ohits.cluster_id], [res_parse{1} res_parse{2}], 'rows');
data.subject_id(match>0) = res_parse{4}(match(match>0));
data.facer_attr(match>0,:) = [res_parse{5}(match(match>0)) res_parse{6}(match(match>0)) res_parse{7}(match(match>0))];
data.facer_attr(data.facer_attr<-100000) = nan;
data.facer_score(match>0) = res_parse{3}(match(match>0));


