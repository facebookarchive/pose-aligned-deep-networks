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

savefile = fullfile(save_dir,'data.mat');
if ~exist(savefile,'file')
    data = get_iccv_data(config);
    generate_poselet_hits(data, poselet_model, config);
    save(savefile, 'data');
else
    load(savefile);
end
end
