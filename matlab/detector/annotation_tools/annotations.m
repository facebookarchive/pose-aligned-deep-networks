classdef annotations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Represents a list of training or test annotations. Each annotation
%%% includes 3D coordiantes of keypoints, visibility and region annotations.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        coords;      % Kx3xN array of double. The coordinates of the K keypoints (or nan if keypoint absent)
        visible;     % KxN array of logical. Whether each keypoint is visible
        image_id;    % Nx1 array of unit16. ID of the image for the n-th annotation in the 'im' struct
        img_flipped; % Nx1 array of logical. Whether the annotation comes from a left-right flipped image
        entry_id;    % Nx1 array of uint16. ID of the current annotation.
        entry_in_image_id; % Nx1 array of uint16. Unique ID of the annotation from all annotations of the same image
        body_type;   % Nx1 array of cell (string). Entries are strings like 'Male','Female','Child'.
        segment_ids; % Nx1 array of sets of uints. IDs of each marked segment in the segmentation image
        segment_labels; % Nx1 array of sets of uints. The label corresponding to each segment in segment_ids
        bounds;         % Nx4 array of double. The visible bounding box (or nan if not available)
        keypoint_z_order;  % KxN array of uint8 specifying the relative distance of a keypoint to its parent (1=closer, 2=equal, 3=further away, 0=unspecified)
    end
    methods        
        function a1=annotations(a)
            for fn=fieldnames(a)'
                a1=setfield(a1,fn{1},getfield(a,fn{1}));
            end           
        end
        function num=size(a)
           num=length(a.image_id); 
        end
        function is=isempty(a)
           is=isempty(a.image_id); 
        end

        %%% Appends anotations a2 at the end of annotations a
        function a=append(a,a2)
            if isempty(a2)
                return;
            end
            range=a.size+(1:a2.size);
            a.coords(:,:,range)=a2.coords;
            a.visible(:,range)=a2.visible;
            a.image_id(range)=a2.image_id;
            a.img_flipped(range)=a2.img_flipped;
            a.entry_id(range)=a2.entry_id;
            a.entry_in_image_id(range)=a2.entry_in_image_id;
            a.body_type(range)=a2.body_type;
            a.segment_ids(range)=a2.segment_ids;
            a.segment_labels(range)=a2.segment_labels;
            a.bounds(range,:)=a2.bounds;
            a.keypoint_z_order(:,range) = a2.keypoint_z_order;

            a.entry_id(:)=1:a.size;
        end
        
        %%% Returns a subset of the annotations
        function a=select(a,subset)
            if isempty(subset)
                a=annotations;
            else
                a.coords = a.coords(:,:,subset);
                a.visible = a.visible(:,subset);
                a.image_id = a.image_id(subset);
                a.img_flipped = a.img_flipped(subset);        
                a.entry_id = a.entry_id(subset);
                a.entry_in_image_id = a.entry_in_image_id(subset);
                a.body_type = a.body_type(subset);
                a.segment_ids = a.segment_ids(subset);
                a.segment_labels = a.segment_labels(subset);
                a.bounds = a.bounds(subset,:);
                a.keypoint_z_order = a.keypoint_z_order(:,subset);
            end
        end
        
        %%% Like select, but the subset is entry IDs instead of direct indices
        function a=select_entries(a,subset)
            idx = zeros(1,length(subset));
            for i=1:length(subset)
                idx(i) = find(a.entry_id==subset(i),1);
            end
            a=a.select(idx);            
        end
        
        % Returns a subset of the annotations that contain a given part
        function ret=contain_part(a,part_id)
            ret=arrayfun(@(x)annotation_contains_part(a,x,part_id),1:a.size);
        end
        
        function bounds = get_bounds(a, pad, stay_in_image, pad_even_real_bounds)
            % Returns a Nx4 array comprising the image space 2D bounding boxes 
            % of the N annotations (the bounding boxes that include all annotated
            % keypoints). Optionally can add padding as a percentage of the dimensions
            % A bounding box is represented as [x_min y_min width height]
            % The bounding box may partly fall outside the image, since keypoint coords
            % may be specified outside the image

            N = a.size;
            if N==1
                min_pt = min(a.coords(:,1:2));
                dims = max(a.coords(:,1:2)) - min_pt;
            else
                min_pt = squeeze(min(a.coords(:,1:2,:)))';
                dims  = squeeze(max(a.coords(:,1:2,:)))' - min_pt;    
            end
            dims=max(dims,1);
            bounds = [min_pt dims];

            if exist('pad','var')
                if isscalar(pad)
                    frame = mean(dims,2)*pad;
                   bounds = bounds + [-frame -frame 2*frame 2*frame];
                else
                   bounds = bounds + ones(N,1)*[-pad 2*pad].*[dims dims];
                end
            end

            a_real_bounds = ~isnan(a.bounds(:,1));
            bounds(a_real_bounds,:) = a.bounds(a_real_bounds,:); % if the bounds are provided, no need to estimate them

            if exist('pad_even_real_bounds','var') && pad_even_real_bounds && ~isequal(a_real_bounds,0)
                if isscalar(pad)
                    frame = mean(dims(a_real_bounds,:),2)*pad;
                    bounds(a_real_bounds,:) = bounds(a_real_bounds,:) + [-frame -frame 2*frame 2*frame];
                else
                    bounds(a_real_bounds,:) = bounds(a_real_bounds,:) + repmat([-pad 2*pad],sum(a_real_bounds),1).*[dims(a_real_bounds,:) dims(a_real_bounds,:)];
                end
            end


            if exist('stay_in_image','var') && stay_in_image
               global im;
               max_pt = min(bounds(:,1:2)+bounds(:,3:4), double(im.dims(a.image_id,:)));
               bounds(:,1:2) = max(bounds(:,1:2),1);
               bounds(:,3:4) = max_pt - bounds(:,1:2)-1;   
            end

            % round them
            min_pt = bounds(:,1:2);
            max_pt = bounds(:,1:2)+bounds(:,3:4);
            bounds = round([min_pt  max_pt-min_pt]);
        end
    end
end

function has=annotation_contains_part(a,idx,region)
    has = ismember(region, a.segment_labels{idx});
end
