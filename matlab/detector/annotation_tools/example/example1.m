function example1(a)
global config;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EXAMPLE 1
%%%
%%% Display an orientation histogram of the angle 
%%% of torsos relative to the camera.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

K = config.K(15); % Configuration for the person category

nbins=12;
bins_ctr = linspace(0,2*pi,nbins+1); bins_ctr(end)=[];

% Select annotations whose upper clothes are marked
torso_a = a.select(a.contain_part(K.A_UpperClothes));

% Get the vector from the right shoulder to the left shoulder
shoulder_vec = squeeze(torso_a.coords(K.L_Shoulder,:,:)- torso_a.coords(K.R_Shoulder,:,:))';

angle = atan2(shoulder_vec(:,3),shoulder_vec(:,1));
figure(3);
rose(angle+pi/2,bins_ctr);
title('Distribution of torso out-of-plane orientations');

