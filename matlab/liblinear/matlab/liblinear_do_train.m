%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function svm_weights=liblinear_do_train(train_labels,train_features,w_per_example,w1,b,c)
global config;

NP = size(find(train_labels == 1));
NN = size(find(train_labels == -1));


if ~exist('b','var') || isempty(b)
    b=1;
end
if ~exist('c','var') || isempty(c)
    c = 1./mean(sum(train_features.^2,2));
end

if exist('w_per_example','var') && ~isempty(w_per_example)
    assert(isequal(size(w_per_example),size(train_labels)));
    assert(any(w_per_example)>=0);
    if ~exist('w1','var') || isempty(w1)
        w1= sum(w_per_example(find(train_labels == -1))) ...
           /sum(w_per_example(find(train_labels == 1)));
    end
   
    train_labels = train_labels(w_per_example>0);
    train_features = train_features(w_per_example>0,:);
    w_per_example = w_per_example(w_per_example>0);
    w_per_example(train_labels>0) = w_per_example(train_labels>0)*w1;
    w_per_example=w_per_example*c;
    model=liblinear_train_perexample(train_labels,sparse(double(train_features)),double(w_per_example),sprintf('-B %f -s 3 -q',b));  
    %model = liblinear_train_perexample(double(w_per_example),train_labels, sparse(double(train_features)),sprintf('-B %f -s 3 -q',b));
else
    if ~exist('w1','var') || isempty(w1)
        w1=NN/NP;
    end
    if issparse(train_features)
         model=liblinear_train_sparse(train_labels,train_features,sprintf('-B %f -c %f -s 3 -q -w1 %f',b, c, w1));
    else
        if ~isa(train_features,'double')
            train_features=double(train_features);
        end
        if ~isa(train_labels,'double')
            train_labels=double(train_labels);
        end
        model=liblinear_train(train_labels,train_features,sprintf('-B %f -c %f -s 3 -q -w1 %f',b, c, w1));
    end
end
svm_weights(1,:) = model.w*model.Label(1);
svm_weights(1,end)=svm_weights(1,end)*b;


