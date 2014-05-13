function [idx,ch]=get_grid_selection(thumb_dims, dims, num_elements)
while 1
    [x,y,ch] = ginput(1);
    y = floor(y/thumb_dims(2));
    x = floor(x/thumb_dims(1));
    idx = y*dims(1) + x+1;
    if (idx<1 || idx>num_elements)
        idx=nan;
    end
    if isscalar(ch)
        return;
    end
end
