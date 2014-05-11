%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function svm_weights  = liblinear_and_logistic_train(features,labels,weights)
    features(labels==0,:) = [];
    weights(labels==0) = [];
    labels(labels==0) = [];
    
    NN = sum(labels<0);
    NP = sum(labels>0);
    if NN==0 || NP==0
        svm_weights = zeros(1,size(features,2)+1);
        logit_coefs = [-1 0];
    else            
        svm_weights = liblinear_do_train(labels,features,weights);       
        scores = features*svm_weights(1:(end-1))' + repmat(svm_weights(end),length(labels),1);
        pw = sqrt(NN/(NP+1));
        md=liblinear_train(double(labels),double(scores),sprintf('-s 0 -q -B 1 -w1 %f',pw));
        logit_coefs = md.w*md.Label(2);
    end
    svm_weights= svm_weights * logit_coefs(1);
    svm_weights(end) = svm_weights(end) + logit_coefs(2);
end
