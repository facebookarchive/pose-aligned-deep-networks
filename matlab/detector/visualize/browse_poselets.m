function browse_poselets(a,poselets, fn, possible_truths)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Visualizes poselets. Allows browsing the examples of each poselet and
%%% their source images
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MAX_THUMBS = 150; % How many examples to show in one screen

if ~exist('figures','var')
   figures=[9 10 11]; 
end

if ~exist('fn','var')
   fn=@browse_poselet_examples;
end

disp('press ''?'' for instructions');
N = length(poselets);

cur_idx = 1;
idx_changed=true;
while 1
    if idx_changed
        closeall(figures(1:2));
        cur_span = cur_idx:min(cur_idx+MAX_THUMBS-1,N);
        cur_poselets = poselets(cur_span);
        thumbs = combine_patches_of_different_sizes(extract_patches_of_poselets(a,set_max_examples(cur_poselets,1)));
        idx_changed=false;
    end
    
    figure(figures(1));
    [h,dims]=display_patches(thumbs, num2str(cur_span'), [ceil(MAX_THUMBS/15) 15]);
    title(sprintf('poselet %d - %d of %d',cur_span(1),cur_span(end),N));
    [idx,ch] = get_grid_selection([size(thumbs,2) size(thumbs,1)],dims,length(cur_span));

    switch ch
        case 27 % ESC
            closeall(figures);
            return;
        case '`'
            return;
        case 29 % ->
            if cur_span(end)<N
                cur_idx=cur_idx+MAX_THUMBS;
                idx_changed=true;
            end
        case 28 % <-
            if cur_span(1)>1
                cur_idx=cur_idx-MAX_THUMBS;
                idx_changed=true;
            end
        case 'g'
            answer = str2double(inputdlg('Enter poselet index:'));
            if ~isempty(answer)
                answer = round(answer);
                if answer>0
                    cur_idx=max(1,min(N,answer));
                    idx_changed=true;
                end
            end   
        otherwise
            if ~isnan(idx)
                if exist('possible_truths','var')
                    fn(a, cur_idx+idx-1, cur_poselets(idx), figures(2:3), ch, possible_truths(idx));
                else
                    fn(a, cur_idx+idx-1, cur_poselets(idx), figures(2:3), ch);                    
                end
            end            
    end
end
end

    
function browse_poselet_examples(a, poselet_id, poselet, figures, fig_title, all_annots)
MAX_THUMBS = 60;

if ~exist('figures','var') || isempty(figures)
   figures=[3 10]; 
end

if ~exist('fig_title','var') || isempty(fig_title)
   fig_title='';
end

cur_idx = 1;
refresh=true;
while 1
    if refresh
        closeall(figures(1:2));

        cur_hit_span = cur_idx:min(cur_idx+MAX_THUMBS-1,poselet.size);
        examples = poselet.select(cur_hit_span);
        thumbs = extract_patches_of_poselets(a,examples);
        thumbs=thumbs{1};
        figure(figures(1));
        if exist('all_annots','var')
            [h,dims]=display_patches(thumbs,all_annots(cur_hit_span,:));        
        else
            [h,dims]=display_patches(thumbs);
        end
        title(sprintf('%s poselet %d  example %d - %d of %d',fig_title,poselet_id,cur_hit_span(1),cur_hit_span(end),poselet.size));
        refresh=false;
    end
    [idx,ch] = get_grid_selection([size(thumbs,2) size(thumbs,1)],dims,MAX_THUMBS);

    switch ch
        case 27 % ESC
            closeall(figures);
            return;
        case '`' % ESC
            return;
        case 29 % ->
            if cur_hit_span(end)<poselet.size
                cur_idx=cur_idx+MAX_THUMBS;
                refresh=true;
            end
        case 28 % <-
            if cur_hit_span(1)>1
                cur_idx=cur_idx-MAX_THUMBS;
                refresh=true;
            end
        case 'g'
            answer = str2double(inputdlg('Enter poselet example index:'));
            if ~isempty(answer)
                answer = round(answer);
                if answer>0
                    cur_idx=max(1,min(poselet.size,answer));
                    refresh=true;
                end
            end            
        otherwise
            if ~isnan(idx)
                figure(figures(2));
                img = imread(image_file(a.image_id(examples.dst_entry_ids(idx))));
                if a.img_flipped(examples.dst_entry_ids(idx))
                    img=img(:,end:-1:1,:);
                end
                imshow(img);
                [bounds,rot]=poselet_example_bounds(examples.img2unit_xforms(:,:,idx),examples.dims);

                pts = double(get_rot_corners(bounds,rot*180/pi));
                line(pts(:,1),pts(:,2),'color','r');

        %                hits.select(idx).draw_bounds;
                title(sprintf('image id: %d  annot id: %d rank: %d',a.image_id(examples.dst_entry_ids(idx)),examples.dst_entry_ids(idx),cur_hit_span(idx)));
                figure(figures(1));
            end
    end
end
end

function [bounds,rot]=poselet_example_bounds(img2obj_xform,dims)
    img2obj_xform(:,3)=[0;0;1];
    
    scale = norm(img2obj_xform(1:2,1));
    rot = asin(img2obj_xform(2,1)/scale);
    image_to_obj_xform = [1 0 0; 0 1 0; -1.5 -1.5 1]*img2obj_xform*...
        [cos(-rot) -sin(-rot) 0; sin(-rot) cos(-rot) 0; 0 0 1];% * [0.25 0 0; 0 0.25 0; 0 0 1];

    % First figure out a bounding box that spans the area of interest
    unit_square = [-.5 -.5 1; .5 -.5 1; .5 .5 1; -.5 .5 1; -.5 -.5 1];
    unit_square = unit_square.*repmat([dims([2 1])/min(dims) 1],[5 1]);
    rect_coords = unit_square * inv(image_to_obj_xform);
    rect_coords(:,3)=[];

    min_pt = min(rect_coords);
    max_pt = max(rect_coords);
    bounds=[min_pt max_pt-min_pt];
end

function pts=get_rot_corners(bounds, angle)
    % returns a list of points that would be needed to draw the outline of 
    % a rotated rectangle

    ctr = bounds(1:2)+bounds(3:4)/2;

    p1 = bounds(1:2);
    p2 = p1 + bounds(3:4);
    rad = angle*pi/180;

    pts = [p1          1
           p2(1) p1(2) 1
           p2          1
           p1(1) p2(2) 1
           p1          1];

    xform = [1 0 0; 0 1 0; -ctr 1] * ...
            [cos(rad) sin(rad) 0; -sin(rad) cos(rad) 0; 0 0 1] * ...
            [1 0 0; 0 1 0;  ctr 1];

    pts = pts*xform;
    pts = pts(:,1:2);
end

function closeall(figures)
    close(figures(ishandle(figures)));
end

function poselets=set_max_examples(poselets,N)
    for i=1:length(poselets)
        if poselets(i).size>N
           poselets(i)=poselets(i).select(1:N); 
        end
    end
end


