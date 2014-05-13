function example2(a)
global config;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EXAMPLE 2
%%%
%%% Extract upper body clothes of people and display 
%%% them sorted by out-of-plane angle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

K = config.K(15); % Configuration for the person category

disp(sprintf('Extracts the upper body clothes of people and displays them'));
disp(sprintf('in a grid sorted by torso-to-camera angle'));

PATCH_DIMS = [30 10]*5; % Resolution of the patches
MAX_ZOOM = 2;           % Skip any examples that require scaling more than MAX_ZOOM
MAX2SHOW = 30;          % How many examples to display at the same time

% Select annotations whose upper clothes are marked
torso_a = a.select(a.contain_part(K.A_UpperClothes));

% Sort them by out-of-plane angle of the torso (approximated with the angle
% of the shoulders with the X axis)
shoulder_vec = squeeze(torso_a.coords(K.L_Shoulder,:,:)- torso_a.coords(K.R_Shoulder,:,:))';
torso_angle = atan2(shoulder_vec(:,3),shoulder_vec(:,1));
[torso_angle,srt] = sort(torso_angle);
torso_a = torso_a.select(srt);

% Extract patches such that the midpoint of the shoulders is at the top center
% and the midpoint of the hips is at the bottom center

part = find_examples_by_fixing_keypoints(torso_a, K.M_Shoulder,[0 -0.4],K.M_Hip,[0 0.4],true,MAX_ZOOM);
part.dims=PATCH_DIMS;

% Uncomment this line to display the first few examples of the part
% visualize_part(a,part);

NumTorsos = part.size;
figure(1);
first=1;
while first<=NumTorsos
    last = min(NumTorsos,first+MAX2SHOW-1);    

    % Select the samples to show in this round
    part2show = part.select(first:last);

    % Extract the image patches and the pixel labels
    [all_thumbs,falls_outside,all_labels] = extract_patches_of_poselets(a,part2show);

    % Mask out the rest of the image
    [H W N]=size(all_labels{1});
    mask=reshape(repmat(all_labels{1}~=K.A_UpperClothes,[1 1 1 3]),[H W N 3]);
    all_thumbs{1}(permute(mask,[1 2 4 3]))=0;
    
    
    display_patches(all_thumbs{1}, num2str(part2show.dst_entry_ids'));
    title(sprintf('Parts %d-%d of %d. Press a key for the next batch',first,last,NumTorsos));
    first=last+1;
    pause;
end

end




% Extracts image-to-patch transformations for each annotation. Transforms them
% by placing the two keypoints in the expected locations in image space
% Skips any samples that don't contain both keypoints or whose
% transformation results in too large a scale
% The normalized coordinates are such that -0.5 .. 0.5 map to the edges of
% the patch. 
% Returns the subset of the annotations that contain the given xforms
function part = find_examples_by_fixing_keypoints(a, keypoint1, keypoint1_coords, ...
                     keypoint2, keypoint2_coords, both_visible, max_zoom)

    if ~exist('max_zoom','var')
        max_zoom = 0;
    end
    if ~exist('both_visible','var')
        both_visible = true;
    end

    % Collect the image-to-patch transforms and the ids of the valid
    % annotations (the ones that contain both keypoints and are not too small)
    img2patch_xforms = zeros([3 3 0]);
    valid_annots = []; % Collect indices of valid entries in a
    for i=1:a.size
        if both_visible && (a.visible(keypoint1,i)==0 || a.visible(keypoint2,i)==0)
            continue;
        end
        coords = a.coords([keypoint1 keypoint2],1:2,i);
        if any(isnan(coords(:)))
            continue;
        end
        [img_to_patch,scale] = get_matrix(coords(1,:), keypoint1_coords, coords(2,:),  keypoint2_coords);
        if scale<=max_zoom
            img2patch_xforms(:,:,end+1) = img_to_patch; %#ok<AGROW>
            valid_annots(end+1) = i; %#ok<AGROW>
        end
    end

    %a_subset = a.select(valid_annots);
    N = size(img2patch_xforms,3);
    part = poselet(0,[0 0 1 1],[100 100]);
    part.errs=zeros(N,1);
    part.dst_entry_ids = a.entry_id(valid_annots);
    part.img2unit_xforms = img2patch_xforms(:,1:2,:);
    part.size = N;
end


% Returns a transformation matrix that maps a1 to b1 and a2 to b2
function [M,s,alpha] = get_matrix(a1,b1, a2,b2)
    % move the origin at a1
    a2 = a2-a1;

    AB = inv([a2(1) -a2(2); a2(2) a2(1)])*(b2'-b1');
    s = sqrt(AB(1)^2 + AB(2)^2);
    alpha = atan2(AB(2), AB(1));

    M = [s*cos(alpha) -s*sin(alpha) b1(1); ...
         s*sin(alpha)  s*cos(alpha) b1(2); ...
         0             0            1] ...
      * [1 0 -a1(1); 0 1 -a1(2); 0 0 1];
    M = M';
end
 