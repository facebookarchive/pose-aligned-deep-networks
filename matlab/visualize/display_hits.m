%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function dims=display_hits(hits, max_thumbs, sort_by_score, thumb_dims)

dims=[0 0];

if hits.isempty
   return; 
end
if ~exist('max_thumbs','var') || isempty(max_thumbs)
    max_thumbs=hits.size;
else
    max_thumbs = min(max_thumbs,hits.size);
end
if ~exist('sort_by_score','var')
    sort_by_score=true;
end
if ~exist('thumb_dims','var')
    ar = mean(hits.bounds(3,1:max_thumbs)./hits.bounds(4,1:max_thumbs));
    thumb_dims = round(100*[1 1/ar]);
end

if sort_by_score
    [srt,srtd] = sort(hits.score,'descend');
else
   srtd=1:length(hits.score); 
   srt=hits.score;
end
srtd((max_thumbs+1):end) = [];
srt((max_thumbs+1):end) = [];
%[h,dims]=display_patches(hits2patches(hits.select(srtd), thumb_dims,'nearest',im), num2str(srt,'%4.2f'));
%[h,dims]=display_patches(hits2patches(hits.select(srtd), thumb_dims,'bicubic'), num2str(srt,'%4.2f'));
%[h,dims]=display_patches(hits2patches(hits.select(srtd), thumb_dims,'bicubic'), num2str((1:length(srt))'));
[h,dims]=display_patches(hits2patches(hits.select(srtd), thumb_dims,'bicubic'),[],[2 12]);
