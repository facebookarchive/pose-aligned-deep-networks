%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function result = train_attr_classifier(data, dir_name, config)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%This function trains the two-level attribute classifiers. Intermediate
%%models and scores will be stored in dir_name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

train_idx = [data.ohits.image_id(data.train_idx) data.ohits.cluster_id(data.train_idx)];
val_idx = [data.ohits.image_id(data.val_idx) data.ohits.cluster_id(data.val_idx)];
trainval_idx = [train_idx; val_idx];
test_idx = [data.ohits.image_id(data.test_idx) data.ohits.cluster_id(data.test_idx)];

data.attr_labels(data.attr_labels>0) = 1;
data.attr_labels(data.attr_labels<0) = -1;

train_labels = data.attr_labels(data.train_idx,:);
val_labels = data.attr_labels(data.val_idx,:);
trainval_labels = [train_labels; val_labels];
test_labels = data.attr_labels(data.test_idx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TRAIN LEVEL 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

level1_model_file = fullfile(dir_name,'level1_model.mat');
if ~exist(level1_model_file, 'file')
    level1_model = train_level1(train_idx,train_labels,config);
    save(level1_model_file,'level1_model');
else
    load(level1_model_file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TRAIN LEVEL 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

level1_val_scores_file = fullfile(dir_name, 'level1_val_scores.mat');
if ~exist(level1_val_scores_file, 'file')
    level1_val_scores = test_level1(level1_model, val_idx, config);
    save(level1_val_scores_file,'level1_val_scores'); 
else
    load(level1_val_scores_file);
end
 
level2_model_file = fullfile(dir_name, 'level2_model.mat');
if ~exist(level2_model_file, 'file')
   level2_model = train_level2(level1_val_scores,val_labels,config);
   save(level2_model_file, 'level2_model');
else
   load(level2_model_file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TRAIN LEVEL 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% eval level1 on test
level1_trainval_scores_file = fullfile(dir_name, 'level1_trainval_scores.mat');
if ~exist(level1_trainval_scores_file, 'file')
    level1_trainval_scores = test_level1(level1_model, trainval_idx, config);
    save(level1_trainval_scores_file,'level1_trainval_scores'); 
else
    load(level1_trainval_scores_file);
end

% eval level2 on test
level2_trainval_scores_file = fullfile(dir_name, 'level2_trainval_scores.mat');
if ~exist(level2_trainval_scores_file, 'file')
  level2_trainval_scores = test_level2(level2_model, level1_trainval_scores, config);
  save(level2_trainval_scores_file, 'level2_trainval_scores');
else
  load(level2_trainval_scores_file);
end

level3_model_file = fullfile(dir_name, 'level3_model.mat');
if ~exist(level3_model_file, 'file')
  level3_model = train_level3(level2_trainval_scores, trainval_labels, config);
  save(level3_model_file, 'level3_model');
else
  load(level3_model_file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TEST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 1
    % eval level1 on test
    level1_test_scores_file = fullfile(dir_name, 'level1_test_scores.mat');
    if ~exist(level1_test_scores_file, 'file')
        level1_test_scores = test_level1(level1_model, test_idx, config);
        save(level1_test_scores_file,'level1_test_scores'); 
    else
        load(level1_test_scores_file);
    end
    
    % eval level2 on test
   level2_test_scores_file = fullfile(dir_name, 'level2_test_scores.mat');
   if ~exist(level2_test_scores_file, 'file')
      level2_test_scores = test_level2(level2_model, level1_test_scores, config);
      save(level2_test_scores_file, 'level2_test_scores');
   else
      load(level2_test_scores_file);
   end

   % eval level3 on test
   level3_test_scores_file = fullfile(dir_name, 'level3_test_scores.mat');
   if ~exist(level3_test_scores_file, 'file')
      level3_test_scores = test_level3(level3_model, level2_test_scores, test_labels);
      save(level3_test_scores_file, 'level3_test_scores');
   else
      load(level3_test_scores_file);
   end

   % compute level2 AP
   result = report_ap(level1_test_scores, level2_test_scores, level3_test_scores, test_labels, data, config);
end

end

