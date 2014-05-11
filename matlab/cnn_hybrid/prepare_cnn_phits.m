%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function prepare_cnn_phits(data, config)

CREATE_TRAINVALTEST_BATCHES = false;

if CREATE_TRAINVALTEST_BATCHES
   disp('Warning: Create phits that include the test set too!');
end
%prepare patches for gpu training
poselet_model = load(config.MODEL_FILE);
poselet_model = poselet_model.model;
for p=1:config.N_poselet
    clear patches phits train_idx train_idx_large val_idx test_idx;
    fprintf('Prepare the %d-th poselet.\n',p);
    dir_name = [config.CNN_PATCHES_DIR +'/poselet_' num2str(p)];
    if ~exist(dir_name,'dir')
        mkdir(dir_name);
    end
    
    % Prepare phits
    qqq=load(fullfile(config.PHITS_DIR,sprintf('poselet_%s',num2str(p))));
    phits=qqq.phits;
    clear qqq;
    if config.DATASET == config.DATASET_ICCV
        phits.cluster_id(:)=0;
    end
    
    phits_ids = [phits.image_id phits.cluster_id];
    train_ids = [data.ohits.image_id(data.train_idx) data.ohits.cluster_id(data.train_idx)];
    val_ids   = [data.ohits.image_id(data.val_idx  ) data.ohits.cluster_id(data.val_idx  )];
    test_ids  = [data.ohits.image_id(data.test_idx ) data.ohits.cluster_id(data.test_idx )];
    all_ids   = [data.ohits.image_id data.ohits.cluster_id];
    
    if CREATE_TRAINVALTEST_BATCHES
        BATCH_THRESH = [0.3 0.4 0.3];
        [srt,srtd] = sort(phits.score,'descend');
        b1_2 = round(phits.size * BATCH_THRESH(1));
        b2_3 = round(phits.size * sum(BATCH_THRESH(1:2)));
        train_idx = srtd(1 : (b1_2-1))';
        train_idx_large = srtd(b1_2 : (b2_3-1))';
        val_idx = srtd(b2_3 : end)';
        test_idx = train_idx;
        phits_filename = [dir_name '/phits_trainvaltest.mat'];
    else
        train_idx       = find(ismember(phits_ids,train_ids,'rows')~=0 & phits.score >0.9)';
        train_idx_large = find(ismember(phits_ids,train_ids,'rows')~=0 & phits.score <=0.9)';
        val_idx         = find(ismember(phits_ids,val_ids,  'rows')~=0)';
        test_idx        = find(ismember(phits_ids,test_ids, 'rows')~=0)';
        phits_filename = [dir_name '/phits.mat'];
    end
    [~,phits2allhits] = ismember(phits_ids, all_ids, 'rows');

    save(phits_filename,'phits','train_idx', 'train_idx_large', 'val_idx', 'test_idx', 'phits2allhits');
end

