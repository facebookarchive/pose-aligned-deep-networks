function phog=image2phog(img, config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Given an RGB uint8 image returns the pyramid HOG features
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Scale the image and add a margin
%%%%%%%%%%%%%%%%%%%%%%%%%%
img=double(img);
[H,W,D] = size(img);
phog.img_scale = 1;
s = get_image_detection_scale([W H], config);

phog.hog = {};

CONTEXT_DIMS=[96 64];

phog.img_width=W;
min_scale = max(CONTEXT_DIMS./[H W]);
img = double(img);
num_scales = 0;

while true
    if config.DEBUG>1
        disp(sprintf('Scale: %f', s));
    end

    wh = floor([H W]*s);
    im1 = zeros([wh + CONTEXT_DIMS D]);
    hdim = CONTEXT_DIMS/2;

    if s==1
        im1(hdim(1) + (1:wh(1)), hdim(2) + (1:wh(2)),:) = img;
    else
        im1(hdim(1) + (1:wh(1)), hdim(2) + (1:wh(2)),:) = mex_imresize(img, wh(1), wh(2));
    end

    im1(1:hdim(1),hdim(2)+(1:wh(2)),:) = im1(hdim(1)+(hdim(1):-1:1),hdim(2)+(1:wh(2)),:);
    im1(hdim(1)+wh(1)+(1:hdim(1)),hdim(2)+(1:wh(2)),:) = im1(hdim(1)+wh(1)-(0:(hdim(1)-1)),hdim(2)+(1:wh(2)),:);

    im1(:,1:hdim(2),:) = im1(:,hdim(2)+(hdim(2):-1:1),:);
    im1(:,hdim(2)+wh(2)+(1:hdim(2)),:) = im1(:,hdim(2)+wh(2)-(0:(hdim(2)-1)),:);

    [hog,samples_x,samples_y] = compute_hog(im1,config);
    if isempty(hog)
        break;
    end

    phog.hog{end+1}=bind_hog(hog,samples_x-hdim(2),samples_y-hdim(1),s,[0 0]);

    s = s / config.PYRAMID_SCALE_RATIO;
    if s<min_scale
       break;
    end

    num_scales = num_scales+1;
end
end

function ph=bind_hog(hog,samples_x,samples_y,scale,img_top_left)
    ph.hog=hog;
    ph.samples_x=samples_x;
    ph.samples_y=samples_y;
    ph.scale=scale;
    ph.img_top_left=img_top_left;
end



