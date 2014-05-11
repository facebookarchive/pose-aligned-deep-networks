%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function thresh = get_confidence_thresh(scores, labels, acc_thresh)
    idx=20;
    num_correct = sum(labels(1:idx));
    acc = num_correct/idx;
    while acc > acc_thresh && idx<length(scores)
        idx=idx+1;
        num_correct = num_correct + labels(idx);
        acc = num_correct/idx;
    end
    thresh = scores(idx);
end
