function missing_fbids = generate_poselet_hits_and_patches(data, model, config)
%generate poselet hits and patches and store them in each file poselet_<poselet_id>

missing_fbids = [];
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
    idx = find(data.phits.poselet_id == i-1 & ~ismember(data.phits.image_id, missing_fbids));
    phits = data.phits.select(idx);
    fprintf('Store %d-th poselet (%d examples). So far %d missing photos\n' ,i, length(idx), length(missing_fbids));
    tic;
    [patches,fail_idx] = hits2patches_zoom(phits, config.PATCH_SIZE, config.PATCH_ZOOM, model);
    missing_fbids = unique([missing_fbids;  phits.image_id(fail_idx)]);
    succeed_idx = setdiff(1:length(idx),fail_idx);
    patches(:,:,:,fail_idx) = [];
    phits = phits.select(succeed_idx);

    save(fullfile(config.PATCHES_DIR,['/poselet_' num2str(i)]),'patches'); 

    idx = find(data.phits.poselet_id == i-1 & ~ismember(data.phits.image_id, missing_fbids));
    phits = data.phits.select(idx);
    [patches,fail_idx] = hits2patches_zoom(phits, config.CNN_PATCH_DIMS, config.PATCH_ZOOM, model);
    assert(isempty(fail_idx));
    save([cnn_patches_dir '/patches.mat'],'patches');

    save(phits_file,'phits');
    save('/tmp/missing.mat','missing_fbids');
    toc;
end
end

