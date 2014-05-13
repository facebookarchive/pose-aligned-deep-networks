function imgfile = image_file(id,im2)
global im;

if nargin<2
    if isfield(im,'image_file')
        imgfile = im.image_file{id};
    else
        imgfile = [im.image_directories{im.dataset_id(id)} '/images/' im.stem{id} '.jpg'];
    end
else
    if isfield(im2,'image_file')
        imgfile = im2.image_file{id};
    else
        imgfile = [im2.image_directories{im2.dataset_id(id)} '/images/' im2.stem{id},'.jpg'];
    end
end

