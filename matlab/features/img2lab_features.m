%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function features=img2lab_features(img)
assert(isequal(class(img),'uint8'));
color_patch = double(reshape(img,[],3))/255;
features = applycform(color_patch,makecform('srgb2lab'));   
