function segs = segs_file(id,im2)
global im;
segs=[];
if nargin<2
    if im.has_segs(id)
        segs = [im.image_directories{im.dataset_id(id)} '/segmentations/' im.stem{id} '.png'];
    end        
else
    if im2.has_segs(id)
        segs = [im2.image_directories{im2.dataset_id(id)} '/segmentations/' im2.stem{id},'.png'];
    end
end

