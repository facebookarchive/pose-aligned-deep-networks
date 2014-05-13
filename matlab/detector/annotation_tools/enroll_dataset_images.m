function enroll_dataset_images(dataset_dir,dataset_id,image_list_file)
global config;
global im;

tic;
if isempty(im)
    im.stem = cell(0,1);
    im.has_segs = false(0,1);
    im.dims = zeros(0,2,'uint32');
    im.difficult_bounds = cell(0,1);
    im.dataset_id=zeros(0,1,'uint32');
    im.image_directories={};
end
im.image_directories{dataset_id}=dataset_dir;

if ~exist('image_list_file','var')
    image_list_file='annotation_list.txt';
end

difficult_stems={};
difficult_bounds=zeros(0,5);
fid = fopen([dataset_dir '/difficult.txt'],'r');
if fid>0
    dp = textscan(fid,'%s %d %d %d %d %s');
    difficult_stems = dp{1};
    difficult_bounds = [dp{2} dp{3} dp{4} dp{5}];     
    fclose(fid);

    % Find the class of the difficult object. Default is person
    difficult_classes = ones(length(difficult_stems),1)*find(ismember(config.CLASSES,'person'));
    for i=1:length(config.CLASSES)
        difficult_classes(ismember(dp{6},config.CLASSES{i})) = i;
    end
    difficult_bounds(:,5) = difficult_classes;  % The last column is the class ID
end

fid = fopen([dataset_dir '/' image_list_file],'r');
info_files = textscan(fid,'%s');
info_files = info_files{1};
fclose(fid);


numFiles = length(info_files);

disp(sprintf('Enrolling %s',dataset_dir));
for i=1:numFiles
    fnd = strfind(info_files{i},'_');
    stem = info_files{i}(1:fnd(end)-1);
    prf=findstr(stem,'/');
    if ~isempty(prf)
        stem=stem((prf(end)+1):end);
    end

    if isempty(find(ismember(im.stem,stem),1))
        im.stem{end+1,1} = stem;
        im.difficult_bounds{end+1,1} = difficult_bounds(ismember(difficult_stems,stem),:);
        im.dataset_id(end+1,1) = dataset_id;

        img = imread(image_file(length(im.stem)));
        im.dims(end+1,:) = [size(img,2) size(img,1)];
%        info=imfinfo(image_file(length(im.stem))); % imfinfo sometimes crashes
%        im.dims(end+1,:) = [info.Width info.Height];

        im.has_segs(end+1,:)=exist([dataset_dir '/segmentations/' stem '.png'],'file');
    end
    if mod(i,round(numFiles/10))==0
        fprintf('.');
    end
end
disp(sprintf('Enrolled %s. Images so far: %d',dataset_dir,length(im.stem)));
toc;

