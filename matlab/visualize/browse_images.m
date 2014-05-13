%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function browse_images(image_ids)

N = length(image_ids);
cur_idx = 1;
refresh=true;
while 1
    if refresh
        display_image_and_hits(image_ids(cur_idx));
        refresh=false;
    end
    [x,y,ch] = ginput(1);

    switch ch
        case 27 % ESC
            return;
        case 29 % ->
            if cur_idx<N
                cur_idx=cur_idx+1;
                refresh=true;
            end
        case 28 % <-
            if cur_idx>1
                cur_idx=cur_idx-1;
                refresh=true;
            end
        case 'g'
            answer = str2double(inputdlg('Enter index:'));
            if ~isempty(answer)
                answer = round(answer);
                if answer>0
                    cur_idx=max(1,min(N,answer));
                    refresh=true;
                end
            end
    end
end % while 1

end



