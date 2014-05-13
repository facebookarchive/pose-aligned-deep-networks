%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function data = data_collection()
%collect albums for experiments
global config;

filename = fullfile(config.DATA_DIR,'albums_info.mat');
if exist(filename,'file')
    load(filename);
else
    albums = get_album_info();
    save(filename,'albums');
end

filename = fullfile(config.DATA_DIR,'data_20albums.mat');
if exist(filename,'file')
    load(filename);
else
    data = select_albums(albums);
    save(filename,'data');
end

end


function albums = get_album_info()
%get the albums info for data selection
out = dbquery('select album_id, album_type, count(distinct subject_id) from photo_albums, object_poselet_facebox_hit where photo_albums.photo_fbid = object_poselet_facebox_hit.photo_fbid and album_type=0 and subject_id!=0 group by album_id  limit 1000000000');
data = textscan(out,'%u64 %d %d');
album_ids = data{1};
album_count = data{3};

album_map = containers.Map(album_ids, [1:size(album_ids)]);

out_album = dbquery('select distinct album_id,subject_id from photo_albums, object_poselet_facebox_hit where photo_albums.photo_fbid = object_poselet_facebox_hit.photo_fbid and album_type = 0 and subject_id!=0 limit 1000000');
data = textscan(out_album,'%u64 %u64');
album_ids2 = data{1};
album_subject_ids  = data{2};
album_subjects = cell(length(album_ids),1);
for i = 1:length(album_ids)
    idx = find(album_ids2 == album_ids(i));
    album_subjects{i} = album_subject_ids(idx);
end

album_weights = zeros(length(album_ids),length(album_ids));
for i = 1:length(album_ids)
    for j = i+1:length(album_ids)
        album_int =intersect(album_subjects{i},album_subjects{j});
        if isempty(album_int)
            album_weights(i,j) = 0;
        else
            album_weights(i,j) = size(album_int,1);
        end
        
    end
end
album_weights = album_weights + album_weights';

out_album_photo = dbquery('select distinct album_id , object_poselet_facebox_hit.photo_fbid from photo_albums,object_poselet_facebox_hit where photo_albums.photo_fbid = object_poselet_facebox_hit.photo_fbid and photo_albums.album_type=0 and object_poselet_facebox_hit.subject_id!=0 limit 10000000');
data = textscan(out_album_photo,'%u64 %u64');
album_ids3 = data{1};
album_photoids = data{2};
album_photos = cell(length(album_ids),1);
for i = 1:size(album_ids)
    idx = find(album_ids3 == album_ids(i));
    album_photos{i} = album_photoids(idx);
end
albums.album_ids = album_ids;
albums.album_count = album_count;
albums.album_photos = album_photos;
albums.album_weights = album_weights;
albums.album_subjects = album_subjects;
albums.album_map = album_map;
end


function download_all_images(albums,data)
%download all the images for selected albums, call if needed
for i= 1:length(data.total_album)
    mkdir(num2str(data.total_album(i)));
    idx = find(albums.album_ids == data.total_album(i));
    p = albums.album_photos{idx};
    for j = 1:numel(p)
        image = load_image(p(j));
        filename = [config.DATA_DIR '/' num2str(data/total_album(i)) '/' num2str(p(j)) '.jpeg'];
        imwrite(image,filename,'jpeg');
    end
end
end

function data = select_albums(albums)
%select albums based on the album_count and album_weights
%start from the album with most subjects and expand based on the weights
total_album=[];
[~,ind] = sort(albums.album_count,'descend');
for i = 1:3
    total_album = [total_album albums.album_ids(ind(i))];
end
new_add_old = total_album;
while(length(total_album)<20)
    new_add=[];
    for u = new_add_old
        [~,ind]=sort(albums.album_weights(albums.album_map(u),:),'descend');
        i=1;
        while(length(new_add)<3)
            if(isempty(find(total_album == albums.album_ids(ind(i)))))
                new_add = [new_add albums.album_ids(ind(i))];
            end
            i = i +1;
        end
    end
    new_add_old = new_add;
    total_album = [total_album new_add];
end

total_subjects = [];
for i = 1:length(total_album)
    total_subjects = [total_subjects albums.album_subjects{albums.album_map(total_album(i))}'];
end
total_subjects = unique(total_subjects);

total_photo = [];
for i = 1:length(total_album)
    idx(i) = find(albums.album_ids == total_album(i));
    total_photo = [total_photo albums.album_photos{idx(i)}'];
end
total_photo = unique(total_photo);

data.total_album = total_album;
data.total_photo = total_photo;
data.total_subjects = total_subjects;
end

