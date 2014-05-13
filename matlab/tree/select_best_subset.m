%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function [selIdx, total_cost]= select_best_subset(X, n, mask,features_corr)
    assert(n>0 && n<=size(X,2));
    if n==1
        C = computeCost(X, mask, features_corr);
        if size(X,2)>1
            C = C - diag(diag(C));
        end
        [total_cost, selIdx] = min(sum(C, 1));
        return;
    end
    C = computeCost(X,mask,features_corr) + 10000*eye(size(X,2));
    [total_cost, mid] = min(C(:));
    [mi, mj] = ind2sub(size(C), mid);
    selIdx = [mi mj];
    remIdx = setdiff(1:size(X,2), [mi mj]); 
    for ci = 3:n
      cline = sum(C(selIdx, remIdx), 1); 
      [min_linecost, mk] = min(cline);
      total_cost = total_cost + min_linecost;
      selIdx(end+1) = remIdx(mk); %#ok<AGROW>
      remIdx(mk) = [];
    end    
    %assert(abs(2*total_cost+sum(diag(C(selIdx,selIdx)))-sum(sum(C(selIdx,selIdx)))) < 1e-5);
end

function C=computeCost(X,mask,features_corr)
% given a p x n matrix, compute cost of putting X(:,i) and X(:,j) in the
% same cluster in C(i,j)
C = -X'*features_corr(mask, mask)*X;
end

