%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function xray = get_xray(query)
out = dbquery(sprintf('select * from poselets.xray WHERE %s', query));
data = textscan(out, '%u64 %d %f %f %f %f %f %f %f %f %f %f');
scores = [data{3} data{4} data{5} data{6} data{7} data{8} data{9} data{10} data{11} data{12}]';
xray = xray_image_list(data{1}, scores, data{2});
end
