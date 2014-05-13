function [hits,num_evals,features]=detect_poselets(phog, svms, config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Given an RGB uint8 image returns the locations and scores of all
%%% poselets that were detected using the given svm classifiers.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


warning('off','MATLAB:intConvertOverflow');
warning('off','MATLAB:intConvertNonIntVal');

needs_features = nargout>2;

hits=hit_list;

num_evals = 0;
for aspect=1:length(svms)
    if needs_features
        features{aspect}=[];
    end
    for sc=1:length(phog.hog)
        [top_left,poselet1,score1,num_evals1,features1] = detect_poselets_one_scale(phog.hog{sc}.hog, phog.hog{sc}.samples_x, phog.hog{sc}.samples_y, svms{aspect}, needs_features, config);
        num_evals = num_evals + num_evals1;
        N = length(score1);
        if N==0
            continue;
        end

        top_left = top_left+repmat(phog.hog{sc}.img_top_left,N,1);
        bounds = [top_left'; repmat(svms{aspect}.dims(2:-1:1)',1,N)]/phog.hog{sc}.scale;

        hits=hits.append(hit_list(bounds,score1,poselet1,0));

        if needs_features
           features{aspect}(end+(1:N),:) = features1;
        end

        if config.DEBUG>1
           disp(sprintf('Scale %f hits: %d',phog.hog{sc}.scale,N));
        end
    end
end

N = hits.size;
if N>0
    hits.bounds = hits.bounds/phog.img_scale;
end

end


function [top_left,poselet_id,score,num_evals,features]=detect_poselets_one_scale(hog, samples_x, samples_y, svms, needs_features, config)
    [num_blocks, g_hog_blocks] = hog2features(hog,svms.dims,config); % returns in g_hog_blocks
    if prod(num_blocks)==0
       top_left=zeros(0,2);
       poselet_id=[];
       score=[];
       num_evals=[];
       features=[];
       return;
    end

    [qx,qy] = meshgrid(samples_x(1:num_blocks(1)),samples_y(1:num_blocks(2)));
    scores = g_hog_blocks*svms.svms(1:end-1,:)+repmat(svms.svms(end,:),prod(num_blocks),1);

    [q_loc,poselet_id] = find(scores>=config.DETECT_SVM_THRESH);
    score = scores(scores>=config.DETECT_SVM_THRESH);

    % Suppress too many hits of a given poselet type. Keep only the ones
    % with highest scores
    if length(score)>config.DETECT_MAX_HITS_PER_SCALE_PER_POSELET*max(poselet_id)
        valid=true(length(poselet_id),1);
        [srt,srtd]=sort(score,'descend');
        poselet_id_srtd=poselet_id(srtd);
        for p=1:max(poselet_id)
           fnd = find(poselet_id_srtd==p);
           valid(srtd(fnd((config.DETECT_MAX_HITS_PER_SCALE_PER_POSELET+1):end)))=false;
        end

        score=score(valid);
        q_loc=q_loc(valid);
        poselet_id=poselet_id(valid);
    end
    poselet_id = svms.svm2poselet(poselet_id);

    top_left = [qx(q_loc) qy(q_loc)]+1;
    if size(top_left,2)>2   % this could happen if size(qx,1)==1 for a small image
        top_left = reshape(top_left,2,[])';
    elseif isempty(top_left)
        top_left = zeros(0,2);
    end

    num_evals = prod(num_blocks)*length(svms.svm2poselet);

    if needs_features
       features = g_hog_blocks(q_loc,:);
    else
       features=[];
    end
end


