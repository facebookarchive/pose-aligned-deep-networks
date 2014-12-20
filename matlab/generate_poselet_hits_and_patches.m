function generate_poselet_hits_and_patches(data, model, config)
%generate poselet hits and patches and store them in each file poselet_<poselet_id>

for i = 1:config.N_poselet
    phits_file = fullfile(config.PHITS_DIR,['/poselet_' num2str(i) '.mat']);
    if exist(phits_file,'file')
        continue;
    end
    cnn_patches_dir = [config.CNN_PATCHES_DIR +'/poselet_' num2str(i)];
    if ~exist(cnn_patches_dir,'file')
        mkdir(cnn_patches_dir);
    end
    clear phits patches;
    tic
    fprintf('Storing phits and patches for poselet %d\n', i);
    idx = find(data.phits.poselet_id == i-1);
    phits = data.phits.select(idx);
    [patches,fail_idx] = hits2patches_zoom(phits, config.CNN_PATCH_DIMS, config.PATCH_ZOOM, model);
    assert(isempty(fail_idx));
    save([cnn_patches_dir '/patches.mat'],'patches');

    save(phits_file,'phits');
    save('/tmp/missing.mat','missing_fbids');
    toc;
end
end

