% save all the bins weights
clear model;
for p = 1 : config.N_poselet
    clear mean;

    model_file = sprintf('%s/poselet_%d.bin', config.CNN_MODELS_DIR, p);
   
    feedforward_mex('init', p, model_file, ...
        config.CNN_PATCH_DIMS(1) - 2 * config.CNN_FRINGE, ...
        config.CNN_PATCH_DIMS(2) - 2 * config.CNN_FRINGE);
    layer_names = {'conv1', 'conv2', 'conv3', 'conv4', 'local3', ...
        'fully_is_male', 'fully_has_long_hair', 'fully_wear_glasses',...
        'fully_wear_hat', 'fully_wear_dress','fully_wear_sunglasses',...
        'fully_wear_short_sleeves', 'fully_is_baby'};
    model.mean = feedforward_mex('get_mean', p);
    weights = cell(1, numel(layer_names));
    bias = cell(1, numel(layer_names));
    for j = 1 : numel(layer_names)
        outputs = feedforward_mex('layer_info', p, layer_names{j});
        weights{j} = outputs.weights;
        bias{j} = outputs.biases;
    end
    model.weights = weights;
    model.bias = bias;
    tmp_file = ['../weights/p_' num2str(p) '.mat'];
    mean = model.mean;
    save(['../weights/mean_' num2str(p) '.mat'], 'mean')
    save(tmp_file,'model')
end