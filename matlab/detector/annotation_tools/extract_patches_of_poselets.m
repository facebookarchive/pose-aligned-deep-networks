function [all_patches,falls_outside,all_labels] = extract_patches_of_poselets(a,poselets,interp,pad)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Given a set poselets extracts the image patches associated with their
%%% examples and normalizes them to the unit size of the poselet
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

global im;
global config;

if ~exist('interp','var')
    interp='bilinear';
end

if ~exist('pad','var')
    if config.USE_PHOG
        pad=4;
    else
        pad=1; 
    end
end

need_labels = nargout>2;

for p=1:length(poselets)
    patch_dims = poselets(p).dims + pad*2;
    all_patches{p} = zeros([patch_dims 3 poselets(p).size],'uint8'); 
    if need_labels
       all_labels{p} = zeros([patch_dims poselets(p).size],'uint8'); 
    end
    
    falls_outside{p}=false(1,poselets(p).size);
end

% index for each annotation which poselets and poselet examples use it
for annot_id=1:a.size
    poselets_in_annot{annot_id}=zeros(0,2);
end
for p=1:length(poselets)
   for ex_idx=1:poselets(p).size
       poselets_in_annot{poselets(p).dst_entry_ids(ex_idx)}(end+1,:)=[p ex_idx];
   end
end

% Loop over the annotations that are used by at least one example
for annot_id=find(~cellfun(@isempty,poselets_in_annot))
    img = imread(image_file(a.image_id(annot_id)));
    if size(img,3)==1
       img1(:,:,1)=img;
       img1(:,:,2)=img;
       img1(:,:,3)=img;
       img=img1;
       clear img1;
    end
    if a.img_flipped(annot_id)
       img = img(:,end:-1:1,:);        
    end
    
    
    if need_labels
        if ~isempty(segs_file(a.image_id(annot_id)))
            labels_img = uint16(bwlabel(imread(segs_file(a.image_id(annot_id)))<16384));
            labels_img = imerode(imdilate(labels_img,ones(3)),ones(3));
        else
            labels_img = zeros(size(img,1),size(img,2),'uint16'); 
        end
        if a.img_flipped(annot_id)
            labels_img = labels_img(:,end:-1:1,:);            
        end
    end
    
    for j=1:size(poselets_in_annot{annot_id},1)
        p=poselets_in_annot{annot_id}(j,1);
        i=poselets_in_annot{annot_id}(j,2);

        patch_dims = poselets(p).dims + pad*2;
        img2unit_xform=poselets(p).img2unit_xforms(:,:,i);
        [patch_channels,fo] = transform_resize_crop(img, img2unit_xform, patch_dims([2 1]), interp);
        falls_outside{p}(i) = fo;
        all_patches{p}(:,:,:,i) = patch_channels;
        if need_labels
             xformed_parts = transform_resize_crop(labels_img, img2unit_xform, patch_dims([2 1]), 'nearest',0);
             if ~isempty(a.segment_labels{annot_id})
                 lookup=zeros(max(labels_img(:))+1,1,'uint16');
                 lookup(1)=config.K(a.category_id).A_Occluder; % occluder
                 lookup(a.segment_ids{annot_id}+1) = a.segment_labels{annot_id};
                 all_labels{p}(:,:,i) = lookup(xformed_parts+1);
             else
                 all_labels{p}(:,:,i) = zeros(patch_dims,'uint8'); 
             end         
        end
    end    
end
fprintf('\n');


end