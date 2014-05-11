%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function features = prepare_level1_global_features(patches, config)
dims = config.CNN_GLOBAL_MODEL_DIMS;
N = size(patches,4);
switch config.CNN_GLOBAL_MODEL_TYPE
    case 'decaf'
        %write images to decaf tmp dir
        parfor i = 1:N
            filename = sprintf('%s/%05d.jpg', config.DECAF_TMP_DIR, i);
            imwrite(patches(1:dims(1),:,:,i), filename, 'jpeg');
            filename = sprintf('%s/%05d.jpg', config.DECAF_TMP_DIR, i+N);
            imwrite(patches(dims(1)+1: 2*dims(1), :, :, i), filename, 'jpeg');
        end
        %call decaf python interface to extract features
        system(['python attributes/cnn_hybrid/get_decaf_features.py ' config.CNN_GLOBAL_MODEL ' ' ...
            config.DECAF_TMP_DIR  ' ' config.CNN_DECAF_FEATURES_FILE ' ' num2str(N+N)]);
        decaf_features = load(config.CNN_DECAF_FEATURES_FILE);
        features = [decaf_features.features(1:N, :) decaf_features.features(N+1:end, :)];
    case 'espresso'
        splits=100;
        subranges = split_range(1:N, splits);
        feedforward_mex(0, config.CNN_GLOBAL_MODEL, ...
        dims(1) - 2 * config.CNN_GLOBAL_FRINGE, ...
        dims(2) - 2 * config.CNN_GLOBAL_FRINGE);
        featureGroups = cell(splits,1);
        crop_dims = dims - 2 * config.CNN_GLOBAL_FRINGE;
        assert(size(patches,1) == dims(1)*2);
        tic;
        for i=1:splits
            % Unfortunately couldn't get feedforward_mex here to run in parallel
            fprintf('Feedforward %d (size=%d)\n',i,length(subranges{i}));
            
            r_top = feedforward_mex(0, patches(config.CNN_GLOBAL_FRINGE + (1:crop_dims(1)),...
               config.CNN_GLOBAL_FRINGE + (1:crop_dims(2)),:,subranges{i}), 16, 16, 'fc6');
            r_bot = feedforward_mex(0, patches(dims(1)+config.CNN_GLOBAL_FRINGE + (1:crop_dims(1)),...
                config.CNN_GLOBAL_FRINGE + (1:crop_dims(2)),:,subranges{i}),  16, 16, 'fc6');
            featureGroups{i} = [r_top{1}; r_bot{1}];
            toc;
        end
        features = nan(N,size(featureGroups{1},1),'single');
        for i=1:splits
            features(subranges{i},:) = featureGroups{i}';
        end
end
end

function subranges = split_range(range, N) 
    num_per_unit = floor(length(range) / double(N-1));
    for i=1:(N-1)
        subranges{i} = range(((i-1)*num_per_unit+1):(i*num_per_unit));
    end
    subranges{N} = range(((N-1)*num_per_unit+1):length(range));
end
