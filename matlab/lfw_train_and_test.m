%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
init

data = create_training_directory(config.ROOT_DIR,skin_gmm,model,config);
prepare_cnn_patches(data, config);

if ~exist(config.CNN_VAL_FEATURES_FILE, 'file') || ...
    ~exist(config.CNN_TEST_FEATURES_FILE, 'file')
    tic;
	[val_features, test_features] = prepare_level1_features_cnn(config, data);
    toc;
    save(config.CNN_VAL_FEATURES_FILE, 'val_features');
    save(config.CNN_TEST_FEATURES_FILE, 'test_features');
    toc;
end

data.attr_labels(data.attr_labels>0) = 1;
data.attr_labels(data.attr_labels<0) = -1;

load(config.CNN_VAL_FEATURES_FILE);  % val_features
level2_model = train_level2_cnn(data.attr_labels(data.val_idx,:), val_features, [], config);

load(config.CNN_TEST_FEATURES_FILE);  % test_features
ap = test_level2_cnn(level2_model,data.attr_labels(data.test_idx,:), test_features, [], config);

%% neeraj(iccv 2011) ap
neeraj = load(config.NEERAJ_FILE);
neeraj_scores = neeraj(data.test_idx);
neeraj_ap = get_precision_recall(neeraj_scores, data.attr_labels(data.test_idx,:))

