%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function model2file(model,filename)
    global config;
    if ischar(filename)
        fid = fopen(filename,'w');
        fprintf(fid,'<?xml version="1.0" encoding="utf-8"?>\n');
    else
       fid = filename;
    end
    fprintf(fid,'<model category="%s" num_keypoints="%d" num_poselets="%d">\n',config.CLASSES{model.category_id},size(model.hough_votes(1).hyp.mu,1),length(model.selected_p));
    fprintf(fid,'<bounds_regress>\n   ');
    for i=1:length(model.bounds_regress(:))
        fprintf(fid,'%f ',model.bounds_regress(i));
    end
    fprintf(fid,'\n</bounds_regress>\n');

    fprintf(fid,'<wts>\n   ');
    for i=1:length(model.wts)
        fprintf(fid,'%f ',model.wts(i));
    end
    fprintf(fid,'\n</wts>\n');

    fprintf(fid,'<poselets>\n');
    for p=1:length(model.wts)
        for j=1:length(model.svms)
           idx=find(model.svms{j}.svm2poselet==p,1);
           if ~isempty(idx)
               if isfield(model,'bigq_logit_coef')
                  fprintf(fid,'  <poselet dims="%d %d">\n',model.svms{j}.dims([2 1]));
                  fprintf(fid,'     <bigq_weights logit_coef="%f %f">\n          ',model.bigq_logit_coef(p,:));
                  for i=1:size(model.bigq_weights,2)
                      fprintf(fid,'%f ',model.bigq_weights(p,i));
                  end
                  fprintf(fid,'\n     </bigq_weights>\n');
               else
                  fprintf(fid,'  <poselet dims="%d %d" logit_coef="%f %f">\n',model.svms{j}.dims([2 1]),model.logit_coef(p,:));
               end
              fprintf(fid,'     <svm_weights logit_coef="%f %f">\n',model.logit_coef(p,:));
              fprintf(fid,'         ');
              for w=1:size(model.svms{j}.svms,1)
                 fprintf(fid, '%f ',model.svms{j}.svms(w,idx));
              end
              fprintf(fid,'\n     </svm_weights>\n');

              fprintf(fid,'     <obj_bounds pos="%f %f %f %f" var="%f %f %f %f" />\n',model.hough_votes(p).obj_bounds, model.hough_votes(p).obj_bounds_var);
              if isfield(model.hough_votes(p),'torso_ctr')
                  fprintf(fid,'     <torso ctr="%f %f" length="%f" width="%f" angle="%f" />\n',...
                      model.hough_votes(p).torso_ctr, model.hough_votes(p).torso_length, model.hough_votes(p).torso_width, model.hough_votes(p).torso_angle);
              end

              fprintf(fid,'     <coords_sum>\n');
              fprintf(fid,'         ');
              for i=1:size(model.hough_votes(p).hyp.coords_sum,1)
                 fprintf(fid, '%f %f  ',model.hough_votes(p).hyp.coords_sum(i,:));
              end
              fprintf(fid,'\n     </coords_sum>\n');

              fprintf(fid,'     <coords_sum2>\n');
              fprintf(fid,'         ');
              for i=1:size(model.hough_votes(p).hyp.coords_sum2,1)
                 fprintf(fid, '%f %f  ',model.hough_votes(p).hyp.coords_sum2(i,:));
              end
              fprintf(fid,'\n     </coords_sum2>\n');

              fprintf(fid,'     <w_sum>\n');
              fprintf(fid,'         ');
              for i=1:size(model.hough_votes(p).hyp.w_sum,1)
                 fprintf(fid, '%f %f  ',model.hough_votes(p).hyp.w_sum(i,:));
              end
              fprintf(fid,'\n     </w_sum>\n');

              fprintf(fid,'</poselet>\n');
           end
        end
    end
    fprintf(fid,'</poselets>\n');
    fprintf(fid,'</model>\n');
    if ischar(filename)
        fclose(fid);
    end
end
