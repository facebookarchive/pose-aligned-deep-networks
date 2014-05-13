function [h,dims_out]=display_patches(patches, annotations, dims)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Displays a grid of patches
%%%
%%% PARAMETERS:
%%%    patches:  [H x W x 3 X N] array of N patches as RGB images
%%%
%%% OPTIONAL PARAMETERS:
%%%    annotations: [N x K] array of char. Places the strings at the top left corner of each patch 
%%%    dims: [H x W] grid dimensions (X*Y must be = N)
%%%
%%% RETURN VALUES:
%%%    h:    Handle of the drawn figure
%%%    dims: Grid dimensions used (if ones were not provided)
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning('off','Images:initSize:adjustingMag');
if isempty(patches)
    dims_out=[0 0];
    h=[];
    return;
end
    
if 0 && (length(size(patches))==3) 
    [H,W,N] = size(patches);
    if nargin<3
        h=montage(reshape(patches, H,W,1,N));
    else
        h=montage(reshape(patches, H,W,1,N), 'Size',dims);
    end
else
    [H,W,C,N] = size(patches);
    if nargin<3
        h=montage(patches, 'Size', [floor(sqrt(N)) ceil(N/floor(sqrt(N)))]);
    else
        h=montage(patches, 'Size',dims);
    end
end


% figure out the dimensions used
im_sz = size(get(h,'CData'));
s_sz = size(patches);
if nargin<3
    dims_out = im_sz([2 1])./s_sz([2 1]);
else
    dims_out=dims([2 1]);
end

% draw annotations
if exist('annotations','var') && ~isempty(annotations)
    for i=1:size(patches,4)
        text(mod(i-1,dims_out(1))*s_sz(2),floor((i-1)/dims_out(1))*s_sz(1)+8,annotations(i,:),...
            'BackgroundColor',[1 1 1],'Margin',0.0001,'FontSize',9);
    end
end