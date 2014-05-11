%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function data = get_extra_labels_from_db(config, data)
% Returns the poselet hits, object hits and attribute labels for all
% hypotheses in attr_table
atts = config.ATTR_NAME;
attr_num = numel(atts);
attr_query = [];
for i = 1:attr_num
attr_query = [attr_query atts{i} '_value, '];
end
attr_query(end-1:end) = '';

res = dbquery(['select photo_fbid, hyp_id, ' attr_query ' from ' config.TABLE ' limit 10000000']);

assert(~isempty(res));

parse_string = '%u64 %d ';
for i = 1:attr_num
    parse_string = [parse_string ' %f'];
end
res_parse = textscan(res,parse_string);

query_ids = [res_parse{1} res_parse{2}];
match_ids = [data.ohits.image_id data.ohits.cluster_id];
[~,idx] = ismember(match_ids,query_ids,'rows');
for i = 1:attr_num
   data.attr_labels(:, i) = res_parse{2+i}(idx); 
end


