%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
classdef examples
   properties
      features; % [F x N] array of float. N features
      labels;   % array of N integers. -1 is fp, 1..150 is pid
      size;
   end

    methods
        function e = examples(features, labels)
            e.features = features;
            e.labels = labels;
            e.size = length(e.labels);
        end

        function e = select_features(e, mask)
           e.features = e.features(mask,:); 
        end
        
        function e = select(e, sel)
           e.features = e.features(:,sel);
           e.labels = e.labels(sel);
           e.size = length(e.labels);
        end
    end
end