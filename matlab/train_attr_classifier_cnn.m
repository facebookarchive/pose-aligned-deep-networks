%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [ap,scores] = train_attr_classifier_cnn(data, config)

cnn_out_file = sprintf('%s/poselet_1/patches.mat', config.CNN_PATCHES_DIR);
if ~exist(cnn_out_file, 'file')
    prepare_cnn_phits(data, config);
end

%% ON GPU Machine
%% Train CNN model per poselet using caffe 
%%


if ~exist(config.CNN_VAL_FEATURES_FILE, 'file') || ...
   ~exist(config.CNN_TEST_FEATURES_FILE, 'file')
    tic;
	[val_features, test_features] = ...
        extract_level1_features(config, data);
    toc;   
    save(config.CNN_VAL_FEATURES_FILE, 'val_features');
    save(config.CNN_TEST_FEATURES_FILE, 'test_features');
end



if  ~isequal(config.CNN_MODEL_TYPE,'parts')
    if ~exist(config.CNN_GLOBAL_VAL_FEATURES_FILE, 'file')
        tic;
        patch_dims = config.CNN_GLOBAL_MODEL_DIMS .* [2 1];
        [fail_idx, patches] = ...
            extract_person_patches(config,data.ohits.select(data.val_idx), ...
            patch_dims);
        valg_features = prepare_level1_global_features(patches, config);
        clear patches;
        save(config.CNN_GLOBAL_VAL_FEATURES_FILE, 'fail_idx','valg_features');
        toc;
    else
        load(config.CNN_GLOBAL_VAL_FEATURES_FILE);
        disp('Loading cached global val features');
    end
else
    valg_features = [];
end

level2_cnn_model_file = [config.TMP_DIR '/attribute_model.mat'];
if ~exist(level2_cnn_model_file, 'file')
    load(config.CNN_VAL_FEATURES_FILE);  % val_features
    level2_model = train_level2_cnn(data.attr_labels(data.val_idx,:), ...
        val_features, valg_features, config);
    save(level2_cnn_model_file, 'level2_model');
else
   load(level2_cnn_model_file);
   disp('Loading cached attribute classifier');
end
clear val_features val_used;


load(config.CNN_TEST_FEATURES_FILE);
if ~isequal(config.CNN_MODEL_TYPE,'parts')
    if ~exist(config.CNN_GLOBAL_TEST_FEATURES_FILE, 'file')
        tic;
        patch_dims = config.CNN_GLOBAL_MODEL_DIMS .* [2 1];
        [fail_idx, patches] = extract_person_patches(config, ...
            data.ohits.select(data.test_idx), patch_dims);
        testg_features = prepare_level1_global_features(patches, config);
        clear patches;
        save(config.CNN_GLOBAL_TEST_FEATURES_FILE, 'fail_idx','testg_features');
        toc;
    else
        load(config.CNN_GLOBAL_TEST_FEATURES_FILE);
        disp('Loading cached global test features');
    end
else
    testg_features = [];
end

data.attr_labels(data.attr_labels>0) = 1;
data.attr_labels(data.attr_labels<0) = -1;

[ap,scores] = test_level2_cnn(level2_model, ...
    data.attr_labels(data.test_idx,:), test_features, ...
    testg_features, config);

end
