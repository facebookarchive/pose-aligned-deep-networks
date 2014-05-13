%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
classdef face_list
    properties
        bounds;     % Nx4 array of single. [min_x min_y width height]
        facebox_id; % Nx1 array of uint64. FBID of the facebox
        score;      % Nx1 array of single. Face confidence
        image_id;   % Nx1 array of uint64. The FBID of each image (or other uniqueid)
        subject_id; % Nx1 array of uint64. FBID of the subject
        smiling;    % Nx1 array of single. smile score.
        glasses;    % Nx1 array of single. glasses score.
        gender;     % Nx1 array of single. gender score.
        size;       % uint32 size
    end
    methods
        function h = face_list(bounds,score,facebox_id,image_id,subject_id,smiling,glasses,gender)
            h.size=0;
            h.bounds=zeros(4,0,'single');
            h.facebox_id=zeros(0,1,'uint64');
            h.score=zeros(0,1,'single');
            h.image_id=zeros(0,1,'uint64');
            h.subject_id=zeros(0,1,'uint64');
            h.smiling=zeros(0,1,'single');
            h.glasses=zeros(0,1,'single');
            h.gender=zeros(0,1,'single');
            if nargin>0
                assert(size(bounds,1)==4);
                h.size=size(bounds,2);
                h.bounds=single(bounds);
                h.score(1:h.size,1)=single(score);
                h.facebox_id(1:h.size,1)=uint64(facebox_id);
                h.image_id(1:h.size,1)=uint64(image_id);
                h.subject_id(1:h.size,1)=uint64(subject_id);
                h.smiling(1:h.size,1)=single(smiling);
                h.glasses(1:h.size,1)=single(glasses);
                h.gender(1:h.size,1)=single(gender);
            end            
        end
        
        function is=isempty(h)
           is=(h.size==0); 
        end

        %%% Appends hits h2 at the end of hits h
        function h=append(h,h2)
            if isempty(h2)
                return;
            end
            rng=1:h2.size;
            h.bounds(:,h.size+rng)      = h2.bounds(:,rng);
            h.score(h.size+rng,:)       = h2.score(rng);
            h.image_id(h.size+rng,:)    = h2.image_id(rng);
            h.facebox_id(h.size+rng,:)  = h2.facebox_id(rng);
            h.subject_id(h.size+rng,:)  = h2.subject_id(rng);
            h.smiling(h.size+rng,:)     = h2.smiling(rng);
            h.glasses(h.size+rng,:)     = h2.glasses(rng);
            h.gender(h.size+rng,:)      = h2.gender(rng);
            h.size=h.size+h2.size;
        end
                
        function h=reserve(h,len)
            diff = len-length(h.score);
            if diff>0
               h.bounds(1:4,end+(1:diff)) = nan;
               h.score(end+(1:diff),1)=nan;
               h.image_id(end+(1:diff),1)=0;
               h.facebox_id(end+(1:diff),1)=0;
               h.subject_id(end+(1:diff),1)=0;
               h.smiling(end+(1:diff),1)=nan;
               h.glasses(end+(1:diff),1)=nan;
               h.gender(end+(1:diff),1)=nan;
            end
        end

        %%% Returns a subset of the input hits
        function h=select(h,sel)
            if isempty(sel)
                h=hit_list;
                return;
            end
            h.bounds = h.bounds(:,sel);
            h.score = h.score(sel,1);
            h.image_id = h.image_id(sel,1);
            h.facebox_id = h.facebox_id(sel,1);
            h.subject_id = h.subject_id(sel,1);
            h.smiling = h.smiling(sel,1);
            h.glasses = h.glasses(sel,1);
            h.gender = h.gender(sel,1);
            h.size=length(h.score);
        end
        
        %%% Draws the rotated bounding box of a hit
        function draw_bounds(h,color,linewidth,linestyle,textbg,textfg)
            if ~exist('color','var')
                color='g';
            end
            if ~exist('linewidth','var')
               linewidth=4; 
            end
            if ~exist('linestyle','var')
               linestyle='-'; 
            end

            for i=1:h.size
                rectangle('position',h.bounds(:,i),'edgecolor',color,'linewidth',linewidth,'linestyle',linestyle);
                if exist('textbg','var')
                    if ~exist('textfg','var')
                       textfg = [1 1 1];           
                    end
                    text(double(h.bounds(1,i)),double(h.bounds(2,i)),num2str(h.score(i),'%4.2f'),'BackgroundColor',textbg,'Color',textfg);
                end
            end            
        end        
    end
end