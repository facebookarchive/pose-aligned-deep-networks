function feature=patch2feature(patch, config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% patch2feature: Returns the feature vector associated with a patched of
%%% normalized dimensions.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if config.USE_PHOG % pyramid HOG
    % the patch must be normalized in size. Allow 4 pixels of margin 72x104 i.e. (4+64+4) by (4+96+4)
%    assert(isequal(size(patch),[config.PATCH_DIMS+8 3]));
    patch=single(patch);

    % Base level hog. Call with 1 pixel of margin
    [hog1,sx,sy]=compute_hog_internal(patch(4:(end-3),4:(end-3),:), config);
    assert(sx(1)==1 && sy(1)==1);
    feature1 = single(permute(hog1,[3 1 2]));

    % Downsample to (2+32+2) by (2+48+2)
    im2=(patch(1:2:end,1:2:end,:)+patch(2:2:end,1:2:end,:)+patch(1:2:end,2:2:end,:)+patch(2:2:end,2:2:end,:))/4;

    % Compute hog with 1 pixel margin
    [hog2,sx,sy]=compute_hog_internal(im2(2:(end-1),2:(end-1),:), config);
    assert(sx(1)==1 && sy(1)==1);
    feature2 = single(permute(hog2,[3 1 2]));

    % Downsample to (1+16+1) by (1+24+1)
    im4=(im2(1:2:end,1:2:end,:)+im2(2:2:end,1:2:end,:)+im2(1:2:end,2:2:end,:)+im2(2:2:end,2:2:end,:))/4;

    % Compute hog with 1 pixel margin
    [hog4,sx,sy]=compute_hog_internal(im4, config);
    assert(sx(1)==1 && sy(1)==1);
    feature4 = single(permute(hog4,[3 1 2]));

    feature = [feature1(:); feature2(:); feature4(:)]';
else
%    assert(isequal(size(patch),[config.PATCH_DIMS+2 3]));
    [H W D] = size(patch);

    cell_size = config.HOG_CELL_DIMS./config.NUM_HOG_BINS;
    block_size = [W-2 H-2]./cell_size(1:2);
    assert(isequal(block_size,round(block_size)));
    hog_block_size = block_size-1;

    % the patch must be normalized in size

    hog_c = compute_hog(patch, config);
    [H,W,cell_hog_len] = size(hog_c);
    assert(W==hog_block_size(1) && H==hog_block_size(2));

    feature = single(permute(hog_c,[3 1 2]));
    feature = feature(:)';
end
