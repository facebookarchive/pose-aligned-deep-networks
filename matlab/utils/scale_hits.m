%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function hits = scale_hits(hits, scale, tr)
% Scales the bounds of faces while keeping the center location fixed.

if isscalar(scale)
   scale=[scale;scale];
end
if ~exist('tr','var')
   tr = [0 0];
end
dims = hits.bounds(3:4,:);
ctr = hits.bounds(1:2,:) + dims/2;
tr = [dims(1,:)*tr(1); dims(2,:)*tr(2)];
dims = dims.*repmat(scale,1,size(dims,2));
hits.bounds(1:2,:) = ctr - dims/2 + tr;
hits.bounds(3:4,:) = dims;
end
