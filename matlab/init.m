%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initilaization  step
%% Please change the path to your local directory paths.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
addpath liblinear/matlab;
addpath detector;
addpath detector/poselet_detection;
addpath ../caffe/matlab/caffe/
global config;


config.DATASET_ICCV = 1;
config.DATASET = config.DATASET_ICCV;
extension='_iccv';


config.TMP_DIR = '~/local/fbcode_data/vision/tmp_iccv';
  
config.ATTR_CNN = true; % Do we use deep learning for attributes

config.CNN_PATCH_DIMS = [64 64];


config.CNN_FRINGE = 4; % how much of CNN_PATCH_DIMS is cropped out from each side
config.CNN_FEATURE_LAYER = 'local3_neuron';
config.CNN_MIRROR = false;
config.CNN_MULTIVIEW = false;
config.CNN_NORMALIZATION_TYPE = 'power';

config.ROOT_DIR = ['~/local/fbcode_data/vision/attr' extension];

config.ICCV_DATASET_DIR = '~/local/fbcode_data/vision/attributes/datasets/berkeley_attributes_dataset';
config.ICCV_TESTIMAGEIDS_OFFSET = 10000;
config.IMAGES_DIR =  [config.TMP_DIR '/images'];
config.PATCHES_DIR = [config.TMP_DIR '/patches'];
config.PHITS_DIR= [config.TMP_DIR '/phits'];
config.FEATURES_DIR = [config.TMP_DIR '/features'];

config.CNN_VAL_FEATURES_FILE = [config.TMP_DIR '/cnn_val_features.mat'];
config.CNN_TEST_FEATURES_FILE = [config.TMP_DIR '/cnn_test_features.mat'];
config.CNN_PATCHES_DIR ...
  = sprintf('%s/cnn_output_%d', config.TMP_DIR, config.CNN_PATCH_DIMS(1));

% Use just bounding box deep feature(holistic) or just poselets (parts) or both (combined)
config.CNN_MODEL_TYPE = 'combined';

config.FULL_CROPS_DIR = [config.TMP_DIR '/full_crops'];
config.CNN_GLOBAL_MODEL_TYPE = 'espresso';%'decaf';%decaf or espresso
config.CNN_GLOBAL_VAL_FEATURES_FILE = [config.TMP_DIR '/cnn_' ...
    config.CNN_GLOBAL_MODEL_TYPE '_val_features.mat'];
config.CNN_GLOBAL_TEST_FEATURES_FILE = [config.TMP_DIR '/cnn_' ...
    config.CNN_GLOBAL_MODEL_TYPE '_test_features.mat'];
config.CNN_GLOBAL_VAL_PATCHES_FILE = [config.TMP_DIR '/cnn_fullcrop_val_patches.mat'];
config.CNN_GLOBAL_TEST_PATCHES_FILE = [config.TMP_DIR '/cnn_fullcrop_test_patches.mat'];
config.CNN_GLOBAL_MODEL_DIMS = [256 256];
config.CNN_GLOBAL_FRINGE = 16;

config.CNN_PURE_PATCHES_DIR = [config.TMP_DIR '/pure_batches'];
config.CONFIDENCE_THRESH = 0.95; % confidence threshold for producing an attribute score

if ~exist(config.ROOT_DIR,'dir')
    mkdir(config.ROOT_DIR);
end
if ~exist(config.TMP_DIR,'dir')
    mkdir(config.TMP_DIR);
end
if ~exist(config.IMAGES_DIR,'dir')
    mkdir(config.IMAGES_DIR);
end
if ~exist(config.PATCHES_DIR,'dir')
    mkdir(config.PATCHES_DIR);
end
if ~exist(config.PHITS_DIR,'dir')
    mkdir(config.PHITS_DIR);
end
if ~exist(config.FEATURES_DIR,'dir')
    mkdir(config.FEATURES_DIR);
end
if ~exist(config.CNN_PATCHES_DIR,'dir')
    mkdir(config.CNN_PATCHES_DIR);
end
if ~exist(config.CNN_PURE_PATCHES_DIR,'dir')
    mkdir(config.CNN_PURE_PATCHES_DIR);
end
%config parameters for feature extraction and attribute classification
config.PATCH_ZOOM = 1.2; % zoom in poselet patches
config.PATCH_SIZE = [104 104]; %patch size to store
config.HOG_CELL_DIMS = [16 16 180];
config.NUM_HOG_BINS = [2 2 9];
config.USE_PHOG=true;
config.USE_MEX_HOG = false;
config.SKIN_CELL_DIMS = [2 2];
config.SKIN_CELL_SIZE = 8;
config.HOG_WTSCALE = 2;
config.HOG_NORM_EPS = 1;
config.HOG_NORM_EPS2 = 0.01;
config.HOG_NORM_MAXVAL = 0.2;
config.HOG_NO_GAUSSIAN_WEIGHT=false;

config.ATTR_USE_COLORHIST = true;
config.ATTR_HIST_H_BINS = linspace(0,1,10);
config.ATTR_HIST_S_BINS = linspace(0,1,10);
config.ATTR_HIST_V_BINS = linspace(0,1,10);
config.ATTR_COLORHIST_WEIGHT = 1;
config.FB_ATTR_NAME ={'is_male','has_long_hair','wear_hat','wear_glasses',...
  'wear_dress','wear_sunglasses','wear_short_sleeves','is_baby'};

        config.ATTR_NAME = {'is_male','has_long_hair','has glasses', 'has hat', ...
            'has t-shirt', 'has long sleeves', 'has shorts', 'has jeans', 'long pants'};
        config.POSELET_TABLE = 'poselet_hits_iccv11attr';


config.MAX_HYPS = 100000000;

config.LIBLINEAR_B = 10;     % bias when training poselet SVMs

% poselets model
config.MODEL_FILE = 'poselet_model.mat';
model = load(config.MODEL_FILE);
model = model.model;

config.N_poselet = length(model.selected_p);
if ~config.ATTR_CNN
    %load skin models
    config.skin_model = load('skin_model');
    %load poselet model
    config.TRAIN_PERCENT = 0.35;
    config.VAL_PERCENT = 0.35;
    config.FEATURE_DIM = 5599;
    %load poselet selction per attribute
    load('masks_and_coverage');
    config.used_poselets = used_poselets;
end
clear user;

config.USE_GPU = 1;
config.PANDA_DEF = '../poselet_models/deploy_panda.prototxt';
config.CNN_MODEL_DIR = '../poselet_models';
config.GLOBAL_MEAN_FILE = '../poselet_models/ilsvrc_2012_mean.mat';
config.GLOBAL_DEF = '../poselet_models/deploy.prototxt';
config.GLOBAL_MODEL = '../caffe/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';