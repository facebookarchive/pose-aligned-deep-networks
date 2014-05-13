function [a,voc_id]=generate_annotations(dataset_name,info_list_file)
global K;
global im;
global config;


dataset_dir = [config.DATASET_DIR '/' dataset_name];
if ~exist('info_list_file','var')
    info_list_file = 'image_list.txt';
end

fid = fopen([dataset_dir '/' info_list_file],'r');
C = textscan(fid,'%s');
info_files = C{1};
fclose(fid);

numUniqueAnnotations = size(info_files,1);
numAnnotations = numUniqueAnnotations*2;

a=annotations;
a.coords = zeros([K.NumLabels 3 numAnnotations]);
a.visible = logical(zeros(K.NumLabels,numAnnotations)); %#ok<LOGL>
a.image_id = zeros(numAnnotations,1,'uint16');
a.img_flipped = false(numAnnotations,1);
a.entry_id = uint16(1:numAnnotations)';
a.entry_in_image_id = zeros(numAnnotations,1,'uint16');
a.body_type = cell(numAnnotations,1);
a.segment_ids = cell(numAnnotations,1);
a.segment_labels = cell(numAnnotations,1);
a.bounds = nan(numAnnotations,4);
a.keypoint_z_order = zeros(K.NumLabels,numAnnotations);
voc_id=nan(numAnnotations,1);


for i=1:numUniqueAnnotations
    body_type='';
    
    % strip away optional .gnd
    qq=findstr(info_files{i},'.gnd');
    if ~isempty(qq)
       info_files{i}=info_files{i}(1:(qq-1)); 
    end
    stem = info_files{i}(1:findstr(info_files{i},'.jpg')-1);
    im_idx = find(ismember(im.stem,stem));
    assert(isscalar(im_idx));       % im must include all images referenced by info
    a.image_id(i) = im_idx;

    fid = fopen([dataset_dir '/info/' info_files{i} '.gnd'],'r');
    C = textscan(fid,'%s %f %f %f %s %s');
    if isequal(C{1}{end},'body_type') || isequal(C{1}{end},'view')
        body_type = textscan(fid,'%s',1);
    end
    
    % read region info
    seg_ids = [];
    seg_labels = [];
    while 1
        region_name = textscan(fid,'%s',1);
        if isempty(region_name{1})
            break;
        end
        if isequal(region_name{1}{1},'bounds')
            BX=textscan(fid,'%f');
           a.bounds(i,:)=BX{1}';           
           continue;
        elseif isequal(region_name{1}{1},'id_in_voc_rec')
            BX=textscan(fid,'%d');
            voc_id(i)=BX{1};
            continue;
        elseif isequal(region_name{1}{1},'view')
            body_type=textscan(fid,'%s',1);
            continue;            
        end
        region = find(ismember(K.AreaNames, region_name{1}{1}));
        assert(isscalar(region));
        vals = textscan(fid,'%d');  
        seg_ids = [seg_ids; vals{1}]; %#ok<AGROW>
        seg_labels = [seg_labels; ones(length(vals{1}),1)*region]; %#ok<AGROW>
    end
    a.segment_ids{i} = seg_ids;
    a.segment_labels{i} = seg_labels;
    
    fclose(fid);

    coords = nan(K.NumLabels,3);
    visible = false(K.NumLabels,1);
    keypoints = C{1};
    for j=1:length(keypoints)
        if isequal(keypoints{j}(end),',')
            keypoints{j}(end)=[];
        end
        if isequal(keypoints{j},'R_ELbOW')
            keypoints{j}='R_ELBOW';     % Typo in some of the data
        end
        idx = find(ismember(K.Labels,keypoints{j}));
        if isscalar(idx)
            coords(idx,:) = [C{2}(j) C{3}(j) C{4}(j)];
            fnd = find(ismember({'Close','Equal','Far'},C{5}{j}));
            assert(isscalar(fnd));
            a.keypoint_z_order(idx,i)=fnd;                    
            visible(idx) = isequal(C{6}{j},'visible');
        elseif isequal(keypoints{j},'bounds')
            a.bounds(i,:) = [C{2}(j) C{3}(j) C{4}(j) str2num(C{5}{j})];
        elseif isequal(keypoints{j},'id_in_voc_rec')
            voc_id(i)=C{2}(j);
        elseif ~isequal(keypoints{j},'body_type') && ~isequal(keypoints{j},'view')
            error('Unrecognized: %s',keypoints{j});
        end
    end
        
    a.coords(:,:,i) = coords;
    a.visible(:,i) = visible;
    
    s1=findstr(info_files{i},';');
    if isempty(s1)
        a.entry_in_image_id(i) = 0;
    else
        a.entry_in_image_id(i) = str2double(info_files{i}((s1+1):end));
    end
    if ~isempty(body_type) && ~isempty(body_type{1})
        a.body_type(i) = body_type{1};
    end
    if mod(i,100)==0
       fprintf('.'); 
    end
end
fprintf('\n');

a.visible(:,1:numUniqueAnnotations) = fix_kp_visibility(a.select(1:numUniqueAnnotations));
% For any annotations that have segmentation labels but no bounds, infer
% the bounds from the seg labels
num_missing_bounds=sum(isnan(a.bounds(:,1)));
if isequal(config.OBJECT_TYPE,'person')
    a = find_real_visible_bounds(a);
end
num_corrected_bounds=num_missing_bounds-sum(isnan(a.bounds(:,1)));
if num_corrected_bounds>0
   disp(sprintf('Found the visible bounds of %d annotations from their labeled regions', num_corrected_bounds));
end

regular = 1:numUniqueAnnotations;
flipped = numUniqueAnnotations+regular;
a.img_flipped(flipped) = true;
a.img_flipped(regular) = false;
voc_id(flipped) = voc_id(regular);
a.coords(:,:,flipped) = a.coords(:,:,regular);
a.coords(K.KEYPOINT_FLIPMAP(:,1),:,flipped) = a.coords(K.KEYPOINT_FLIPMAP(:,2),:,regular);
a.visible(:,flipped) = a.visible(:,regular);
a.visible(K.KEYPOINT_FLIPMAP(:,1),flipped) = a.visible(K.KEYPOINT_FLIPMAP(:,2),regular);
a.image_id(flipped) = a.image_id(regular);
a.entry_in_image_id(flipped) = a.entry_in_image_id(regular);
a.body_type(flipped) = a.body_type(regular);
a.segment_ids(flipped) = a.segment_ids(regular);
a.bounds(flipped,:) = a.bounds(regular,:);
a.keypoint_z_order(:,flipped) = a.keypoint_z_order(:,regular);
a.keypoint_z_order(K.KEYPOINT_FLIPMAP(:,1),flipped) = a.keypoint_z_order(K.KEYPOINT_FLIPMAP(:,2),regular);

% Flip X coordinate
for i=numUniqueAnnotations+(1:numUniqueAnnotations)
    W = double(im.dims(a.image_id(i),1));
    a.coords(:,1,i) = W-a.coords(:,1,i)+1;
    a.bounds(i,1) = W-a.bounds(i,1)-a.bounds(i,3)+2; % change xmin
    if isequal(a.body_type{i-numUniqueAnnotations},'Left')
        a.body_type{i}='Right';
    elseif isequal(a.body_type{i-numUniqueAnnotations},'Right')
        a.body_type{i}='Left';        
    end
end


assert(isequal(K.AREA_FLIPMAP(:,1),(1:length(K.AreaNames))'));
for i=1:numUniqueAnnotations
    a.segment_labels{numUniqueAnnotations+i} = K.AREA_FLIPMAP(a.segment_labels{i},2);
end

% Add the helper keypoints
for i=1:size(K.MID_KEYPOINTS,1)
    a.coords(K.MID_KEYPOINTS(i,1),:,:) = mean(a.coords([K.MID_KEYPOINTS(i,2:3)],:,:));
    a.visible(K.MID_KEYPOINTS(i,1),:) = a.visible(K.MID_KEYPOINTS(i,2),:) & a.visible(K.MID_KEYPOINTS(i,3),:);
end

end

function visible=fix_kp_visibility(a)
    global im;
    % Keypoints outside the image bounds are marked invisible
    num_kp = size(a.coords,1);
    visible=a.visible;
    
    x_coords = round(squeeze(a.coords(:,1,:)));
    im_width=im.dims(a.image_id,1);
    visible(x_coords<1 | x_coords>repmat(im_width,1,num_kp)' | isnan(x_coords)) = false;
    
    y_coords = round(squeeze(a.coords(:,2,:)));
    im_height=im.dims(a.image_id,2);
    visible(y_coords<1 | y_coords>repmat(im_height,1,num_kp)' | isnan(y_coords)) = false;
end

function a=find_real_visible_bounds(a)
global im;
global config;
global K;

% All H3D images that have no specified bounds but segmentation: Use the
% union of the segmented labels to set the bounds

foreground_labels = [K.A_Face K.A_Hair K.A_UpperClothes K.A_LeftArm K.A_RightArm K.A_LowerClothes K.A_LeftLeg K.A_RightLeg K.A_LeftShoe K.A_RightShoe K.A_Neck K.A_Hat K.A_LeftGlove K.A_RightGlove K.A_LeftSock K.A_RightSock K.A_Sunglasses K.A_Dress];
foreground_and_bad_labels = [foreground_labels K.A_BadSegment];

cur_imgid = nan;
for i=find(isnan(a.bounds(:,1)))'
    if a.image_id(i)==0
        continue;
    end
    segs_file = im.segs_file{a.image_id(i)};
    if isempty(segs_file) || isempty(a.segment_ids{i})
        continue;
    end
    if a.image_id(i)~=cur_imgid
       segs_img = imread(segs_file);
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