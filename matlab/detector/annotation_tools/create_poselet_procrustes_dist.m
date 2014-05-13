function   [part,examples_info] = create_poselet_procrustes_dist(unit_dims, src_annot, src_patch, a, disable_rotation)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Creates a poselet given a seed patch. Similarity is computed as a linear 
%%% combination of the procrustes distance between the keypoints in common and 
%%% an 'aspect distance', which is intersection over union of the common keypoints.
%%%
%%% PARAMETERS:
%%%   unit_dims -- normalized dimensions of the poselet [width height]
%%%   src_patch -- location of the seed patch in the seed annotation [x_min y_min width height rotation] 
%%%                The seed patch is 0-indexed, i.e. the first image pixel is (0,0) not (1,1)
%%%   src_annot -- the seed annotation (of type 'annotation')
%%%   a         -- the annotations to draw training examples from (of type 'annotation')
%%%   disable_rotation -- when present and true, 
%%%
%%% RETURNS:
%%%   part      -- the constructed poselet
%%%   examples_info -- the scale, rotation of each example and whether it is fully inside the image. Can be used to prune the examples.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global im;
global config;


warning('off','MATLAB:lscov:RankDefDesignMat');

if ~exist('disable_rotation','var')
    disable_rotation=false;
end

examples_info.out_of_image=[];
examples_info.scale=[];
examples_info.rot=[];

% don't allow matches whose view is opposite of that of the seed. 
% pose = 0=unspecified, 1=left, 2=right, 3=front, 4=back
opposite_viewpoints = [nan 2 1 4 3];
disallowed_viewpoint = opposite_viewpoints(src_annot.pose(1)+1);

src_coords = src_annot.coords;
src_dims = src_patch(3:4);
src_angle = src_patch(5);
src_scale = mean(src_dims);

part = poselet(src_annot.entry_id, [src_patch(1:2)-src_dims/2 src_dims], unit_dims);


unit2src_xform = [ src_scale*cos(src_angle) src_scale*sin(src_angle) 0         0
                  -src_scale*sin(src_angle) src_scale*cos(src_angle) 0         0
                   0                        0                        src_scale 0
                   src_patch(1)             src_patch(2)             0         1];
src2unit_xform = inv(unit2src_xform);              
               
unit_square = [-.5 -.5 1; .5 -.5 1; .5 .5 1; -.5 .5 1];
unit_square = unit_square.*repmat([src_dims/min(src_dims) 1],[4 1]);

% Transform the source coords to unit space and select the ones that are
% close. We ignore far away keypoints in computing the fit.
% Unit space is centered at the patch and is scaled so that the shortest
% patch dimenison goes from -0.5 to 0.5
unit_src_coords = [src_coords ones(size(src_coords,1),1)]* src2unit_xform;    

src_kp_inside = get_kp_inside(unit_src_coords,src_dims,1);
valid_src_keypts = ~isnan(src_coords(:,1)) & src_kp_inside;
visible_valid_srckeypts = valid_src_keypts & src_annot.visible;

if sum(valid_src_keypts)<2 || ~any(visible_valid_srckeypts) % the source has less than two keypoints
    return;
end

dst2unit_xforms = zeros([3 2 0]);
errs = [];
selected = [];
for dst_i = 1:a.size
    if ~isnan(disallowed_viewpoint) && a.pose(dst_i)==disallowed_viewpoint
        continue; % matches of opposite views are disallowed
    end
    
    dst_coords = a.coords(:,:,dst_i);
    dst_kp_exists = ~isnan(dst_coords(:,1));
    dst_coords(~dst_kp_exists,:) = 0;
    
    shared_keypoints = valid_src_keypts & dst_kp_exists;
    N = sum(shared_keypoints);
    if N<2 && disable_rotation
        % Try to recover if disable_rotation is true. Use a twice as large a context
       shared_keypoints = ~isnan(src_coords(:,1)) & get_kp_inside(unit_src_coords,src_dims,2) & dst_kp_exists;
        N = sum(shared_keypoints);
    end

    if N<2
       continue;   % This sample has less than two keypoints shared with the source
    end

    % Least squares Ax = b
    A = [unit_src_coords(shared_keypoints,1) -unit_src_coords(shared_keypoints,2) ones(N,1) zeros(N,1); ...
         unit_src_coords(shared_keypoints,2)  unit_src_coords(shared_keypoints,1) zeros(N,1) ones(N,1)];
    b = [dst_coords(shared_keypoints,1); dst_coords(shared_keypoints,2)];

    x = lscov(A,b);    
%    x = pinv(A'*A)*A'*b;
    scale_sqrd = x(1)*x(1)+x(2)*x(2);
    
    if disable_rotation
        x(1)=sqrt(scale_sqrd);
        x(2) = 0;
    end

    unit2dst_xform = [x(1) x(2) 0; -x(2) x(1) 0; x(3) x(4) 1];
    dst2unit_xform = inv(unit2dst_xform);
    if any(isinf(dst2unit_xform(:)))
       continue;    % failed to find the similarity transform
    end
    
    rot = asin(x(2)/sqrt(scale_sqrd));
    if x(1)<0
        if rot>0
            rot = pi-rot;
        else
            rot = -pi-rot;
        end
    end
    examples_info.rot(end+1)   = rot;
    examples_info.scale(end+1) = sqrt(sum(dst2unit_xform(1,1:2).^2));
                
    rect_coords = unit_square * unit2dst_xform;
    rect_coords(:,3)=[];
    img_dims = im.dims(a.image_id(dst_i),:);
    examples_info.out_of_image(end+1)=any([rect_coords(:)<=0; rect_coords(:,1)>img_dims(1); rect_coords(:,2)>img_dims(2)]);

    % Compute the residual error
    unit_dst_coords = [dst_coords(:,1:2) ones(size(dst_coords,1),1)]*dst2unit_xform;    
    proc_dist = mean((unit_dst_coords(shared_keypoints) - unit_src_coords(shared_keypoints)).^2);
    
    dst_kp_inside = get_kp_inside(unit_dst_coords,src_dims,1);
    valid_dst_keypts = dst_kp_exists & dst_kp_inside;
    visible_valid_dstkeypts = valid_dst_keypts & a.visible(:,dst_i);    
    vis_dist = sum(bitxor(visible_valid_srckeypts,visible_valid_dstkeypts)) / sum(visible_valid_srckeypts | visible_valid_dstkeypts);
    
    errs(end+1) = proc_dist + config.VISUAL_DIST_WEIGHT*vis_dist;
        
    dst2unit_xforms(:,:,end+1) = dst2unit_xform(:,1:2);
    selected(end+1)=dst_i;
end

[errs,srtd] = sort(errs);
part.img2unit_xforms = dst2unit_xforms(:,:,srtd);
part.errs(:,1) = errs;
part.dst_entry_ids = a.entry_id(selected(srtd));
 
examples_info.out_of_image=examples_info.out_of_image(srtd);
examples_info.scale=examples_info.scale(srtd);
examples_info.rot=examples_info.rot(srtd);

end

function kp_inside=get_kp_inside(unit_coords, src_dims, scale)
    unit_dims = src_dims/min(src_dims)*scale;
    kp_inside = unit_coords(:,1)>=-unit_dims(1)/2 & unit_coords(:,1)<=unit_dims(1)/2 & unit_coords(:,2)>=-unit_dims(2)/2 & unit_coords(:,2)<=unit_dims(2)/2;
end



