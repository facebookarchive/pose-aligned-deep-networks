function cropped = imcrop_with_padding(source, rect, pad_value)
% imcrop that allows the crop rectangle to be partically/fully outside the
% source image. Copies only the valid pixels from the source and fills the
% rest with a given pad value

if nargin<3
    pad_value=0;
end

[H W D] = size(source);
rect(3:4) = rect(3:4)+rect(1:2);
rect = round(rect);
rect(3:4) = rect(3:4)-rect(1:2);

if rect(1)>0 && rect(2)>0 && rect(1)+rect(3)<=W && rect(2)+rect(4)<=H
   %cropped = imcrop(source,[rect(1:2)-0.5 rect(3:4)]);
   cropped = source(rect(2):(rect(2)+rect(4)),rect(1):(rect(1)+rect(3)),:);
else
    if islogical(source)
        cropped = logical(ones([rect(4)+1,rect(3)+1,D])*pad_value);
    else
        cropped = ones([rect(4)+1,rect(3)+1,D],class(source))*pad_value;
    end
   xspan = rect(1):(rect(1)+rect(3));
   yspan = rect(2):(rect(2)+rect(4));
   valid_xspan = xspan>0 & xspan<=W;
   valid_yspan = yspan>0 & yspan<=H;
   cropped(valid_yspan,valid_xspan,:) = source(yspan(valid_yspan),xspan(valid_xspan),:);
end