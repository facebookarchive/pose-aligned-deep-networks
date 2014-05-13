function ch=browse_hit_patches(all_hits,visualize_hit_fn,params)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Displays the hits in all_hits in a grid sorted by score and allows
%%% browsing
%%% 
%%% PARAMETERS:
%%%    all_hits:     A hit_list of hits, such as the predicted bounds or
%%%                  poselet activations
%%%
%%% OPTIONAL PARAMETERS:
%%%    visualize_hit_fn: 
%%%                  Function to call when zooming on a hit
%%%
%%%    params:       Extra parameters, such as the list of detected
%%%                  poselets, torsos (for the person category), poselet
%%%                  masks and example poselets to help visualization. See
%%%                  demo_poselets.m for more.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figuredims_file = 'figuredims.mat';
if exist(figuredims_file,'file')
   load(figuredims_file);
else
    figuredims.f1 = [4 714 522 412];
    figuredims.f3 = [4 714 522 412];
   save(figuredims_file,'figuredims');
end
figure(1);


if ~exist('params','var')
   params=[]; 
end
if ~isfield(params,'dims')
    MAX_THUMB_SIZE=200;
    params.dims = double(round(all_hits.bounds(3:4,1) * MAX_THUMB_SIZE/max(all_hits.bounds(3:4,1)))');
end

if ~exist('visualize_hit_fn','var') || isempty(visualize_hit_fn)
   visualize_hit_fn = @default_visualize_hit_fn;
end

if ~isfield(params,'max_thumbs')
    MAX_THUMBS = 100;
else
    MAX_THUMBS = params.max_thumbs; 
end
if isfield(params,'sorted') && params.sorted
    [~,srtd]=sort(all_hits.score,'descend');
else
   srtd=1:all_hits.size; 
end
cur_idx = 1;
refresh=true;
while 1
    if refresh
        cur_hit_span = srtd(cur_idx:min(cur_idx+MAX_THUMBS-1,all_hits.size));
        patches = hits2patches(all_hits.select(cur_hit_span),params.dims,'bilinear');
        if isfield(params,'labels') && ~all(params.labels==0)
            patches=frame_patches(patches,params.labels(cur_hit_span));
        end
        if isfield(params,'show_score') && params.show_score
            [h,dims]=display_patches(patches,num2str(all_hits.score(cur_hit_span),'%4.2f'));
        else
            [h,dims]=display_patches(patches);
        end
        set(1, 'position', figuredims.f1);

        title(sprintf('hits %d - %d of %d',cur_idx,min(cur_idx+MAX_THUMBS-1,all_hits.size),all_hits.size));
        refresh=false;
    end
    [idx,ch] = get_grid_selection([size(patches,2) size(patches,1)],dims,MAX_THUMBS);

    switch ch
        case 27 % ESC
            return;
        case 29 % ->
            if cur_hit_span(end)<all_hits.size
                cur_idx=cur_idx+MAX_THUMBS;
                refresh=true;
            end
        case 28 % <-
            if cur_hit_span(1)>1
                cur_idx=cur_idx-MAX_THUMBS;
                refresh=true;
            end
        case 'g'
            answer = str2double(inputdlg('Enter hit index:'));
            if ~isempty(answer)
                answer = round(answer);
                if answer>0
                    cur_idx=max(1,min(all_hits.size,answer));
                    refresh=true;
                end
            end  
        case 'r'
            figuredims.f1=get(1,'position');
            figuredims.f3=get(3,'position');
            save(figuredims_file,'figuredims');
        otherwise
            if ch<=3
                if ~isnan(idx)
                    image_idx = all_hits.image_id(cur_hit_span(idx));
                    cf=gcf;
                    figure(3); clf;

                    visualize_hit_fn(image_idx,all_hits.select(cur_hit_span(idx)),params);
                    set(3, 'position', figuredims.f3);
                    figure(cf);
                end
            else
               return; 
            end
    end
end % while 1

end

function patches=frame_patches(patches,labels)
    % Put a green frame over true positives and a red frame over false positives
    FRAME=6;
%        patches = uint8(repmat(mean(patches,4),[1 1 1 3]));
    for i=1:size(patches,4)
        if labels(i)<0;
            color=[255 0 0];
        elseif labels(i)==0
            color=[0 0 255];
        else
            color=[0 255 0];
        end
        for c=1:length(color)
            patches([(2:FRAME) (end-(1:(FRAME-2)))],:,c,i)=color(c);
            patches(:,[(2:FRAME) (end-(1:(FRAME-2)))],c,i)=color(c);
        end
    end    
end

function default_visualize_hit_fn(image_idx,hits,params)
   img=load_image(image_idx,params.config);
   imshow(img);
   hits.draw_bounds;
   set(title(sprintf('img_id: %d',image_idx)),'interpreter','none');
end
