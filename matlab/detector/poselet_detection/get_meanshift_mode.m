function md = get_meanshift_mode(x,sigma,w,use_meanshift)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Returns a one-dimensional meanshift or just weighted average of the
%%% samples. Internal function.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  x = [x; x+var; x-var];
%  w = [w; w/2; w/2];
%  md = (x'*w)/sum(w);
if size(x,1)==1
   md = x;
   return;
end
   if ~exist('use_meanshift','var') || ~use_meanshift
      w = w./sigma;
      md = (x'*w)/sum(w);
      return;
   end

  [modes,mode_w] = meanshift(x, sigma.^2, w);
  md=modes(find(mode_w==max(mode_w),1),:);
end



function [modes,mode_w,mode_of_x] = meanshift(at, sigma2, w)

x = at;
[N,D] = size(x);

if N==1
   modes = at;
   mode_w = w;
   mode_of_x = 1;
   return;
end

THRESH = 1e-5;
MODE_EPS = 20;
MAX_ITERS = 100;

for iter=1:MAX_ITERS
    for i=1:N
       xdiff = (x - repmat(x(i,:),N,1))./sigma2;
       wt = w.*exp(-sum(xdiff.^2,2) / 2)./sqrt(prod(sigma2,2));
       
       sumw = sum(wt);
       if sumw>0       
           nvalue(i,:) = sum(repmat(wt,1,D).*x,1)./sumw;
       else
           nvalue(i,:) = x(i,:);
       end
    end
    
    shift_sqrd_dist = sum((x - nvalue).^2,2);

    if mean(shift_sqrd_dist)<THRESH
        break;
    end

    x = nvalue;
end


[md,foo,mode_of_x] = unique(round(x*MODE_EPS),'rows');
modes = md./MODE_EPS;

% compute the weight of each mode
for i=1:size(modes,1)
    xdiff = (at - repmat(modes(i,:),N,1))./sigma2;
    dist = exp(-sum(xdiff.^2,2) / 2)./sqrt(prod(sigma2,2));
    mode_w(i,1) = w' * dist;
end
end


