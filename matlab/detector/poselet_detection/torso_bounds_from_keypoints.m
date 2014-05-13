function [torso_bounds,torso_angle]=torso_bounds_from_keypoints(lrshoulder_lrhip_coords,config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Returns a rectangle approximation of the torso.
%%% lrshoulder_lrhip_coords should be an array of 4x2xN doubles, where the
%%% first dimension is the keypoint in order: [left_shoulder right_shoulder left_hip right_hip]
%%% The second dimension is the x,y coordinate and the last dimension is the N annotations
%%% Returns an Nx4 array of torso bounds in [minx,miny,width,height] format and an
%%% Nx1 array of angles, where 0 is vertical. The angles are computed
%%% centered at the torso center
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    mShoulder = shiftdim(mean(lrshoulder_lrhip_coords(1:2,1:2,:)))';
    mHip      = shiftdim(mean(lrshoulder_lrhip_coords(3:4,1:2,:)))';
    torsoCtr = (mShoulder+mHip)/2;

    spine = mShoulder - mHip;
    torso_length = sqrt(sum(spine.^2,2));
    torso_dir = spine./[torso_length torso_length];

    torso_angle = atan2(torso_dir(:,2),torso_dir(:,1))+pi/2;
    torso_angle(torso_angle>pi) = torso_angle(torso_angle>pi)-2*pi;
    torso_dims = [torso_length/config.TORSO_ASPECT_RATIO torso_length];
    torso_bounds = [torsoCtr-torso_dims/2 torso_dims]';
end
