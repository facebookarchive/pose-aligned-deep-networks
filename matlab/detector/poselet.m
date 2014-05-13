classdef poselet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  A poselet is a computer vision part represented as a set of patches 
%%%  from the training annotations that have locally similar keypoint
%%%  configurations, such as "a frontal face" or "half of a face and a
%%%  right shoulder"
%%% 
%%%  It is defined with seed patch in a training image, which implicitly
%%%  defines the keypoint configuration. The examples of the poselet are then
%%%  constructed using a similarity function that associates the
%%%  configuration to other such configurations in other training images.
%%% 
%%%  The poselet parameters are defined relative to a set of training annotations
%%%  (instance of the 'annotations' class). When defining the poselet examples we don't refer to images but 
%%%  to indices of specific training examples in the annotations class.
%%%  The same image patch may correspond to a different poselets depending
%%%  on which training annotation it is referring to. For example, if two
%%%  people are next to each other, a patch covering both of their faces
%%%  could refer to "frontal face on the left" or "frontal face on the
%%%  right" poselet.
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        % The seed patch
        src_entry_id;   % which annotation the seed patch came from. I.f. a.entry_id == src_entry_id
        src_bounds;     % bounds of the seed patch in the src_entry_id annotation

        % The poselet examples
        dst_entry_ids;  % [N x 1] of uint16. entry_id-s of the poselet examples in the annotations.
        img2unit_xforms;% [3 x 2 x N] a transformation matrix from image coordinates to the example's normalized coordinates
        errs;           % [N x 1] of double. The error (quality of match) of the corresponding patch
        
        size;           % Number of examples
        dims;           % [H x W] normalized dimensions of the poselet
    end
    
    methods
        function p = poselet(src_entry_id, src_bounds, dims)
           p.src_entry_id=src_entry_id;
           p.src_bounds = src_bounds;
           p.dims = dims;
           p.size=0;
        end
        
        function p = select(p, sel)
           p.dst_entry_ids = p.dst_entry_ids(sel);
           p.img2unit_xforms = p.img2unit_xforms(:,:,sel);
           p.errs = p.errs(sel);
           p.size = length(p.errs);
        end
        
        % Generate examples
        % Browse
    end
end


