function patches = hits2patches(hits,dims,sampling,im)

if ~exist('sampling','var') || isempty(sampling)
   sampling='bilinear'; 
end
if ~exist('im','var')
   global im; 
end

for i=1:hits.size
    scale = 1/min(hits.bounds([3 4],i));
    tr = hits.bounds([1 2],i)';
    unit2src_xform = ...
        [1 0 0
         0 1 0
         -tr 1] * ...
         [scale 0 0
          0 scale 0
          0 0 1] * ...
        [1 0 0
         0 1 0
         -dims/(2*min(dims)) 1];
           
   src2unit_xforms(:,:,i) = double(unit2src_xform);
end

patches = zeros([dims([2 1]) 3 length(hits)],'uint8');

count=0;
image_ids = unique(hits.image_id);
for i=1:length(image_ids)
    img_id = image_ids(i);

    hit_ids   = find((hits.image_id==img_id));
    if isempty(hit_ids)
        continue;
    end

    img=imread(image_file(img_id,im));
    for h=hit_ids'
       patches(:,:,:,h) = transform_resize_crop(img, src2unit_xforms(:,:,h), dims, sampling, nan); 
       count=count+1;
       if mod(count,100)==0
           fprintf('.');
       end
    end
end
