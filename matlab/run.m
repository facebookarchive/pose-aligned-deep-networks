%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Scripts to run the attribute classifiers.%%
%% All the configs are set in init.m        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


init;


data = create_training_directory(model,config);


ap = train_attr_classifier_cnn(data,config);    
