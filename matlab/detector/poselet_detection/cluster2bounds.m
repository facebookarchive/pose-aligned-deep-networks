function [torsos_for_image,bounds_for_image] = cluster2bounds(hits_for_img,hyps_for_img,cluster_labels_for_img,model,img_dims,config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Returns the object bounds and torso bounds given the clustered poselet
%%% hits in a given image
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source
%%% directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    if config.DEBUG>0
        clf; imshow(config.DEBUG_IMG);
    end

    if ~exist('agglom_thresh','var')
       agglom_thresh=config.CLUSTER_HITS_CUTOFF;
    end

    if isequal(config.CLASSES{model.category_id},'person');
        % Extract torso bounds
        % TODO: Should the torso score use model.wts?? Currently just the bounds score does
        torsos_for_image = hit_list;
        for c=unique(cluster_labels_for_img(cluster_labels_for_img>0))'
            if ~isempty(hits_for_img.src_idx) % Big qs
                smallqs_in_cluster = [];
                for i=find(cluster_labels_for_img==c)'
                   smallqs_in_cluster = [smallqs_in_cluster hits_for_img.src_idx{i}];
                end
                smallqs_in_cluster = unique(smallqs_in_cluster);
               [torso_bounds,torso_angle,torso_score]=compute_torso_bounds(hits_for_img.select(smallqs_in_cluster),...
                                                                                  hyps_for_img(smallqs_in_cluster),config);
            else
               [torso_bounds,torso_angle,torso_score]=compute_torso_bounds(hits_for_img.select(cluster_labels_for_img==c),...
                                                                                  hyps_for_img(cluster_labels_for_img==c),config);
            end
            clear src_idx;
            src_idx{1} = uint32(find(cluster_labels_for_img==c)');
            torsos_for_image = torsos_for_image.append(hit_list(torso_bounds,torso_score,0,hits_for_img.image_id(1),src_idx));
        end

        if config.DEBUG>1
            [srt,top_three]=sort(-torsos_for_image.score);
            top_three(4:end) = [];
            torsos_for_image.select(top_three).draw_bounds('r',0.5,'-',[0 0 0]);
        end

        % Do non-max suppression
        torsos_for_image = agglomerative_cluster_predictions(torsos_for_image,agglom_thresh,config);
        for i=1:torsos_for_image.size
            torsos_for_image.src_idx{i} = unique(torsos_for_image.src_idx{i});
        end

        % Compute the corresponding visible bounds
        if config.DEBUG>0
            [srt,top_three]=sort(-torsos_for_image.score);
            top_three(4:end) = [];
            torsos_for_image.select(top_three).draw_bounds('g');
        end

        bounds_for_image = hit_list;
        bounds_for_image.reserve(torsos_for_image.size);
        for t=1:torsos_for_image.size
            bounds_pred = get_bounds_predictions(hits_for_img.select(torsos_for_image.src_idx{t}),model);
            bounds_pred.src_idx(1) = torsos_for_image.src_idx(t);
            if config.DEBUG>0 && ismember(t,top_three)
                bounds_pred.draw_bounds('b');
            end
            bounds_for_image = bounds_for_image.append(bounds_pred);
        end
    else
        bounds_for_image = hit_list;
        for c=unique(cluster_labels_for_img(cluster_labels_for_img>0))'
            if ~isempty(hits_for_img.src_idx) % Big qs
                smallqs_in_cluster = [];
                for i=find(cluster_labels_for_img==c)'
                   smallqs_in_cluster = [smallqs_in_cluster hits_for_img.src_idx{i}];
                end
                smallqs_in_cluster = unique(smallqs_in_cluster);
            else
                smallqs_in_cluster = find(cluster_labels_for_img==c)';
            end

            bounds_pred = get_bounds_predictions(hits_for_img.select(smallqs_in_cluster),model);
            bounds_pred.src_idx{1,1} = smallqs_in_cluster;
            bounds_for_image = bounds_for_image.append(bounds_pred);
        end


        bounds_for_image = agglomerative_cluster_predictions(bounds_for_image,agglom_thresh,config);

        for i=1:bounds_for_image.size
            bounds_for_image.src_idx{i} = unique(bounds_for_image.src_idx{i});
        end
        torsos_for_image = bounds_for_image;
    end

    % Apply regression and clip bounds to stay within the image
    bounds_for_image.bounds(3:4,:) = bounds_for_image.bounds(3:4,:)+bounds_for_image.bounds(1:2,:);
    bounds_for_image.bounds = model.bounds_regress*bounds_for_image.bounds;
    if config.CROP_PREDICTED_OBJ_BOUNDS_TO_IMG
        bounds_for_image.bounds(1,:) = max(bounds_for_image.bounds(1,:),1);
        bounds_for_image.bounds(2,:) = max(bounds_for_image.bounds(2,:),1);
        bounds_for_image.bounds(3,:) = min(bounds_for_image.bounds(3,:),img_dims(1));
        bounds_for_image.bounds(4,:) = min(bounds_for_image.bounds(4,:),img_dims(2));
    end
    bounds_for_image.bounds(3:4,:) = bounds_for_image.bounds(3:4,:)-bounds_for_image.bounds(1:2,:);
end


function [torso_bounds,torso_angle,torso_score]=compute_torso_bounds(hits_for_torso,hyps_for_torso,config)
    % Get the expected location of the hips and shoulders to construct the torso bounds
    torso_kpts = [config.K(15).L_Shoulder config.K(15).R_Shoulder config.K(15).L_Hip config.K(15).R_Hip];

    kp_mu=reshape([hyps_for_torso(:).mu],size(hyps_for_torso(1).mu,1),2,[]);
    torso_score=sum(hits_for_torso.score);

    if 0
        for kp=1:length(torso_kpts)
            coords = reshape([kp_mu(torso_kpts(kp),1,:) kp_mu(torso_kpts(kp),2,:)],2,[]);
            mean_coords(kp,:) = sum([hits_for_torso.score hits_for_torso.score].*coords',1)/torso_score;
        end
    else
        kp_var=reshape([hyps_for_torso(:).sigma],size(hyps_for_torso(1).sigma,1),2,[]);
        for kp=1:length(torso_kpts)
              coords = shiftdim([kp_mu(torso_kpts(kp),1,:) kp_mu(torso_kpts(kp),2,:)],1)';
              var    = shiftdim([kp_var(torso_kpts(kp),1,:) kp_var(torso_kpts(kp),2,:)],1)';
              mean_coords(kp,:) =get_meanshift_mode(coords,var,repmat(hits_for_torso.score,1,2));
        end
    end

    [torso_bounds,torso_angle] = torso_bounds_from_keypoints(mean_coords,config);
end
