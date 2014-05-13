%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
classdef hit_list
    properties
        bounds;     % Nx4 array of single. [min_x min_y width height]
        poselet_id; % Nx1 array of uint16. Unique ID of the detected poselet
        score;      % Nx1 array of single. Score of the SVM classifier
        image_id;   % Nx1 array of uint64. The FBID of each image (or other uniqueid)
        cluster_id; % Nx1 array of uint16. The index of the hyp cluster within the image
        size;       % uint32 size
    end
    methods
        function h = hit_list(bounds,score,poselet_id,image_id,cluster_id)
            h.size=0;
            h.bounds=zeros(4,0,'single');
            h.poselet_id=zeros(0,1,'uint16');
            h.score=zeros(0,1,'single');
            h.image_id=zeros(0,1,'uint64');
            h.cluster_id=zeros(0,1,'uint16');
            if nargin>0
                assert(size(bounds,1)==4);
                h.size=size(bounds,2);
                h.bounds=single(bounds);
                h.score(1:h.size,1)=single(score);
                h.poselet_id(1:h.size,1)=uint16(poselet_id);
                h.image_id(1:h.size,1)=uint64(image_id);
                h.cluster_id(1:h.size,1)=uint16(cluster_id);
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
            h.poselet_id(h.size+rng,:)  = h2.poselet_id(rng);
            h.cluster_id(h.size+rng,:)  = h2.cluster_id(rng);
            h.size=h.size+h2.size;
        end
                
        function h=reserve(h,len)
            diff = len-length(h.score);
            if diff>0
               h.bounds(1:4,end+(1:diff)) = nan;
               h.score(end+(1:diff),1)=nan;
               h.image_id(end+(1:diff),1)=0;
               h.poselet_id(end+(1:diff),1)=0;
               h.cluster_id(end+(1:diff),1)=0;
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
            h.poselet_id = h.poselet_id(sel,1);
            h.cluster_id = h.cluster_id(sel,1);
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