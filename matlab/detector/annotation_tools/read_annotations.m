function a=read_annotations(a,root_dir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Reads the annotation list from a directory of XML files.
%%% Don't call directly. Instead call the annotation_list constructor.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global im;
    global config;
    
    if exist(root_dir,'file')==7 % directory
        fdir = dir([root_dir '/*.xml']);
        if isempty(fdir)
            error('The directory %s has no XML info files',root_dir);
        end
        for i=1:length(fdir)
           files{i}=fdir(i).name; 
        end
    elseif exist(root_dir,'file')==2 % file
        fid = fopen(root_dir);
        files = textscan(fid,'%s');
        fclose(fid);
        files=files{1};
        root_dir = [fileparts(root_dir) '/info'];
    end

    for i=1:length(files)
        docNode = xmlread([root_dir '/' files{i}]);
        docRootNode = docNode.getDocumentElement;

        category = docRootNode.getElementsByTagName('category').item(0).getFirstChild.getNodeValue.toCharArray';
        category_id = find(ismember(config.CLASSES,category));
        if ~isscalar(category_id)
            error('Annotation %s has unrecognized category %s',files{i},category);
        end
        if i==1
            % Initialize based on the category
            K = config.K(category_id);

            a.category_id = category_id;
            a.coords=nan(length(K.Labels),3,length(files),'single');
            a.visible=false(length(K.Labels),length(files));
            a.keypoint_z_order=zeros(K.NumPrimaryKeypoints,length(files),'uint8');
            a.image_id=zeros(length(files),1,'uint16');
            a.img_flipped=false(length(files),1);
            a.entry_id=zeros(length(files),-1,'uint32');
            a.voc_id=zeros(length(files),1,'uint8');
            a.pose=zeros(length(files),1,'uint8');
            a.entry_in_image_id=zeros(length(files),1,'uint8');
            a.bounds=nan(length(files),4,'single');
        elseif category_id~=a.category_id
            error('Annotation %s has category %s but previous one was %s',files{i},category,config.CLASSES{a.category_id});
        end


        if docRootNode.hasAttribute('id')
            a.entry_id(i) = str2num(docRootNode.getAttribute('id'));
        end

        eiim=strfind(files{i},'_');
        if isempty(eiim)
            error('%s is nonstandard xml annotation name.', files{i});
        end
        a.entry_in_image_id(i)=str2num(files{i}((eiim(end)+1):(end-4)));


        imgName = docRootNode.getElementsByTagName('image').item(0).getFirstChild.getNodeValue.toCharArray';
        if ~isequal(imgName,files{i}(1:(eiim(end)-1)))
            error('xml file name is %s but the image inside is %s',files{i},imgName);
        end
        img_id = find(ismember(im.stem,imgName));
        if ~isscalar(img_id)
            error('Unknown image %s in file %s',imgName,files{i});
        end
        a.image_id(i)=img_id;

        subcat = docRootNode.getElementsByTagName('subcategory').item(0);
        if ~isempty(subcat)
            subcat = subcat.getFirstChild.getNodeValue.toCharArray';
        end
        a.subcategory{i,1}=subcat;

        bounds = docRootNode.getElementsByTagName('visible_bounds').item(0);
        if ~isempty(bounds)
            a.bounds(i,:) = str2num([bounds.getAttribute('xmin').toCharArray' ' ' bounds.getAttribute('ymin').toCharArray' ' '...
                bounds.getAttribute('width').toCharArray' ' ' bounds.getAttribute('height').toCharArray']);
        else
            a.bounds(i,:) = [nan nan nan nan];
        end

        pose = docRootNode.getElementsByTagName('pose').item(0);
        if ~isempty(pose)
            poseStr=pose.getFirstChild.getNodeValue.toCharArray';
            pose_id = find(ismember({'Left','Right','Frontal','Rear'},poseStr));
            if ~isscalar(pose_id)
                error('Unknown pose %s in file %s',poseStr,files{i});
            end
            a.pose(i) = pose_id;
        else
            a.pose(i)=0;
        end

        voc_id_node = docRootNode.getElementsByTagName('voc_id').item(0);
        if ~isempty(voc_id_node)
            a.voc_id(i)=str2num(voc_id_node.getFirstChild.getNodeValue.toCharArray');
        else
            a.voc_id(i)=0;
        end

        a.coords(:,:,i)=nan;
        a.visible(:,i)=false;
        a.keypoint_z_order(:,i)=0;
        kpNodes = docRootNode.getElementsByTagName('keypoints').item(0).getElementsByTagName('keypoint');
        for kp=0:(kpNodes.getLength-1)
            name=kpNodes.item(kp).getAttribute('name').toCharArray';
            kpid = find(ismember(K.Labels,name));
            if ~isscalar(kpid)
                error('Unknown keypoint %s in file %s',name, files{i});
            end
            a.visible(kpid,i)  = str2num(kpNodes.item(kp).getAttribute('visible').toCharArray');
            a.coords(kpid,1,i) = str2num(kpNodes.item(kp).getAttribute('x').toCharArray');
            a.coords(kpid,2,i) = str2num(kpNodes.item(kp).getAttribute('y').toCharArray');
            a.coords(kpid,3,i) = str2num(kpNodes.item(kp).getAttribute('z').toCharArray');
            a.keypoint_z_order(kpid,i)=str2num(kpNodes.item(kp).getAttribute('zorder').toCharArray');
        end

        a.segment_ids{i}=uint16([]);
        a.segment_labels{i}=uint8([]);
        segNodes = docRootNode.getElementsByTagName('segments').item(0);
        if ~isempty(segNodes)
            segNodes = segNodes.getElementsByTagName('segment');
            for kp=0:(segNodes.getLength-1)
                name=segNodes.item(kp).getAttribute('name').toCharArray';
                kpid = find(ismember(K.AreaNames,name));
                if ~isscalar(kpid)
                    error('Unknown region name %s in file %s',name, files{i});
                end
                seg_ids = str2num(segNodes.item(kp).getAttribute('segments').toCharArray');
                a.segment_ids{i} = [a.segment_ids{i} seg_ids];
                a.segment_labels{i} = [a.segment_labels{i} repmat(kpid,1,length(seg_ids))];
            end
        end
        disp(files{i});
    end

    a.visible = fix_kp_visibility(a);
    % For any annotations that have segmentation labels but no bounds, infer
    % the bounds from the seg labels
    num_missing_bounds=sum(isnan(a.bounds(:,1)));
    if isequal(config.CLASSES{a.category_id},'person')
        a = find_real_visible_bounds(a);
        num_corrected_bounds=num_missing_bounds-sum(isnan(a.bounds(:,1)));
        if num_corrected_bounds>0
            disp(sprintf('Inferred the visible bounds of %d annotations from their labeled regions', num_corrected_bounds));
        end
    end

    % Add the helper keypoints
    for i=1:size(K.MID_KEYPOINTS,1)
        a.coords(K.MID_KEYPOINTS(i,1),:,:) = mean(a.coords([K.MID_KEYPOINTS(i,2:3)],:,:));
        a.visible(K.MID_KEYPOINTS(i,1),:) = a.visible(K.MID_KEYPOINTS(i,2),:) & a.visible(K.MID_KEYPOINTS(i,3),:);
    end

    % Reorder annotations in entryid order
    if any(a.entry_id==-1)
        disp('Warning! Some entries have no entry_id. Placing them at the end');
    end
    [srt,srtd] = sort(a.entry_id);
    a=a.select(srtd);
end

% Keypoints outside the image bounds are marked invisible
function visible=fix_kp_visibility(a)
    global im;
    num_kp = size(a.coords,1);
    visible=a.visible;

    x_coords = round(squeeze(a.coords(:,1,:)));
    im_width=im.dims(a.image_id,1);
    visible(x_coords<1 | x_coords>repmat(im_width,1,num_kp)' | isnan(x_coords)) = false;

    y_coords = round(squeeze(a.coords(:,2,:)));
    im_height=im.dims(a.image_id,2);
    visible(y_coords<1 | y_coords>repmat(im_height,1,num_kp)' | isnan(y_coords)) = false;
end

% All H3D images that have no specified bounds but segmentation: Use the
% union of the segmented labels to set the bounds
function a=find_real_visible_bounds(a)
    global im;
    global config;
    K = config.K(a.category_id);

    foreground_labels = [K.A_Face K.A_Hair K.A_UpperClothes K.A_LeftArm K.A_RightArm K.A_LowerClothes K.A_LeftLeg K.A_RightLeg K.A_LeftShoe K.A_RightShoe K.A_Neck K.A_Hat K.A_LeftGlove K.A_RightGlove K.A_LeftSock K.A_RightSock K.A_Sunglasses K.A_Dress];
    foreground_and_bad_labels = [foreground_labels K.A_BadSegment];

    cur_imgid = nan;
    for i=find(isnan(a.bounds(:,1)))'
        if a.image_id(i)==0
            continue;
        end
        s_file = segs_file(a.image_id(i));
        if isempty(s_file) || isempty(a.segment_ids{i})
            continue;
        end
        if a.image_id(i)~=cur_imgid
            segs_img = imread(s_file);
            if a.img_flipped(i)
                segs_img=segs_img(:,end:-1:1);
            end
            cur_imgid=a.image_id(i);
        end
        % Get the bounds of the foreground regions, excluding the bad segments.
        % This is the default bounds
        sel=ismember(segs_img,a.segment_ids{i}(ismember(a.segment_labels{i},foreground_labels)));
        sel=imerode(imdilate(sel,ones(3)),ones(3));
        x_span = any(sel);
        y_span = any(sel,2);
        min_pt = [find(x_span,1) find(y_span,1)];
        max_pt = [find(x_span,1,'last') find(y_span,1,'last')];

        % Get bounds of the visible keypoints and take the union
        if any(a.visible(:,i))
            kp_min_pt = squeeze(min(a.coords(a.visible(:,i),1:2,i)));
            kp_max_pt = squeeze(max(a.coords(a.visible(:,i),1:2,i)));
            if any(kp_min_pt<min_pt) || any(kp_max_pt>max_pt)
                % There are visible keypoints outside the foreground bounds.
                % Allow the bounds to grow, but only up to the foreground
                % bounds that include the bad segment labels
                selb=ismember(segs_img,a.segment_ids{i}(ismember(a.segment_labels{i},foreground_and_bad_labels)));
                selb=imerode(imdilate(selb,ones(3)),ones(3));
                x_span = any(selb);
                y_span = any(selb,2);
                min_pt_b = [find(x_span,1) find(y_span,1)];
                max_pt_b = [find(x_span,1,'last') find(y_span,1,'last')];

                if config.DEBUG>0
                    img=imread(image_file(a.image_id(i)));
                    if a.img_flipped(i)
                        img=img(:,end:-1:1,:);
                    end
                    img_b=img(:,:,3);
                    img_b(sel)=255;
                    img(:,:,3)=img_b;
                    imshow(img);
                    rectangle('position',[min_pt max_pt-min_pt],'edgecolor','g');
                    min_pt=min(min_pt,kp_min_pt);
                    max_pt=max(max_pt,kp_max_pt);
                    rectangle('position',[min_pt max_pt-min_pt],'edgecolor','y');
                    min_pt=max(min_pt,min_pt_b);
                    max_pt=min(max_pt,max_pt_b);
                    rectangle('position',[min_pt max_pt-min_pt],'edgecolor','r','linewidth',2);
                    keyboard;
                else
                    min_pt=max(min(min_pt,kp_min_pt),min_pt_b);
                    max_pt=min(max(max_pt,kp_max_pt),max_pt_b);
                end
            end
        end

        if any(min_pt<1) || any(max_pt>im.dims(a.image_id(i),:))
            min_pt=max(1,min_pt);
            max_pt=min(im.dims(a.image_id(i),:),max_pt);
        end

        a.bounds(i,:) = [min_pt max_pt-min_pt];

        if config.DEBUG>1
            img=imread(image_file(a.image_id(i)));
            img_b=img(:,:,3);
            img_b(sel)=255;
            img(:,:,3)=img_b;
            imshow(img);
            rectangle('position',a.bounds(i,:),'edgecolor','r','linewidth',2);
            keyboard;
        end
    end
end