%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [idx,ch]=get_grid_selection(thumb_dims, dims, num_elements)
while 1
    [x,y,ch] = ginput(1);
    y = floor(y/thumb_dims(2));
    x = floor(x/thumb_dims(1));
    idx = y*dims(1) + x+1;
    if (idx<1 || idx>num_elements)
        idx=nan;
    end
    if isscalar(ch)
        return;
    end
end
