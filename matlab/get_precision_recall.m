%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%

function [ap,rec,prec] = get_precision_recall(scores,labels,num_truths)
if nargin==2
    num_truths=sum(labels==1);
end
[srt1,srtd]=sort(scores,'descend');
fp=cumsum(labels(srtd)==-1);
tp=cumsum(labels(srtd)==1);
rec=tp/num_truths;
prec=tp./(fp+tp);

%print_precrec(srt1,prec,rec);

mrec=[0 ; rec ; 1];
mpre=[0 ; prec ; 0];
for i=numel(mpre)-1:-1:1
    mpre(i)=max(mpre(i),mpre(i+1));
end
i=find(mrec(2:end)~=mrec(1:end-1))+1;
ap=sum((mrec(i)-mrec(i-1)).*mpre(i));

end


function print_precrec(score,prec,rec)

for rc=0.1:0.1:0.9
    t = find(rec>rc,1);
    fprintf('recall: %4.2f  precision: %4.2f  score: %4.2f\n',rec(t),prec(t),score(t));
end

end

