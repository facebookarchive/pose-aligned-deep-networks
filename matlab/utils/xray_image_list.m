%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
classdef xray_image_list
    properties
        image_id;   % Nx1 array of uint64. The FBID of each image (or other uniqueid)
        version;    % Nx1 array of int
        scores;     % KxN array of float. Scores for various categories
        size;       % uint32 size
    end
    methods
        function h = xray_image_list(image_id,scores,version)
            h.size=0;
            h.scores=zeros(10,0,'single');
            h.image_id=zeros(0,1,'uint64');
            h.version=zeros(0,1,'int32');
            if nargin>0
                h.size=length(image_id);
                h.scores(:,1:h.size)=single(scores);
                h.image_id(1:h.size,1)=uint64(image_id);
                h.version(1:h.size,1)=int32(version);
            end

        end

        function is = isempty(h)
           is=(h.size==0);
        end

        function h = sortby(h,idx,mod)
            if nargin==2
               mod='ascend';
            end
            [srt,srtd] = sort(h.scores(idx,:),mod);
            h = h.select(srtd);
        end

        %%% Appends hits h2 at the end of hits h
        function h = append(h,h2)
            if isempty(h2)
                return;
            end
            rng = 1:h2.size;
            h.scores(:,h.size+rng)   = h2.scores(:,rng);
            h.image_id(h.size+rng,:) = h2.image_id(rng);
            h.version(h.size+rng,:) = h2.version(rng);
            h.size = h.size + h2.size;
        end

        function h = reserve(h,len)
            diff = len - h.size;
            if diff>0
               h.scores(:,end+(1:diff)) = nan;
               h.image_id(end+(1:diff),1) = 0;
               h.verson(end+(1:diff),1) = 0;
            end
        end

        %%% Returns a subset of the input hits
        function h = select(h,sel)
            if isempty(sel)
                h = xray_image_list;
                return;
            end
            h.scores = h.scores(:,sel);
            h.image_id = h.image_id(sel,1);
            h.version = h.version(sel,1);
            h.size = length(h.image_id);
        end
    end
end
