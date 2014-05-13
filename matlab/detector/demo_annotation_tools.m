%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Demo file that shows examples of using H3D
%%%
%%% Copyright (C) 2009, Lubomir Bourdev.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init;
addpath annotation_tools/example/
global config;

h3d_dir = [config.DATA_DIR '/person/image_sets/h3d'];
if ~exist(h3d_dir,'file')
   error('Please download H3D and place it in %s',h3d_dir);
end

% Registering the images
global im;
h3d_file = [h3d_dir '/h3d_b.mat'];
if exist(h3d_file, 'file')
    load(h3d_file);
else
    disp('initializing and caching H3D images');
    enroll_dataset_images(h3d_dir,1); % saves them in global 'im'

    disp('extracting and caching H3D annotations');
    a_h3d_train = annotation_list([h3d_dir '/train_annotation_list.txt']);
    a_h3d_train = a_h3d_train.append(a_h3d_train.get_flipped_annotations);
    a_h3d_test  = annotation_list([h3d_dir '/test_annotation_list.txt']);
    a_h3d_test  = a_h3d_test.append(a_h3d_test.get_flipped_annotations);
    a_h3d_val   = annotation_list([h3d_dir '/val_annotation_list.txt']);
    a_h3d_val   = a_h3d_val.append(a_h3d_val.get_flipped_annotations);
    %a=generate_annotations('h3d','image_list.txt');
    save(h3d_file,'a_h3d_train','a_h3d_test','a_h3d_val','im');
end
clear i img_file h3d_dir h3d_file;

% Combine all
a = a_h3d_train.append(a_h3d_test.append(a_h3d_val));


disp('Example 1. Please press a key');
example1(a);

pause;
disp('Example 2 (using the first 50 annotations)');
example2(a.select(1:50));

disp('Example 3');
example3(a);
