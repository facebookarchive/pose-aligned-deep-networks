%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [wts,b]=cvx_weights_train(grads,labels,C)
    X = grads;
    y = labels;
    m = size(X,1);
    n = size(X,2);
    c = ones(m,1);
%    C=1/mean(sum(X.^2,2));
    c(y==1) = C;
    c(y==-1) = C*sum(y==1)/sum(y==-1);
    % train svm using cvx
    if ~exist('cvx_begin','file')
       qqq=pwd;
       if exist('../cvx','file')
           cd('../cvx');
       end
       cvx_setup;
       cd(qqq);
    end
    cvx_quiet(false);

    cvx_begin
%        cvx_solver sdpt3
        variables w(n) b xi(m)
        minimize 1/2*sum_square(w) + sum(c.*xi)
        y.*(X*w + b) >= 1 - xi;
        xi >= 0;
        w >= 0;
    cvx_end
    if nargout<2
        wts = w/sum(w)*n;
    else
        wts = w;
    end

end
