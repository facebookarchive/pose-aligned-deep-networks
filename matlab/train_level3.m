%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function level3_model = train_level3(level2_scores, attr_labels, config)
%Train level3 context layers classifier

%This is for iccv
switch config.DATASET
    case config.DATASET_FB
level3_params{1} = '-t 1 -r 1 -g 2.000000 -d 1 -b 1 -e 0.005 -c 0.010000'; 
level2_params{2} = '-t 1 -r 1 -g 1.000000 -d 1 -b 1 -e 0.005 -c 10.000000 '; 
level3_params{3} = '-t 1 -r 1 -g 2.000000 -d 1 -b 1 -e 0.005 -c 1.000000 '; 
level3_params{4} = '-t 1 -r 1 -g 2.000000 -d 1 -b 1 -e 0.005 -c 10.000000'; 
level3_params{5} = '-t 1 -r 1 -g 1.000000 -d 1 -b 1 -e 0.005 -c 0.100000 '; 
level3_params{6} = '-t 1 -r 1 -g 2.000000 -d 1 -b 1 -e 0.005 -c 0.100000 '; 
level3_params{7} = '-t 1 -r 1 -g 2.000000 -d 1 -b 1 -e 0.005 -c 10.000000 '; 
level3_params{8} = '-t 1 -r 1 -g 1.000000 -d 1 -b 1 -e 0.005 -c 100.000000'; 
level3_params{9} = '-t 1 -r 1 -g 2.000000 -d 1 -b 1 -e 0.005 -c 1.000000 ';
    case config.DATASET_ICCV
level3_params{1} = '-t 1 -r 1 -g 2.000000 -c 0.010000';
level3_params{2} = '-t 1 -r 10 -g 2.00000 -c 10.000000'; % -c 100
level3_params{3} = '-t 1 -r 10 -g 0.010000 -c 0.010000';
level3_params{4} = '-t 1 -r 1 -g 0.001000 -c 10.000000';
level3_params{5} = '-t 1 -r 1 -g 2.000000 -c 1.000000';
level3_params{6} = '-t 1 -r 10 -g 0.001000 -c 0.010000';
level3_params{7} = '-t 1 -r 10 -g 2.000000 -c 10.000000';% -c 100
level3_params{8} = '-t 1 -r 10 -g 0.001000 -c 0.001000';
    otherwise
        error('Not implemented');
end
num_attr = size(attr_labels, 2);
    
GRID_SEARCH = false;

level3_model = cell(num_attr,1);
assert(length(unique(attr_labels))==3);

if GRID_SEARCH
    fid = fopen([config.TMP_DIR '/level3_20k_fit.txt'],'w');
    for attr_id=1:num_attr
        labels = attr_labels(:,attr_id);
        %ignore those whith labels = 0
        idx  = find(labels ~= 0);

        disp(sprintf('Training Level 3 %s (%d positive and %d negative examples)',...
            config.ATTR_NAME{attr_id}, sum(labels>0), sum(labels<0)));

        best_poly = grid_find_optimal_params_poly(labels(idx),level2_scores(idx,:));
        str = sprintf('**************** %s BEST POLYNOMIAL: acc: %f  params:%s\n',...
          config.ATTR_NAME{attr_id}, best_poly.acc, best_poly.str);
        disp(str); fprintf(fid,'%s\n',str);
        drawnow;   
        level3_params{attr_id} = best_poly.str;
        level3_model{attr_id}.acc = best_poly.acc;
        level3_model{attr_id}.model = svmtrain(labels(idx),level2_scores(idx,:),level3_params{attr_id});
        level3_model{attr_id}.params = level3_params{attr_id};
    end
    fclose(fid);    
else
    parfor attr_id=1:num_attr
        labels = attr_labels(:,attr_id);
        %ignore those whith labels = 0
        idx  = find(labels ~= 0);

        disp(sprintf('Training Level 3 %s (%d positive and %d negative examples)',...
            config.ATTR_NAME{attr_id}, sum(labels>0), sum(labels<0)));
        level3_model{attr_id}.model = svmtrain(labels(idx),level2_scores(idx,:),level3_params{attr_id});
        level3_model{attr_id}.params = level3_params{attr_id};
        
        % evaluate on the training set
        [~,~,l3s]= svmpredict(labels(idx), level2_scores(idx,:), level3_model{attr_id}.model);
        train_scores = l3s * level3_model{attr_id}.model.Label(1);
        ap = get_precision_recall(train_scores, labels(idx));
        fprintf('%s ap on train set: %4.2f%%\n', config.ATTR_NAME{attr_id}, ap*100);
    end    
end

end

function best = grid_find_optimal_params_poly(labels,features)
   params = zeros(0,4);
   for c=[0.001 0.01 0.1 1 10 100]
        for gamma=[2 1 0.1 0.01 0.001]
            for coeff0=[1 10]
                for degree=[1 1.5]
                    params(end+1,:) = [c gamma coeff0 degree];
                end
            end
        end
   end
    
   acc = zeros(size(params,1),1);   
   parfor i=1:size(params,1)
        c = params(i,1);
        gamma = params(i,2);
        coeff0 = params(i,3);
        degree = params(i,4);

        str = sprintf('-t 1 -r %d -g %f -d %d -b 1 -e 0.005 -c %f',coeff0,gamma,degree,c);

        acc(i) = svmtrain(labels,features,[str ' -v 2']);
        strs{i} = str;
	end
    
    best.acc=max(acc);
    best.str = strs{find(acc==max(acc),1)};
end

