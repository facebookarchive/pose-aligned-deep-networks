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
%%Initilaization  step, change the parameters if needed        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
addpath db;
addpath visualize;
addpath tree;
addpath utils;
addpath liblinear/matlab;
addpath detector;
addpath detector/poselet_detection;
addpath facer;
addpath features;
addpath attributes;
addpath attributes/cnn_hybrid;
addpath cvx;
global config;


user = getenv('USER');
%change your directories here
config.DATASET_FB = 1;
config.DATASET_ICCV = 2;
config.DATASET_FBLARGE = 3;
config.DATASET_LFW = 4;
config.DATASET_FBEXT = 5;
config.DATASET_ICCV_DPM = 6;
config.DATASET_FB_DPM = 7;
config.DATASET_NAME = {'Facebook Dataset','ICCV11 Dataset','Facebook LargeScale Dataset',...
    'LFW','Facebook Extended Attributes Dataset', 'ICCV DPM', 'Facebook Dataset DPM'};

config.DATASET = config.DATASET_FB_DPM;

config.FBLARGE_VERSION = 1;
switch config.DATASET
    case config.DATASET_FB
        extension='_fb';
    case config.DATASET_FBEXT
        extension='_ext';
    case config.DATASET_ICCV
        extension='_iccv';
    case config.DATASET_FBLARGE
        extension=sprintf('_fblarge%d',config.FBLARGE_VERSION);
    case config.DATASET_LFW
        extension ='_lfw';
    case config.DATASET_ICCV_DPM
        extension = '_iccv_dpm';
    case config.DATASET_FB_DPM
        extension = '_fb_dpm';
    otherwise
        error('Unknown dataset');
end

config.CLUSTER = false;
if config.CLUSTER
    % For the matlab cluster the data must be in a shared directory
    config.TMP_DIR = ['/home/' user '/attributes/attr' extension];
else
    config.TMP_DIR = ['/data/users/' user '/attributes/attr' extension];
end
config.ATTR_CNN = true; % Do we use deep learning for attributes

config.CNN_PATCH_DIMS = [64 64];
if config.DATASET==config.DATASET_FB || config.DATASET == config.DATASET_FB_DPM
    config.CNN_MODELS_DIR = '/home/engshare/fbcode_data/vision/attributes/cnn_models/fb_train';
else
    config.CNN_MODELS_DIR = '/home/engshare/fbcode_data/vision/attributes/cnn_models/fb_full';
end

config.CNN_FRINGE = 4; % how much of CNN_PATCH_DIMS is cropped out from each side
config.CNN_FEATURE_LAYER = 'local3_neuron';
config.CNN_MIRROR = false;
config.CNN_MULTIVIEW = false;
config.CNN_NORMALIZATION_TYPE = 'power';

config.ROOT_DIR = ['~/local/fbcode_data/vision/attr' extension];
if config.DATASET == config.DATASET_ICCV || config.DATASET == config.DATASET_ICCV_DPM
   config.ICCV_DATASET_DIR = '/home/engshare/fbcode_data/vision/attributes/datasets/berkeley_attributes_dataset';
   config.ICCV_TESTIMAGEIDS_OFFSET = 10000;
end
if config.DATASET == config.DATASET_LFW
   config.LFW_DATASET_DIR = '/home/engshare/fbcode_data/vision/attributes/datasets/lfw';
end


config.IMAGES_DIR =  [config.TMP_DIR '/images'];
config.PATCHES_DIR = [config.TMP_DIR '/patches'];
config.PHITS_DIR= [config.TMP_DIR '/phits'];
config.FEATURES_DIR = [config.TMP_DIR '/features'];

config.CNN_VAL_FEATURES_FILE = [config.TMP_DIR '/cnn_val_features.mat'];
config.CNN_TEST_FEATURES_FILE = [config.TMP_DIR '/cnn_test_features.mat'];
config.CNN_PATCHES_DIR ...
  = sprintf('%s/cnn_output_%d', config.TMP_DIR, config.CNN_PATCH_DIMS(1));

% Use just decaf (holistic) or just poselets (parts) or both (combined)
config.CNN_MODEL_TYPE = 'combined';

config.FULL_CROPS_DIR = [config.TMP_DIR '/full_crops'];
config.CNN_GLOBAL_MODEL_TYPE = 'espresso';%'decaf';%decaf or espresso
if strcmp(config.CNN_GLOBAL_MODEL_TYPE, 'decaf')
    config.CNN_GLOBAL_MODEL = ['/data/users/' user '/fbcode/vision/third_party/decaf-release/'];
    config.DECAF_TMP_DIR = [config.TMP_DIR '/decaf_images'];
    if ~exist(config.DECAF_TMP_DIR,'dir')
        mkdir(config.DECAF_TMP_DIR);
    end
    config.CNN_DECAF_FEATURES_FILE = [config.TMP_DIR '/decaf_features.mat'];
end
if strcmp(config.CNN_GLOBAL_MODEL_TYPE, 'espresso')
    config.CNN_GLOBAL_MODEL = '/home/engshare/fbcode_data/vision/attributes/cnn_models/espresso.bin';
end
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
switch config.DATASET
    case {config.DATASET_FB, config.DATASET_FBEXT, config.DATASET_FB_DPM}
        config.ATTR_NAME = config.FB_ATTR_NAME;
        config.TABLE = 'attribute_20k'; %table store attribute labels
        config.FACER_TABLE = 'faceboxes';
        config.POSELET_TABLE = 'poselet_hits_person_head'; %table store poselet activation
        config.PHOTO_URLS_TABLE = 'photo_urls';
    case {config.DATASET_ICCV, config.DATASET_ICCV_DPM}
        config.ATTR_NAME = {'is_male','has_long_hair','has glasses', 'has hat', ...
            'has t-shirt', 'has long sleeves', 'has shorts', 'has jeans', 'long pants'};
        config.POSELET_TABLE = 'poselet_hits_iccv11attr';
    case config.DATASET_FBLARGE
        config.ATTR_NAME = {'is_male'};
        config.FB_ATTR_NAME ={'is_male'};
        config.TABLE = 'fb_large'; %table store attribute labels
        config.FACER_TABLE = 'faceboxes_facebook_large';
        config.POSELET_TABLE = 'poselet_hits_person_head_facebook_large'; %table store poselet activation
        config.PHOTO_URLS_TABLE = 'photo_urls_facebook_large';
    case config.DATASET_LFW
        config.CNN_MULTIVIEW = false;
        config.CNN_MIRROR = false;
        config.CNN_MODEL_TYPE = 'parts';
        config.NEERAJ_FILE = [config.LFW_DATASET_DIR '/neeraj.txt'];
        config.FB_ATTR_NAME ={'is_male'};
        config.ATTR_NAME = {'is_male'};
        config.OBJECT_TABLE = 'object_hits_lfw'; %table store object activation
        config.POSELET_TABLE = 'poselet_hits_lfw'; %table store poselet activation
end
if config.DATASET==config.DATASET_FBEXT
    xtra_attr = {'is_lessthan12', 'is_over60', ...
            'is_asian','is_black', 'is_white','is_indian', 'is_hispanic',...
            'bald', 'blonde','brunette', 'whitehair', ...
            'formal_wear', 'tshirt', 'shorts', 'jeans', 'plaid', 'jacket', 'collaredshirt',...
            'is_smiling', 'running','walking','sitting'};
    config.ATTR_NAME(end+(1:length(xtra_attr))) = xtra_attr;
end

config.MAX_HYPS = 100000000;

config.LIBLINEAR_B=10;     % bias when training poselet SVMs

% poselets model
config.MODEL_FILE='/home/engshare/fbcode_data/vision/poselets/categories/person/model.mat';
model = load(config.MODEL_FILE);
model = model.model;

config.N_poselet = length(model.selected_p);
if ~config.ATTR_CNN
    %load skin models
    config.skin_model = load(fullfile(config.ROOT_DIR, 'skin_model'));
    %load poselet model
    config.TRAIN_PERCENT = 0.35;
    config.VAL_PERCENT = 0.35;
    config.FEATURE_DIM = 5599;
    %load poselet selction per attribute
    load(fullfile(config.ROOT_DIR,'masks_and_coverage'));
    config.used_poselets = used_poselets;
end
clear user;


