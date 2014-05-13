function patches = combine_patches_of_different_sizes(patches1, max_patches)    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Takes a cell array of arrays of image patches of different dimensions
%%% and combines them in a single array by padding. Used for visualizing in
%%% a grid poselets of different dimensions
%%%
%%% PARAMETERS:
%%%   a         -- the annotations associated with the poselets(of type 'annotation')
%%%   poselets  -- a poselet or an array of N poselets
%%%   interp    -- the resampling method (default 'bilinear')
%%%   pad       -- how many pixels to pad around the patches (default 1)
%%%
%%% RETURNS:
%%%   all_patches   -- an array of image patches so all_patches{i} is a H x W x 3 x K array of uint8 
%%%                    if the i-th poselet has K examples and dimensions H x W.
%%%   falls_outisde -- an array of N booleans indicating whether each
%%%                    poselet partially falls outside the image
%%%   all_labels    -- if specified, we also return the label masks of the patches.
%%%                    all_labels{i} is a H x W x K array of uint8 and the
%%%                    values are indices of corresponding parts specified
%%%                    in K. For example, pixels marked with K.A_Occluder are occluded.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin<2
       max_patches=inf; 
    end
    
    N = 0;
    max_dims=[0 0];
    D = 1;
    is_double = false;
    for i=1:length(patches1)
       [H W d num] = get_size(patches1{i});
       if ~isempty(patches1{i})
           is_double = isa(patches1{i},'double');
           D = max(d, D);           
       end
       if num>0
           if num>max_patches
              patches1{i}=patches1{i}(:,:,:,1:max_patches);
              num=max_patches;
           end
           N = N + num; 
           max_dims = max(max_dims, [H W]);
       end
    end

    if is_double
        patches = zeros([max_dims D N]);
    else
        patches = zeros([max_dims D N],'uint8');
    end

    cr=0;
    for i=1:length(patches1)
        if ~isempty(patches1{i})
           [H W D num] = get_size(patches1{i});
           top_left = round((max_dims - [H W])/2);
           patches(top_left(1)+(1:H),top_left(2)+(1:W),:,cr+(1:num)) = patches1{i};
           cr = cr+num;
        end
    end
end

function [H W D num] = get_size(thumb)
if length(size(thumb))==2
   num=1;
   D = 1;
   [H W] = size(thumb);
else
    [H W D num] = size(thumb);
end
end