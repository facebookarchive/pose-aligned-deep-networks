%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% hypothesis: Maintains a hypothesis on the pose of a human.
%%% The locations of each keypoint are represented as Gaussians
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef hypothesis

    properties
        mu,sigma;      % K x 2   representing an isomorphic Gaussian for each of the K keypoints fitted over coords,weight
                       %   Never change mu,sigma directly. Instead change the sufficient statistics and call recompute_mu_sigma
        w_sum;         % K x 2 weight given to each keypoint
        coords_sum,coords_sum2; % K x 2  sufficient statistics. sum of samples and sum of squared samples
        rect;        % bounding box of the keypoint means, expressed as [x_min y_min x_max y_max]. Used to speed up distance computation between hypotheses that are too far
    end
    methods
        function h = hypothesis(coords, weights)
            if nargin>0
                [NumKP,Two,N]=size(coords);
                assert(isequal(size(weights),[N 1]) && Two==2);% && NumKP==K.NumPrimaryKeypoints);

                % Compute the weighted avarage of the coordinates, ignoring NaNs
                w = reshape(weights,[1 1 N]);
                w = repmat(w,[NumKP 2 1]);
                w(isnan(coords)) = 0;

                coords(isnan(coords)) = 0;
                h.coords_sum  = sum( coords.*    w,3);
                h.coords_sum2 = sum((coords.^2).*w,3);

                h.w_sum = sum(w,3);
                h.w_sum(h.w_sum==0)=nan;

                h=h.recompute_mu_sigma;
            end
        end

        % Returns the distance between two hypotheses. Uses the symmetrized
        % KL-divergence for each of them and adds them together, which is
        % equivalent to assuming they are independent
        function [d,dk] = distance(h1,h2,config)
            % Do the bounds intersect?
            if ~all(max(h1.rect(1:2),h2.rect(1:2))<min(h1.rect(3:4),h2.rect(3:4)))
               d=inf; % bounds dont intersect. The distance is too large
               dk=[];
               return;
            end

            meandiff_sqrd = (h1.mu - h2.mu).^2;
            %  d = sum(h1.sigma./h2.sigma,2) + sum(h2.sigma./h1.sigma,2) + sum(meandiff_sqrd./h1.sigma,2) + sum(meandiff_sqrd./h2.sigma,2);
            % dk = 0.5*sum(h1.sigma./h2.sigma + h2.sigma./h1.sigma + meandiff_sqrd./h1.sigma + meandiff_sqrd./h2.sigma - 2, 2);
            dk = sum((h1.sigma+meandiff_sqrd)./h2.sigma + (h2.sigma + meandiff_sqrd)./h1.sigma - 2, 2)/2;

            if config.KL_USE_WEIGHTED_DISTANCE
                dk(isnan(dk))=0;
                d = sum(dk.*config.KL_WEIGHTS) / sum(dk) * config.KL_LOGIT(1) + config.KL_LOGIT(2);
            else
                d = sum(dk(~isnan(dk))) / sum(~isnan(dk)); % Matlab's mean is slow, says profiler!
                if isnan(d)
                    d=inf;
                    dk(:)=inf;
                end
            end
        end

        % changed coords_sum and coords_sum2 to get the given mu, sigma and w_sum
        function h = set_mu_sigma(h,mu,sigma,w_sum)
            config.HYPOTHESIS_PRIOR_VAR = 1;
            config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT = 1;
            if nargin>3
                h.w_sum = w_sum;
            end
            h.coords_sum = mu.*h.w_sum;
%            h.coords_sum2 = (sigma+mu.^2).*(h.w_sum+config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT) - config.HYPOTHESIS_PRIOR_VAR;
            sum1=h.w_sum+config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT;
            h.coords_sum2 = (sigma.*sum1 + 2*mu.*h.coords_sum - (mu.^2).*h.w_sum - config.HYPOTHESIS_PRIOR_VAR*config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT);

            h=h.recompute_mu_sigma;
        end

        % Sigma is complicated because of the prior which is equivalent to
        % having variance of HYPOTHESIS_PRIOR_VAR with weight HYPOTHESIS_PRIOR_VARIANCE_WEIGHT
        function h = recompute_mu_sigma(h)
            config.HYPOTHESIS_PRIOR_VAR = 1;
            config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT = 1;
            h.mu = h.coords_sum./h.w_sum;
            h.sigma = (h.coords_sum2 - 2*h.mu.*h.coords_sum + (h.mu.^2).*h.w_sum + config.HYPOTHESIS_PRIOR_VAR*config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT)./...
                      (h.w_sum+config.HYPOTHESIS_PRIOR_VARIANCE_WEIGHT);

            h.sigma(~isnan(h.sigma(:))) = max(eps,h.sigma(~isnan(h.sigma(:))));
%            assert(all(isnan(h.sigma(:))) || min(h.sigma(~isnan(h.sigma(:))))>0);
            h.rect = [min(h.mu) max(h.mu)];
%            pad=mean(h.rect(3:4)-h.rect(1:2))*0.1;
%            h.rect = h.rect + [-pad -pad pad pad];
        end

        % change coords_sum and coords_sum2 so that:
        % mu = mu*scale + translation
        % sig = sig*scale^2
        function h = apply_xform(h, translation, scale)
            h = h.set_mu_sigma(h.mu*scale+(repmat(translation,size(h.coords_sum,1),1)), h.sigma*scale*scale);
        end

        function draw(h, keypts_range, colors, style, mult)
            if ~exist('keypts_range','var') || isempty(keypts_range)
                global K;
                keypts_range=1:K.NumPrimaryKeypoints;
            end
            if ~exist('colors','var') || isempty(colors)
                colors=jet(length(keypts_range));
            end
            if ~exist('style','var') || isempty(style)
                style='-';
            end
            if ~exist('mult','var')
               mult=1;
            end
            for i=1:length(keypts_range)
                size = sqrt(h.sigma(keypts_range(i),:))*mult;
                if all(~isnan(size))
                    rectangle('position', [h.mu(keypts_range(i),:) - size size*2], 'curvature',1, 'edgecolor',colors(i,:),'linestyle',style,'linewidth',2);
                end
            end
        end
    end
end
