function [resampled,falls_outside] = transform_resize_crop(source, image_to_obj_xform, dims, interp, pad)

if nargin<5
    pad = 128;
    if nargin<4 || isempty(interp)
       interp = 'bicubic';
    end
end
if size(image_to_obj_xform,2)==2
    image_to_obj_xform(:,3)= [0;0;1];
end
% Transforms the image and crops out a region of size dims

% -1 because Matlab images are 1-indexed (indexing starts with 1) and 0.5
% moves from the center to the corner of the pixel
image_to_obj_xform = [1 0 0; 0 1 0; -1.5 -1.5 1]*image_to_obj_xform;

% First figure out a bounding box that spans the area of interest
unit_square = [-.5 -.5 1; .5 -.5 1; .5 .5 1; -.5 .5 1; -.5 -.5 1];
unit_square = unit_square.*repmat([dims/min(dims) 1],[5 1]);
rect_coords = unit_square * inv(image_to_obj_xform);
rect_coords(:,3)=[];
[H W CH] =size(source);
falls_outside = any([rect_coords(:)<0; rect_coords(:,1)>W; rect_coords(:,2)>H]);
if falls_outside && isnan(pad) % pad of nan means fold the image if possible
    fringe = round([max([-rect_coords(:,1); rect_coords(:,1)-W]) max([-rect_coords(:,2); rect_coords(:,2)-H])]);
    fringe = min(max(fringe,1)+1, [W H]);
   source = extend_image(source, fringe([2 1]));
   rect_coords = rect_coords + repmat(fringe,5,1);
   pad=128; % even after folding the image may be too small. Fill with gray
end

top_left = min(rect_coords);
crop_with_pad = imcrop_with_padding(source, [top_left max(rect_coords)-top_left], pad);

image_to_obj_xform = [1 0 0; 0 1 0; top_left 1] * ...
                     image_to_obj_xform * ...
                     [min(dims) 0 0; 0 min(dims) 0; 0 0 1] * ...
                     [1 0 0; 0 1 0; dims/2 1];
image_to_obj_xform(:,3) = [0;0;1]; % num. errors make these non-zero & maketform complains
[xformed,xData,yData] = imtransform(crop_with_pad, maketform('affine', image_to_obj_xform), interp);

% Workaround to do imcrop when the number of channels is 2 or >3
if length(size(xformed))==3 && (size(xformed,3)>3 || size(xformed,3)==2)
    if mod(size(xformed,3),3)==0
       for q=size(xformed,3):-3:1
           resampled(:,:,(q-2):q)=imcrop(xData,yData,xformed(:,:,(q-2):q),[0 0 dims-1]);
       end
    else
       for q=size(source,3):-1:1
            resampled(:,:,q)=imcrop(xData,yData,xformed(:,:,q),[0 0 dims-1]);
       end
    end
else
    resampled=imcrop(xData,yData,xformed,[0 0 dims-1]);
end
if (size(resampled,1)~=dims(2) || size(resampled,2)~=dims(1))
    if ~isempty(resampled)
        resampled = imresize(resampled, [dims(2) dims(1)],interp);
    else
        resampled = repmat(pad,[dims(2) dims(1) size(source,3)]);
    end
%    disp('Double resizing');
end

end

function im1 = extend_image(img, hdim)
    wh = size(img);
    im1(hdim(1) + (1:wh(1)), hdim(2) + (1:wh(2)),:) = img;

    im1(1:hdim(1),:,:) = im1(hdim(1)+(hdim(1):-1:1),:,:);
    im1(hdim(1)+wh(1)+(1:hdim(1)),:,:) = im1(hdim(1)+wh(1)-(1:hdim(1)),:,:);

    im1(:,1:hdim(2),:) = im1(:,hdim(2)+(hdim(2):-1:1),:);
    im1(:,hdim(2)+wh(2)+(1:hdim(2)),:) = im1(:,hdim(2)+wh(2)-(1:hdim(2)),:);
end
