%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [model,preserved] = prepare_model(reduce_factor)
if 1
    qqq = load('/home/engshare/fbcode_data/vision/poselets/matlab/person/model.mat');
    model=qqq.model;
    assert(nargin<2);    
else
    qqq = load('/home/engshare/fbcode_data/vision/poselets/matlab/person/model1200.mat');
    model=qqq.output;
    [model,preserved] = reducemodel(model,reduce_factor);
end



% create mapping
num_poselets = length(model.wts);
model.pid2asp = nan(num_poselets, 1);
model.pid2svm = nan(num_poselets, 1);
for asp = 1:length(model.svms)
    model.pid2asp(model.svms{asp}.svm2poselet) = asp;
    model.pid2svm(model.svms{asp}.svm2poselet) = 1:length(model.svms{asp}.svm2poselet);
end

model.max_children = 3;
model.child_r = 0.75;
fprintf('Model numposelets:%d max_children=%d child_r=%f\n',length(model.wts), model.max_children, model.child_r);
end


function [newmodel, preserved] = reducemodel(model,step)
asp_N = length(model.svms);
preserved = [];
newmodel = model;

% subsample the fields
for asp_I = 1:asp_N
   newmodel.svms{asp_I}.svms = model.svms{asp_I}.svms(:,1:step:end);
   preserved =[preserved, newmodel.svms{asp_I}.svm2poselet(1:step:end)];
end
newmodel.logit_coef = newmodel.logit_coef(preserved, :);
newmodel.wts = newmodel.wts(preserved, :);
newmodel.selected_p = newmodel.selected_p(1, preserved);
newmodel.hough_votes = newmodel.hough_votes(preserved);
% ignore big q
assert(~isfield(model,'bigq_weights'));
assert(~isfield(model,'bigq_logit_coef'));

% fix the mapping at the very last
for asp_I = 1:asp_N
   [allexists, newmodel.svms{asp_I}.svm2poselet] = ismember(newmodel.svms{asp_I}.svm2poselet(1:step:end), preserved);
   assert(all(allexists));
end

end