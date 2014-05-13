function a=write_annotations(a,root_dir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Writes the annotation list to a directory of XML files
%%% Don't call directly. Instead call the annotation_list's writexml method.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   global im;
   global config;
   K = config.K(a.category_id);
   if ~exist(root_dir,'file')
       mkdir(root_dir);
   end
   fid = fopen([root_dir '/annotations_list.txt'],'w');
   for i=1:a.size
       if a.img_flipped(i)
           continue; % don't include the flipped ones
       end
        docNode = com.mathworks.xml.XMLUtils.createDocument('annotation');
        docRootNode = docNode.getDocumentElement;
        docRootNode.setAttribute('id',sprintf('%d',a.entry_id(i)));

        imageNode = docNode.createElement('image');
        imageNode.appendChild(docNode.createTextNode(im.stem{a.image_id(i)}));
        docRootNode.appendChild(imageNode);

        classNode = docNode.createElement('category');
        classNode.appendChild(docNode.createTextNode(config.CLASSES{a.category_id}));
        docRootNode.appendChild(classNode);

        if ~isempty(a.subcategory{i})
            subcatNode = docNode.createElement('subcategory');
            subcatNode.appendChild(docNode.createTextNode(a.subcategory{i}));
            docRootNode.appendChild(subcatNode);
        end
        if a.pose(i)>0
            poseNode = docNode.createElement('pose');
            poses = {'Left','Right','Frontal','Rear'};
            poseNode.appendChild(docNode.createTextNode(poses(a.pose(i))));
            docRootNode.appendChild(poseNode);
        end
        if ~any(isnan(a.bounds(i,:)))
            boundsNode = docNode.createElement('visible_bounds');
            boundsNode.setAttribute('xmin',sprintf('%4.2f',a.bounds(i,1)));
            boundsNode.setAttribute('ymin',sprintf('%4.2f',a.bounds(i,2)));
            boundsNode.setAttribute('width',sprintf('%4.2f',a.bounds(i,3)));
            boundsNode.setAttribute('height',sprintf('%4.2f',a.bounds(i,4)));                    
            docRootNode.appendChild(boundsNode);
        end
        if a.voc_id(i)>0
            vocidNode = docNode.createElement('voc_id');
            vocidNode.appendChild(docNode.createTextNode(sprintf('%d',a.voc_id(i))));
            docRootNode.appendChild(vocidNode);                    
        end

        coordsNode = docNode.createElement('keypoints');
        [srt,srtd]=sort(K.Labels);
        srtd(srtd>K.NumPrimaryKeypoints)=[]; % Only save primary keypoints
        for kp=srtd
           if ~isnan(a.coords(kp,1,i))
              kpNode = docNode.createElement('keypoint');
              kpNode.setAttribute('name',K.Labels{kp});
              kpNode.setAttribute('x',sprintf('%4.2f',a.coords(kp,1,i)));
              kpNode.setAttribute('y',sprintf('%4.2f',a.coords(kp,2,i)));
              kpNode.setAttribute('z',sprintf('%4.2f',a.coords(kp,3,i)));
              kpNode.setAttribute('zorder',sprintf('%d',a.keypoint_z_order(kp,i)-1));
              kpNode.setAttribute('visible',sprintf('%d',a.visible(kp,i)));
              coordsNode.appendChild(kpNode);
           end
        end
        docRootNode.appendChild(coordsNode);

        if ~isempty(a.segment_ids{i})
            areaNode = docNode.createElement('segments');
            [srt,srtd]=sort(K.AreaNames);
            for ar=srtd
               ids4label = sort(a.segment_ids{i}(a.segment_labels{i}==ar));
               if ~isempty(ids4label)
                  arNode = docNode.createElement('segment');
                  arNode.setAttribute('name',K.AreaNames{ar});
                  ids4labelStr = sprintf('%d ',ids4label);
                  arNode.setAttribute('segments',ids4labelStr(1:(end-1)));
                  areaNode.appendChild(arNode);                          
               end
            end
            docRootNode.appendChild(areaNode);
        end


        outfile_name=[im.stem{a.image_id(i)} '_' num2str(a.entry_in_image_id(i)) '.xml'];
        xmlwrite([root_dir '/' outfile_name],docNode);
        fprintf(fid,'%s\n',outfile_name);
        disp(outfile_name);
   end
end