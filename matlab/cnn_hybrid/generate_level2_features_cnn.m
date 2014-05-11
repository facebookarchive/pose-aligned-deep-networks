%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level2_features = generate_level2_features_cnn(level1_features, gfeatures, config)
%combine deep learning features/scores for a second level feature
%is_score = 1 means combining scores, otherwise combining the features.
assert(~isempty(level1_features));

basis = size(level1_features{1}.features,2);
is_score = (basis==1);
num_poselets = length(level1_features);
if config.DATASET ~= config.DATASET_LFW
    num_examples = size(gfeatures,1);
else
    num_examples = 0;
end
level2_features = zeros(num_examples, num_poselets*basis, 'single');

for i = 1:num_poselets    
    %if features is empty, meaning no cnn model of this poselet
    if isempty(level1_features{i})
        continue;
    end
        
    if is_score
        level2_features(level1_features{i}.used,i) = (level1_features{i}.features-0.5);
    else
        level2_features(level1_features{i}.used,(i-1)*basis+1:i*basis) = level1_features{i}.features;
    end
end

switch config.CNN_MODEL_TYPE
    case 'combined'
        level2_features = [level2_features gfeatures];
        fprintf('Combined model\n');
    case 'holistic'
        level2_features = gfeatures;
        fprintf('Global-only model\n');
    case 'parts'
        fprintf('Parts-only model\n');
end

%normalization
switch config.CNN_NORMALIZATION_TYPE
    case 'max'
        fprintf('Normalization: max\n');
        level2_features = level2_features ./repmat(max(level2_features,[],2),1,size(level2_features,2));
    case 'L1'
        fprintf('Normalization: L1\n');
        level2_features = level2_features ./repmat(sum(abs(level2_features),2),1,size(level2_features,2));
    case 'power'
        ppp = 0.3;
        for i = 1:size(level2_features,1)
            level2_features(i,:) = sign(level2_features(i,:)).*abs(level2_features(i,:)).^ppp;
        end
        fprintf('Normalization: power %f\n',ppp);
end
assert(~any(isnan(level2_features(:))));
end