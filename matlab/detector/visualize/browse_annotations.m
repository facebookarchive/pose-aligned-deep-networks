function browse_annotations(a)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  Allows browsing through the annotations and constructing poselets for
%%%  a user-specified bounding box. Press '?' for instructions
%%%
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global g;
global config;


g.a = a;
g.show_keypoints=false;
g.show_region_labels=false;
g.show_skeleton=false;
g.show_flat_colors=false;
g.show_pb_edges=false;
g.threshold=0;
curAnnotation=1;
disp('Press ''?'' for instructions');

while 1
    % See if the image needs to be updated
    g.idx = curAnnotation;
    redraw;
    set(1,'Position',[100 100 600 400]);


    while 1
        [x,y,ch] = ginput(1);
        if isscalar(ch)
            break;
        end
    end
    switch ch                   
        case 27 % ESC
            windows = 1:5;
            close(windows(ishandle(windows)));
            return;
        case '`'
            return;
            
        case '?'
              disp('<-, ->  -- navigate the annotations');
              disp('g       -- go to specific annotation');
              disp('space   -- draw a rectangle and create a poselet from it');
              disp('l       -- toggle foreground');
              disp('k       -- toggle keypoints');
              disp('s       -- toggle skeleton (for person category only)');
              disp('f       -- toggle flat colors');
              disp('e       -- toggle region boundaries');
              disp('up/down -- change the region granularity (if ''e'' or ''f'' is on)');
              disp('ESC     -- exit');

        case 29 % ->
            if curAnnotation<a.size
                curAnnotation=curAnnotation+1;
            end
        case 28 % <-
            if curAnnotation>1
                curAnnotation=curAnnotation-1;
            end
        case 30 % /\
            if g.threshold<255
                g.threshold=g.threshold+5;
            end
        case 31 % \/
            if g.threshold>0
                g.threshold=g.threshold-5;
            end
        case 'g'
            answer = str2double(inputdlg('Enter index:'));
            if ~isempty(answer)
                answer = round(answer);
                if answer>0 && answer<a.size
                    curAnnotation=answer;
                end
            end
        case 'k'
            g.show_keypoints=~g.show_keypoints;
        case 'l'
            g.show_region_labels=~g.show_region_labels;
            if ~g.show_region_labels && ishandle(11)
                close(11);
            else
                g.show_flat_colors=false;
                g.show_pb_edges=false;
            end
        case 's'
            if ~isequal(config.CLASSES{g.a.category_id},'person')
                disp('Skeleton only available for the person category');
            else
                g.show_skeleton=~g.show_skeleton;
            end
        case 'f'
            g.show_flat_colors=~g.show_flat_colors;
            if g.show_region_labels && ishandle(11)
                close(11);
                g.show_region_labels=false;
            end
        case 'e'
            g.show_pb_edges=~g.show_pb_edges;
            if g.show_region_labels && ishandle(11)
                close(11);
                g.show_region_labels=false;
            end
            
        case ' '
            rect = imrect;
            rect_pos = getPosition(rect);
            rect_pos(1:2) = rect_pos(1:2)-1;    % Make it 0-indexed
            ctr = rect_pos(1:2) + rect_pos(3:4)/2 + g.annot_bounds(1:2);
                             
            figure(1); clf;
            unit_dims = round([1 rect_pos(3)/rect_pos(4)]*100);          
            [p1, examples_info] = create_poselet_procrustes_dist(unit_dims, g.a.select(curAnnotation), [ctr rect_pos(3:4) 0], g.a);
            
            % Prevent examples that are too small or too rotated
            maxScale = config.MAX_ZOOM_THRESH/min(unit_dims);
            part = p1.select(examples_info.scale<=maxScale & ...
                (examples_info.rot<=pi-config.MIN_ROT_THRESH & examples_info.rot>=-pi+config.MIN_ROT_THRESH));
            
            if isempty(part) || part.size==0
                 continue;
            end
            figure(2);
            patches = extract_patches_of_poselets(a,part.select(1:10));
            display_patches(patches{1},[],[1 10]); 
            title('The most similar examples');
            
            figure(3);
            imshow(uint8(mean(patches{1},4))); 
            title('The average image');
            
            figure(4);
            scales = sqrt(sum(part.img2unit_xforms(1:2,1,:).^2));
            rots = asin(part.img2unit_xforms(2,1,:)./scales);
            cosin = part.img2unit_xforms(1,1,:)./scales < 0;
            rots(cosin) = rots(cosin)+pi;
            rose_fill(rots+pi/2);
            title('Poselet orientation histogram');
            
            figure(5);
            draw_scatter_keypoints(g.a,part.select(1:(min(part.size,40))));
             set(1,'Position',[100 100 600 400]);
             set(2,'Position',[100 550 600 150]);
             set(3,'Position',[700 100 200 200]);
             set(4,'Position',[900 100 200 200]);
             set(5,'Position',[700 300 400 400]);

            figure(1);
    end %switch%
end % while 1
end % main

function redraw(s,e)
    global g;  
    global im;
    global config;
    K = config.K(g.a.category_id);
    
    if g.show_pb_edges || g.show_flat_colors
        if ~im.has_segs(g.a.image_id(g.idx)) || ~exist(segs_file(g.a.image_id(g.idx)),'file')
           g.show_flat_colors=false;
           g.show_pb_edges=false;
           disp('Segmentations not available for this annotation. Disabling segmentation display.');
        end
    end

    figure(1);
    [display_img,labels,regions,annot_bounds]=display_annot(g.a.select(g.idx), g.show_flat_colors, g.show_skeleton, g.show_pb_edges, g.threshold);
    hold on;
    g.display_img = display_img;

    annot_b = g.a.select(g.idx).get_bounds;

    annot_b(1:2) = annot_b(1:2) - annot_bounds(1:2);
    rectangle('Position',annot_b,'EdgeColor','r');

    if g.show_keypoints
        KP_W=1;
       for i=find(~isnan(g.a.coords(:,1,g.idx))')
           ctr=double(g.a.coords(i,1:2,g.idx)- annot_bounds(1:2));
          rectangle('position',[ctr-[KP_W KP_W] KP_W*2 KP_W*2],'curvature',[1 1],'edgecolor','r');
          text(ctr(1),ctr(2),K.Labels{i},'color','r','interpreter','none');
       end
    end
    if g.show_region_labels
        if ~isempty(g.a.segment_ids{g.idx}) && exist(segs_file(g.a.image_id(g.idx)),'file')
           segs_img = imread(segs_file(g.a.image_id(g.idx)));
           if g.a.img_flipped(g.idx)
              segs_img=segs_img(:,end:-1:1); 
           end
           segs_img=imcrop(segs_img,annot_bounds);
           background_labels = [0 K.A_Occluder K.A_BadSegment];

           sel=ismember(segs_img,g.a.segment_ids{g.idx}(~ismember(g.a.segment_labels{g.idx},background_labels)));
           sel=imerode(imdilate(sel,ones(3)),ones(3));
           display_img_b=display_img(:,:,3);
           display_img_b(sel)=0;
           display_img_b(~sel)=255;
           display_img(:,:,3)=display_img_b;
           figure(11);
           imshow(display_img);
           figure(1);
        end
    end
    hold off;
    handle=title(sprintf('%s %d %s %d/%d',im.stem{g.a.image_id(g.idx)}, g.a.entry_id(g.idx), g.a.subcategory{g.idx},g.idx,g.a.size));
    set(handle,'Interpreter','none');
    g.annot_bounds = annot_bounds;
    %set(1,'Position',[100 100 600 400]);
end

function draw_scatter_keypoints(a,part)
    global config;
    clf;

    unit_coords = a.coords(:,:,part.dst_entry_ids);
    unit_coords(:,3,:) = 1;
    for i=1:part.size
        unit_coords(:,:,i) = unit_coords(:,:,i) * [part.img2unit_xforms(:,:,i) [0 0 1]'];
    end

    for i=1:config.K(a.category_id).NumLabels
        valid = ~isnan(squeeze(unit_coords(i,1,:)));
        if any(valid)
            stds(i) =  sum(std(squeeze(unit_coords(i,1:2,valid))'));
        end
    end
%    stds([K.M_Shoulder K.M_Hip]) = inf;
    [foo, srt] = sort(stds);

    SCATTER_GROUPS = 5;

    hold on;
    colors = jet(SCATTER_GROUPS);
    displayed = [];
    for i=1:SCATTER_GROUPS
        kp = srt(i);
        valid = ~isnan(squeeze(unit_coords(kp,1,:)));
        if any(valid)
            scatter(unit_coords(kp,1,valid), -unit_coords(kp,2,valid),100,colors(i,:),'.');
            displayed(end+1)=kp;
        end
    end
    handle = legend(config.K(a.category_id).Labels(displayed));
    set(handle,'Interpreter','none');
    axis([-1 1 -1 1]);
    w = part.dims(2) / mean(part.dims);
    h = part.dims(1) / mean(part.dims);
    rectangle('Position',[-w/2 -h/2 w h],'EdgeColor','r','LineStyle',':');
    axis equal;
    hold off;
    title(sprintf('Scatter of the tightest %d keypoints', SCATTER_GROUPS));
end


function [display_img,labels,regions,annot_bounds]=display_annot(b, showFlatColors, showSkeleton, showPbEdges, threshold, regionsToShow)
%%% Displays an annotation
%%%
%%% showPbEdges    - draws the Pb edges in red
%%% threshold      - the threshold defining the set of pb regions
%%% selection      - an optional set of selected pb regions drawn in thick boundary

labels = [];
regions = [];
if ~exist('threshold','var')
    threshold=0;
end
if ~exist('showPbEdges','var')
    showPbEdges=false;
end
if ~exist('showSkeleton','var')
    showSkeleton=false;
end
if ~exist('regionsToShow','var')
    regionsToShow=[];
end

use_pb = showFlatColors || showPbEdges || ~isempty(regionsToShow);

global im;
global config;
AreaNames = config.K(b.category_id).AreaNames;

PAD = [1 0.4];
SelectionColors = jet(length(AreaNames));


% Load the current image. Cache for performance
persistent cur_im_id;
persistent cur_im_is_flipped;
persistent img;
if ~isequal(cur_im_id,b.image_id)
    cur_im_id = b.image_id;
    cur_im_is_flipped = false;
    img = imread(image_file(cur_im_id));
end
if cur_im_is_flipped~=b.img_flipped
    cur_im_is_flipped=b.img_flipped;
    img = img(:,end:-1:1,:);
end
if use_pb
    pb_img = imread(segs_file(cur_im_id));
    pb_img(pb_img<16384) = 0;
    pb_img(pb_img>=16384) = pb_img(pb_img>=16384) - 16384;
    leaf_labels = uint16(bwlabel(~pb_img));
    if b.img_flipped
        pb_img = pb_img(:,end:-1:1);
        leaf_labels = leaf_labels(:,end:-1:1);
    end
end
    
persistent cur_idx;    
persistent all_mask;
persistent prev_labeledLeaves;
persistent labeled_mask;
persistent seg_border;
persistent prev_selected_leaves;

% Gets the annotation bounds and crops with them
coords2d = b.coords(:,1:2);
annot_bounds = b.get_bounds(PAD, true, true);

display_img = im2double(imcrop(img, annot_bounds));
if use_pb
    pb  = imcrop(pb_img, annot_bounds);
    labels = imcrop(leaf_labels,annot_bounds);
    regions = bwlabel(pb<=threshold)+1;
end
coords2d = coords2d - ones(size(coords2d,1),1)*max(annot_bounds(1:2),0);

if showFlatColors
    [reg_colors,display_img] = get_flat_colors(regions,display_img);
end

if showPbEdges
    display_img(repmat(pb>threshold,[1 1 3]))=0;    % Make Pb boundary black
    im_red=reshape(display_img(:,:,1),[],1);        % Get the red channel
    im_red(pb>threshold)=255;                       % Mark it full
    display_img(:,:,1) = reshape(im_red,size(display_img(:,:,1))); % Put it back
end

% Draw borders along the selected regions
if ~isempty(regionsToShow)    
    parts = b.segment_ids{1};
    
    if isempty(cur_idx) || b.entry_id~=cur_idx
        % clear from the image any region not included for that person
        all_mask = ismember(labels, parts);
        all_mask = imerode(imdilate(all_mask,ones(3)),ones(3));
                
        prev_labeledLeaves=-1;
        seg_border=logical(zeros([size(labels,1),size(labels,2),length(AreaNames)])); %#ok<LOGL>
        prev_selected_leaves=cell(length(AreaNames),1);
        cur_idx = b.entry_id;
    end
    tic;
    % Find the union of parts that have the given label
    
    annot_labels = b.segment_labels{1};

    selected_leaves = cell(length(AreaNames),1);
    labeled_leaves = parts(annot_labels>0);
    for p=1:length(AreaNames)
        selected_leaves{p} = parts(annot_labels==p);
    end
        
    display_img(repmat(~all_mask,[1 1 3])) = 0;


    % Fade out any part of the image that could be labelled but isn't
    if ~isequal(labeled_leaves,prev_labeledLeaves)
        labeled_mask = ismember(labels, labeled_leaves);
        labeled_mask = imerode(imdilate(labeled_mask,ones(3)),ones(3));
        prev_labeledLeaves=labeled_leaves;
    end
    display_img(repmat(~labeled_mask,[1 1 3])) = display_img(repmat(~labeled_mask,[1 1 3]))*0.5;

    for sel=regionsToShow
        if isempty(selected_leaves{sel})
            continue;
        end
        
        if ~isequal(selected_leaves{sel},prev_selected_leaves{sel})
            seg_mask = ismember(labels, selected_leaves{sel});
            seg_mask = double(imerode(imdilate(seg_mask,ones(3)),ones(3)));

            seg_border(:,:,sel)=imdilate(edge(uint16(seg_mask),'roberts','nothinning'),ones(3))>0;
            prev_selected_leaves{sel}=selected_leaves{sel};
        end

        c = sum(sum(seg_border(:,:,sel)));
        display_img(repmat(seg_border(:,:,sel),[1 1 3])) = [SelectionColors(sel,1)*ones(c,1); SelectionColors(sel,2)*ones(c,1); SelectionColors(sel,3)*ones(c,1)];
    end
end

imshow(display_img);
if showSkeleton
    draw_skeleton(coords2d,[],'blue',1,b.visible);
end

end


function draw_skeleton(coords,sigmas,color,linewidth,visible)
global config;
K = config.K(15); % Person category
if ~exist('visible','var')
    visible = true(size(coords,1),1);
end
if ~exist('color','var')
    color='blue';
end
if ~exist('linewidth','var')
   linewidth=3; 
end
hold on;
q=[K.L_Shoulder K.R_Shoulder]; draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.L_Hip K.R_Hip];           draw_segment(coords(q,:),any(visible(q)),color,linewidth);
draw_segment([mean(coords([K.L_Hip K.R_Hip],:)); mean(coords([K.L_Shoulder K.R_Shoulder],:))], any(visible([K.L_Hip K.R_Hip K.L_Shoulder K.R_Shoulder])),color,linewidth);

q=[K.L_Shoulder K.L_Elbow]; draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.L_Elbow K.L_Wrist];    draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.R_Shoulder K.R_Elbow]; draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.R_Elbow K.R_Wrist];    draw_segment(coords(q,:),any(visible(q)),color,linewidth);

q=[K.L_Hip K.L_Knee];       draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.L_Knee K.L_Ankle];     draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.R_Hip K.R_Knee];       draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.R_Knee K.R_Ankle];     draw_segment(coords(q,:),any(visible(q)),color,linewidth);

q=[K.Nose K.R_Eye];     draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.L_Eye K.L_Ear];     draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.Nose K.L_Eye];     draw_segment(coords(q,:),any(visible(q)),color,linewidth);
q=[K.R_Eye K.R_Ear];     draw_segment(coords(q,:),any(visible(q)),color,linewidth);

if exist('sigmas','var') && ~isempty(sigmas)
    for i=1:12
        if ~any(isnan(coords(i,:)))
            if visible(i)
                ec='b';
            else
                ec='g';
            end
            rectangle('Position', [coords(i,:)-sigmas(i,:) sigmas(i,:)*2],'Curvature',[1 1],'EdgeColor',color,'LineWidth',linewidth/2);
        end
    end
end
hold off;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function draw_segment(coords,solid,color,linewidth)
if ~any(isnan(coords(:)))
    if ~solid
        line(coords(:,1),coords(:,2),'Color',color,'LineWidth',linewidth*2,'LineStyle',':');
    else
        line(coords(:,1),coords(:,2),'Color',color,'LineWidth',linewidth*2);
    end
end
end

function [reg_colors,flatcol_image]=get_flat_colors(regions,image)
    NR = max(regions(:));
    reg_colors = zeros(NR,3);
    reg_counts = zeros(NR,1);

    im1d = reshape(image,[],3);
    for i=1:numel(regions)
        idx = regions(i);
        reg_colors(idx,:) = reg_colors(idx,:)+im1d(i,:);
        reg_counts(idx)= reg_counts(idx)+1;
    end
    reg_colors = reg_colors./repmat(reg_counts,[1 3]);
    
    if nargout>1
        flatcol_image = reshape(reg_colors(regions,:),size(image));
    end
end




