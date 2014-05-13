classdef annotation_list
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
        coords;      % Kx3xN array of single. The coordinates of the K keypoints (or nan if keypoint absent)
        visible;     % KxN array of logical. Whether each keypoint is visible
        keypoint_z_order;  % KxN1 array of uint8 specifying the relative distance of a keypoint to its parent (1=closer, 2=equal, 3=further away, 0=unspecified). N1=number of primary keypoints

        segment_ids; % Nx1 array of sets of uint16. IDs of each marked segment in the segmentation image
        segment_labels; % Nx1 array of sets of uint8. The label corresponding to each segment in segment_ids

        image_id;    % Nx1 array of uint32. ID of the image for the n-th annotation in the 'im' struct
        img_flipped; % Nx1 array of logical. Whether the annotation comes from a left-right flipped image
        entry_id;    % Nx1 array of uint16. ID of the current annotation.
        entry_in_image_id; % Nx1 array of uint16. Unique ID of the annotation from all annotations of the same image
        subcategory; % Nx1 array of cell (string). Entries are strings like 'Male','Female','Child', or 'military','commercial',etc. May be empty
        pose;        % Nx1 array of uint8. 0=unspecified, 1='Left',2='Right',3='Frontal',4='Rear'
        bounds;         % Nx4 array of single. The visible bounding box (or nan if not available)
        voc_id;      % Nx1 array of uint8. The index-in-image of the corresponding object in the PASCAL VOC structure (or 0 if not applicable/unknown)
        
        category_id; % ID of the category. For example config.CLASSES{category_id} == "person"
    end
    methods        
        function num=size(a)
           num=length(a.image_id); 
        end
        function is=isempty(a)
           is=isempty(a.image_id); 
        end

        %%% Appends anotations a2 at the end of annotations a
        function a=append(a,a2)
            assert(a.category_id==a2.category_id);
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
            a.subcategory(range)=a2.subcategory;
            a.pose(range)=a2.pose;
            a.segment_ids(range)=a2.segment_ids;
            a.segment_labels(range)=a2.segment_labels;
            a.bounds(range,:)=a2.bounds;
            a.keypoint_z_order(:,range) = a2.keypoint_z_order;
            a.voc_id(range) = a2.voc_id;

            a.entry_id(:)=1:a.size;
        end
        
        %%% Returns a subset of the annotations
        function a=select(a,subset)
            if isempty(subset)
                a=annotation_list(a.category_id);
            else
                a.coords = a.coords(:,:,subset);
                a.visible = a.visible(:,subset);
                a.image_id = a.image_id(subset);
                a.img_flipped = a.img_flipped(subset);        
                a.entry_id = a.entry_id(subset);
                a.entry_in_image_id = a.entry_in_image_id(subset);
                a.subcategory = a.subcategory(subset);
                a.pose = a.pose(subset);
                a.segment_ids = a.segment_ids(subset);
                a.segment_labels = a.segment_labels(subset);
                a.bounds = a.bounds(subset,:);
                a.keypoint_z_order = a.keypoint_z_order(:,subset);
                a.voc_id = a.voc_id(subset);
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
        
        % Read from a directory of files
        function a=annotation_list(root_dir)
            if isscalar(root_dir)
               a.category_id=root_dir;
               return;
            end
            a=read_annotations(a,root_dir);
        end
         
        function xmlwrite(a,root_dir)
            write_annotations(a,root_dir);
        end
        
        % Returns annotations flipped horizontally. The h3d training and test
        % set are doubled by adding the horizontal flips.
        function a=get_flipped_annotations(a)
            global im;
            global config;
            K = config.K(a.category_id);
            a.img_flipped=~a.img_flipped;

            % Swap the left and right keypoints
            a.coords(K.KEYPOINT_FLIPMAP(:,1),:,:) = a.coords(K.KEYPOINT_FLIPMAP(:,2),:,:);
            a.visible(K.KEYPOINT_FLIPMAP(:,1),:) = a.visible(K.KEYPOINT_FLIPMAP(:,2),:);
            primary_fp_idx = all(K.KEYPOINT_FLIPMAP<=K.NumPrimaryKeypoints,2);
            a.keypoint_z_order(K.KEYPOINT_FLIPMAP(primary_fp_idx,1),:) = a.keypoint_z_order(K.KEYPOINT_FLIPMAP(primary_fp_idx,2),:);

            % Flip the X coordinates
            image_width = double(im.dims(a.image_id,1));
            for i=1:a.size
                a.coords(:,1,i) = image_width(i) - a.coords(:,1,i)+1;
            end
            a.bounds(:,1) = image_width - a.bounds(:,1)-a.bounds(:,3)+2;

            % Flip the left/right of the pose
            swapped_pose = [2 1 3 4];
            a.pose(a.pose>0) = swapped_pose(a.pose(a.pose>0));

            % Flip the region labels. For example "left hand" with "right hand"
            assert(isequal(K.AREA_FLIPMAP(:,1),(1:length(K.AreaNames))'));
            for i=1:a.size
                a.segment_labels{i} = K.AREA_FLIPMAP(a.segment_labels{i},2);
            end
        end

    end
end

function has=annotation_contains_part(a,idx,region)
    has = ismember(region, a.segment_labels{idx});
end
