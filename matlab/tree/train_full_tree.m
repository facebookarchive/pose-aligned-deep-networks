%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function root = train_full_tree(model, preserved, target_dr, prefix)


if ~exist('model','var')
    [model,preserved] = prepare_model;
end

fprintf('Target DR: %f. Max children: %d Child_r: %f\n',target_dr, model.max_children, model.child_r);
for ar=1:length(model.svms)
    savefile_name = sprintf('/tmp/%stree%d_ar%d_%f.mat',prefix,model.max_children,ar,model.child_r);
    if exist(savefile_name,'file')
        load(savefile_name);
    else
        rng(1234);
        fprintf('Training aspect ratio %d\n',ar);
        num_stripes = model.svms{ar}.dims(1)/8-1;

        fff = load(sprintf('~lubomir/poselets/data/features/collected/A%d_D0.02.mat',ar));
%        fff = load(sprintf('~lubomir/poselets/data/features/collected1200/A%d_D0.02.mat',ar));
if 0
        numneg = sum(fff.testlabels==-1);
        [rem fff.testlabels] = ismember(fff.testlabels, [preserved -1]);
        fff.testlabels = fff.testlabels(rem);
        fff.testdata = fff.testdata(:,rem);
        fff.testlabels(fff.testlabels == max(fff.testlabels)) = -1;
        assert(sum(fff.testlabels==-1)==numneg);
end
        num_samples = length(fff.testlabels);

        cvp = cvpartition(num_samples,'kfold',3);
        all_examples = examples(fff.testdata, fff.testlabels);
        clear fff;
        train_idx = find(cvp.test(1));
        val_idx = find(cvp.test(2));
        test_idx = find(cvp.test(3));

        model.features_corr = corrcoef(all_examples.features(:,cvp.test(1))');
        root(ar) = par_train_tree(model, ar, all_examples, train_idx, val_idx, target_dr);

        neg_weights = 500;
        sample_weights = (all_examples.labels(test_idx)<0) * neg_weights + (all_examples.labels(test_idx)>0);
        fprintf('Evaluating on %d test examples (%d virtual)\n', length(all_examples.labels(test_idx)), round(sum(sample_weights)));
        test_f = [all_examples.features(:,test_idx); zeros(1, length(test_idx))];
        [pids,idx,cost] = root(ar).eval_tree(test_f, sample_weights);

        tp = sum(all_examples.labels(test_idx(idx)) == pids);
        dr = tp / sum(all_examples.labels(test_idx)>0);
        bf_cost = length(model.svms{ar}.svm2poselet) * sum(sample_weights) * num_stripes;
        fprintf('Test dr:%4.2f%%  speedup:%4.2f%%\n', dr*100, bf_cost*100/cost);

        save(savefile_name, 'root');
    end
end
if matlabpool('size')>12
    matlabpool('close');
end
generate_tree_XML(sprintf('/tmp/%stree%d_%f.xml',prefix,model.max_children, model.child_r), root);

end

