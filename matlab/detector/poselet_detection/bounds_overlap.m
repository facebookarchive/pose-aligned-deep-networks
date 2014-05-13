%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Returns intersection over union between the single bounds and each of many_bounds
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function int_over_union = bounds_overlap(bounds, many_bounds)
    int_over_union = zeros(size(many_bounds,2),1,'single');
    
    x0 = max(bounds(1),many_bounds(1,:));
    x1 = min(bounds(3)+bounds(1),many_bounds(3,:)+many_bounds(1,:));
    sel_x = find(x1>x0);

    y0 = max(bounds(2),many_bounds(2,sel_x));
    y1 = min(bounds(4)+bounds(2),many_bounds(4,sel_x)+many_bounds(2,sel_x));    
    sel_y = y1>y0;
    
    sel = sel_x(sel_y);
    if ~isempty(sel)
        int_area = (x1(sel)-x0(sel)) .* (y1(sel_y)-y0(sel_y));
        int_over_union(sel) = int_area ./ (many_bounds(3,sel).*many_bounds(4,sel) - int_area +  bounds(3)*bounds(4));
    end
end