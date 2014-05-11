%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function data = create_training_directory(poselet_model, config)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%This function prepares the training features, attr labels given the table
%%name and creates the train/val/test split. All the poslet patches and features
%%will be saved into save_dir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_dir = config.ROOT_DIR;
switch config.DATASET
    case {config.DATASET_FB, config.DATASET_FBEXT, config.DATASET_FB_DPM}
        s = RandStream('mt19937ar','Seed',1);
        RandStream.setGlobalStream(s);
    
        %get poselet hits and attr labels
        savefile = fullfile(save_dir,'data.mat');
        if ~exist(savefile,'file')
            savefile_full = fullfile(save_dir,'data_full.mat');
            if ~exist(savefile_full,'file')
                data_full = get_data_from_db(config);
                save(savefile_full,'data_full');
            else
                load(savefile_full);
            end
    
        %extract patches and filter out any labels that don't have images.
        %at the end phits_labels will align with the saved files of phits and patches for each
        %poselet
            missing_fbids = generate_poselet_hits_and_patches(data_full,poselet_model, config);

            % Remove missing images
            data = remove_missing_images(data_full, missing_fbids);

            % split into train, val, test and make sure no subject_ids and
            % photo_ids are shared
            [data.train_idx, data.val_idx, data.test_idx] = split_trainvaltest(data, config);
            data.missing_fbids = missing_fbids;

            save(savefile,'data');
        else
            load(savefile);
        end
    
    case {config.DATASET_ICCV, config.DATASET_ICCV_DPM}
        savefile = fullfile(save_dir,'data.mat');
        if ~exist(savefile,'file')
            data = get_iccv_data(config);
            generate_poselet_hits_and_patches(data, poselet_model, config);
            save(savefile, 'data');
        else
            load(savefile);
        end
    case config.DATASET_FBLARGE
        savefile = fullfile(save_dir,'data.mat');
        if ~exist(savefile,'file')
            savefiletmp = fullfile(save_dir,'datatmp.mat');
            if ~exist(savefiletmp,'file')
                data = get_data_from_db_fblarge(config);
                save(savefiletmp,'data');
            else
               load( savefiletmp);
            end
            missing_fbids = generate_poselet_hits_and_patches(data,poselet_model, config);
            data = remove_missing_images(data, missing_fbids);
            save(savefile, 'data');
        else
           load(savefile);
        end
    case config.DATASET_LFW
        savefile = fullfile(save_dir,'data.mat');
        if ~exist(savefile,'file')
            data = get_lfw_data(config);
            missing_fbids = generate_poselet_hits_and_patches(data,poselet_model, config);
            assert(isempty(missing_fbids));
            save(savefile, 'data');
        else
           load(savefile);
        end
end
%extract features
savefile = [config.FEATURES_DIR '/poselet_' num2str(config.N_poselet) '.mat'];
if ~config.ATTR_CNN && ~exist(savefile,'file')
    extract_and_save_features(skin_gmm,config);
end
end

function data = remove_missing_images(data_full, missing_fbids)
valid_ohits = find(~ismember(data_full.ohits.image_id, missing_fbids));
data.ohits = data_full.ohits.select(valid_ohits);
data.attr_labels = data_full.attr_labels(valid_ohits,:);
data.subject_id = data_full.subject_id(valid_ohits);
data.facer_attr = data_full.facer_attr(valid_ohits,:);
data.facer_score = data_full.facer_score(valid_ohits);

[~,invphit] = ismember(1:data_full.ohits.size, valid_ohits);
data.poselet2object = invphit(data_full.poselet2object);
valid_phits = data.poselet2object>0;
data.poselet2object = data.poselet2object(valid_phits);
data.phits = data_full.phits.select(valid_phits);
data.missing_fbids = missing_fbids;
end

% Partitions the annotations into training, validation and test subsets
% randomly, but tries to keep all annotations of the same person or the same
% image in the same partition
function [train_idx, val_idx, test_idx] = split_trainvaltest(data, config)

NUM_GROUPS = 3;

photo_ids = data.ohits.image_id;
[groups, unassigned] = constrained_split(photo_ids, NUM_GROUPS);

usel = find(unassigned & data.subject_id>0);
uids = data.subject_id(usel);
groups2 = constrained_split(uids, NUM_GROUPS);

for g=1:length(groups)
    groups{g} = [groups{g}; usel(groups2{g})];
    assert(all(unassigned(usel(groups2{g}))));
    unassigned(usel(groups2{g})) = false;
end

unassigned = find(unassigned);
r = randperm(length(unassigned));
unassigned = unassigned(r);

num_train_to_add = round(config.TRAIN_PERCENT * data.ohits.size) - length(groups{1});
train_idx = [groups{1}; unassigned(1:num_train_to_add)]';
unassigned(1:num_train_to_add) = [];

num_val_to_add = round(config.VAL_PERCENT * data.ohits.size) - length(groups{2});
val_idx = [groups{2}; unassigned(1:num_val_to_add)]';
unassigned(1:num_val_to_add) = [];

test_idx = [groups{3}; unassigned]';

end

function [groups,unassigned] = constrained_split(ids, NUM_GROUPS)
unassigned = true(length(ids),1);
groups = cell(NUM_GROUPS,1);
[~,q2,q3] = unique(ids);
counts = histc(q3,1:max(q3));
[srt,srtd] = sort(counts,'descend');
srtd(srt<2) = [];
multiple_ids = ids(q2(srtd));
for id=multiple_ids'
    elems = find(ids == id);
    assert(length(elems)>1);
    assert(all(unassigned(elems)));
    rand_idx = randi(length(groups),1);
    groups{rand_idx} = [groups{rand_idx}; elems];
    unassigned(elems) = false;
end

end

%function data = get_iccv_data(config)
%    load('/home/lubomir/local/fbcode_data/vision/attr_iccv/dataICCVFromNing.mat');
%end
