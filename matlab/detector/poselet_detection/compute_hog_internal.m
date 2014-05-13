%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% This method computes the feature vector at a fixed grid on a given
%%% image. The features are HOG as described by the paper:
%%%    N.Dalal, B.Triggs, Histograms of Oriented Gradients for Human
%%%    Detection, CVPR 2005
%%% Author: Lubomir Bourdev
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hog,samples_x,samples_y]=compute_hog_internal(img, config)

if config.USE_MEX_HOG
   [hog,samples_x,samples_y]=compute_hog_mex(single(img));
   return;
end

% Computes HOG for the image
[H W num_channels] = size(img);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: Compute oriented gradients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assert(W>=config.HOG_CELL_DIMS(1)+2 && H>=config.HOG_CELL_DIMS(2)+2);
im1 = sqrt(single(img));    % preprocessing sqrt (following D&T)


x_grad = conv2(im1(:,:,1),[ 1 0 -1],'same');
y_grad = conv2(im1(:,:,1),[ 1;0;-1],'same');
x_grad(:,1) = x_grad(:,2);
x_grad(:,end) = x_grad(:,end-1);
y_grad(1,:) = y_grad(2,:);
y_grad(end,:) = y_grad(end-1,:);

grad_mag = x_grad.^2+y_grad.^2;
grad_ori = atan2(y_grad,x_grad);

% if image is multichannel, choose the magnitude and orientation of the
% gradient from the highest grad magnitude channel (following D&T)
for c=2:num_channels
    x_grad = conv2(im1(:,:,c),[-1 0 1],'same');
    y_grad = conv2(im1(:,:,c),[-1;0;1],'same');
    x_grad(:,1) = x_grad(:,2);
    x_grad(:,end) = x_grad(:,end-1);
    y_grad(1,:) = y_grad(2,:);
    y_grad(end,:) = y_grad(end-1,:);

    gm = x_grad.^2+y_grad.^2;
    ga = atan2(y_grad,x_grad);
    grad_ori(gm>grad_mag) = ga(gm>grad_mag);
    grad_mag = max(grad_mag,gm);
end
clear ga gm img x_grad y_grad;
grad_mag = sqrt(grad_mag);
grad_ori = grad_ori*180/pi + 180;
grad_ori(grad_ori>180) = grad_ori(grad_ori>180)-180;

% REMOVE
grad_ori = floor(grad_ori); % To be identical to D&T

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 2: Compute HOG for each cell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

var2 = config.HOG_CELL_DIMS(1:2)/(2*config.HOG_WTSCALE);
var2=(var2.*var2*2);

half_bin = config.NUM_HOG_BINS/2;
cenBand = config.HOG_CELL_DIMS/2;
bandwidth = config.HOG_CELL_DIMS ./ config.NUM_HOG_BINS;

% Make sure to leave a 1-pixel margin around the image so the gradient does
% not polute with the edge
num_cells = floor(([W H]-2)./bandwidth(1:2)) - config.NUM_HOG_BINS(1:2)+1;
%num_cells = floor([W H]./bandwidth(1:2)) - config.NUM_HOG_BINS(1:2)+1;
%num_cells = floor([W H]./bandwidth(1:2));

num_angles = config.NUM_HOG_BINS(3);
angle_span = bandwidth(3);
angles = ((1:num_angles)'-0.5)/num_angles*180;

samples_x = (0:(num_cells(1)-1))*bandwidth(1);
samples_y = (0:(num_cells(2)-1))*bandwidth(2);

% D&T Move the grid to the right
%leftover = floor(mod([H W],bandwidth(1:2))/2);
leftover = floor(([W H] - [samples_x(end) samples_y(end)] - config.HOG_CELL_DIMS(1:2))/2);
%leftover = floor(([W H] - [samples_x(end) samples_y(end)] - bandwidth(1:2))/2);

samples_x=samples_x+leftover(1);
samples_y=samples_y+leftover(2);

% ori_hist is a soft orientation assignment at every point for every
% orientation bin. I.e. ori_hist(:,x,y) is non-negative and sums to 1 and
% ori_hist(a,x,y) is the fraction of the gradient angle at pixel (x,y) that falls in bin a
ori_hist = abs(repmat(reshape(angles,[1 1 num_angles]),[H W 1]) - repmat(grad_ori,[1 1 num_angles]));
clear grad_ori;
ori_hist = (max(0,angle_span - ori_hist) + max(0, angle_span - (180 - ori_hist)))/angle_span;

ori_hist = ori_hist.*repmat(grad_mag,[1 1 num_angles]);
clear grad_mag;

hog = zeros([num_cells(2:-1:1) config.NUM_HOG_BINS(3) config.NUM_HOG_BINS(1:2)]);
for x=1:config.HOG_CELL_DIMS(1)
   for y=1:config.HOG_CELL_DIMS(2)
       if config.HOG_NO_GAUSSIAN_WEIGHT
           w=1;
       else
           w = exp(-sum((([x y]-1 - config.HOG_CELL_DIMS(1:2)/2).^2)./var2));
       end
       pt = half_bin(1:2) - 0.5 + ([x y]-0.5 - cenBand(1:2))./bandwidth(1:2);

       xy_bin_frac = pt - floor(pt);
       xy_bin_floor = floor(pt)+1;
       xy_bin_ceil = xy_bin_floor+1;

       weight = ori_hist(samples_y+y,samples_x+x,:)*w;

       % update floor,floor
       if xy_bin_floor(1)>0 && xy_bin_floor(2)>0
           hog(:,:,:,xy_bin_floor(2),xy_bin_floor(1)) = hog(:,:,:,xy_bin_floor(2),xy_bin_floor(1)) + weight*( ((1-xy_bin_frac(1))*(1-xy_bin_frac(2))));
       end

       % update floor,ceil
       if xy_bin_floor(1)>0 && xy_bin_ceil(2)<=config.NUM_HOG_BINS(2)
           hog(:,:,:,xy_bin_ceil(2), xy_bin_floor(1)) = hog(:,:,:,xy_bin_ceil(2),xy_bin_floor(1) ) + weight*( ((1-xy_bin_frac(1))*   xy_bin_frac(2)));
        end

       % update ceil,floor
       if xy_bin_ceil(1)<=config.NUM_HOG_BINS(1) && xy_bin_floor(2)>0
           hog(:,:,:,xy_bin_floor(2),xy_bin_ceil(1) ) = hog(:,:,:,xy_bin_floor(2),xy_bin_ceil(1) ) + weight*(     xy_bin_frac(1) *(1-xy_bin_frac(2)));
       end

       % update ceil,ceil
       if xy_bin_ceil(1)<=config.NUM_HOG_BINS(1) && xy_bin_ceil(2)<=config.NUM_HOG_BINS(2)
           hog(:,:,:,xy_bin_ceil(2) , xy_bin_ceil(1)) = hog(:,:,:,xy_bin_ceil(2) ,xy_bin_ceil(1) ) + weight*(     xy_bin_frac(1) *   xy_bin_frac(2));
       end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 3: Normalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_hog_dims = prod(config.NUM_HOG_BINS);
hog = reshape(hog,[prod(num_cells),num_hog_dims]);

% Normalize (per D&T)
sumsqrd = sqrt(sum(hog.^2,2));
hog=hog./(repmat(sumsqrd,[1,size(hog,2)])+config.HOG_NORM_EPS*num_hog_dims);
hog = min(hog,config.HOG_NORM_MAXVAL);
sumsqrd = sqrt(sum(hog.^2,2));
hog=hog./(repmat(sumsqrd,[1,size(hog,2)])+config.HOG_NORM_EPS2);
hog=single(reshape(hog,[num_cells(2:-1:1),num_hog_dims]));

end
