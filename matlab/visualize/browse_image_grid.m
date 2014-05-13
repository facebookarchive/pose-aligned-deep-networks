%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function browse_image_grid(all_image_ids, all_labels)

if isequal(class(all_image_ids), 'xray_image_list')
   all_image_ids = all_image_ids.image_id;
end
N = length(all_image_ids);
NUM2DISPLAY = 64;
SCALE = 0.5;
cur_idx = 1;
refresh=true;
while 1
    if refresh
        image_ids=all_image_ids(cur_idx:min(N,cur_idx+NUM2DISPLAY-1));
        if exist('all_labels','var')
            labels = all_labels(cur_idx:min(N,cur_idx+NUM2DISPLAY-1),:);
            [~,dims,patch_dims] = display_image_grid(image_ids, SCALE, labels);
        else
            [~,dims,patch_dims] = display_image_grid(image_ids, SCALE);            
        end
        title(sprintf('%d-%d of %d',cur_idx,min(N,cur_idx+NUM2DISPLAY-1), N));
        refresh=false;
    end
    [idx,ch] = get_grid_selection(patch_dims,dims,NUM2DISPLAY);

    switch ch
        case 27 % ESC
            close(gcf);
            return;
        case 29 % ->
            if cur_idx+NUM2DISPLAY<=N
                cur_idx=cur_idx+NUM2DISPLAY;
                refresh=true;
            end
        case 28 % <-
            if cur_idx-NUM2DISPLAY>0
                cur_idx=cur_idx-NUM2DISPLAY;
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
        otherwise
            if ch<=3
                if ~isnan(idx)
                    cf=gcf;
                    figure(3); clf;
                    imshow(load_image(image_ids(idx)));
                    figure(cf);
                end
            else
               return; 
            end            
    end
end % while 1

end



