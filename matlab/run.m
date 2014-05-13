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

%%%%%run DPM added by Ning%%%%%
if 0
    try
        load([config.ROOT_DIR '/dpm_phits']);
    catch
        q = load('dpm_human_weak.mat');
        dpm_model = q.model;
        dpm_phits = get_dpm_hits(config, dpm_model, data.ohits);
        save([config.ROOT_DIR '/dpm_phits'], 'dpm_phits');
    end
    data.phits = dpm_phits;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

if config.ATTR_CNN
    ap = train_attr_classifier_cnn(data,config);    
else
    ap = train_attr_classifier(data,config.ROOT_DIR,config);
end

