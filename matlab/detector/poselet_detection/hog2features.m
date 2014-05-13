function [num_blocks,g_hog_blocks]=hog2features(hog_c, patch_dims, config)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% hog2features: Converts HOG cells to features.
%%% For speed, the result is returned in the global variable g_hog_blocks
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

g_hog_blocks=[];
num_blocks=[0 0];
if ~config.USE_PHOG
   [num_blocks,g_hog_blocks]=hog2features_internal(hog_c, patch_dims, config);
else
   [num_blocks1,hog_blocks1]=hog2features_internal(hog_c.hog1, patch_dims, config);
   if any(num_blocks1==0)
       return;
   end
   hog_blocks1=reshape(hog_blocks1,num_blocks1(2),num_blocks1(1),[]);

   [H2,W2,Y2,X2,D]=size(hog_c.hog2);
   assert(H2==2 && W2==2);
   for y=1:H2
       for x=1:W2
           [nb,hb] = hog2features_internal(reshape(hog_c.hog2(y,x,:,:,:),Y2,X2,D), patch_dims/2, config);
           hog_blocks2(y,:,x,:,:) = reshape(hb,nb(2),nb(1),[]);
           if exist('num_blocks2','var')
               assert(isequal(nb,num_blocks2));
           else
              num_blocks2=nb;
               if any(num_blocks2==0)
                   g_hog_blocks=[];
                   num_blocks=[0 0];
                   return;
               end
           end
       end
   end

   [H4,W4,Y4,X4,D]=size(hog_c.hog4);
   assert(H4==4 && W4==4);
   for y=1:H4
       for x=1:W4
           [nb,hb] = hog2features_internal(reshape(hog_c.hog4(y,x,:,:,:),Y4,X4,D), patch_dims/4, config);
           hog_blocks4(y,:,x,:,:) = reshape(hb,nb(2),nb(1),[]);
           if exist('num_blocks4','var')
               assert(isequal(nb,num_blocks4));
           else
              num_blocks4=nb;
               if any(num_blocks4==0)
                   g_hog_blocks=[];
                   num_blocks=[0 0];
                   return;
               end
           end
        end
   end

   num_blocks = min([num_blocks1; num_blocks2*2; num_blocks4*4]);

   % Reference implementation. Slow but more readable version that must
   % produce the same result as the real one
   if config.DEBUG>100
       disp('Running hierarchical features reference implementation');
       hb1=reshape(hog_blocks1(1:num_blocks(2),1:num_blocks(1),:),[],size(hog_blocks1,3));
       for x=0:(num_blocks(1)-1)
          for y=0:(num_blocks(2)-1)
    %          disp(sprintf('y=%d x=%d blocks2(%d,%d,%d)  blocks4(%d,%d,%d)',y,x,mod(y,2)+1,mod(x,2)+1,floor(x/2)*num_blocks2(2)+floor(y/2)+1,mod(y,4)+1,mod(x,4)+1,floor(x/4)*num_blocks4(2)+floor(y/4)+1));
              hb2(x*num_blocks(2)+y+1,:) = hog_blocks2(mod(y,2)+1,floor(y/2)+1,mod(x,2)+1,floor(x/2)+1,:);
              hb4(x*num_blocks(2)+y+1,:) = hog_blocks4(mod(y,4)+1,floor(y/4)+1,mod(x,4)+1,floor(x/4)+1,:);
          end
       end
       hog_blocks_reference = [hb1 hb2 hb4];
   end

   % Trim the blocks to the new size
   hog_blocks1 = hog_blocks1(  1:num_blocks(2)    ,1:num_blocks(1)  ,:);
   hog_blocks2 = hog_blocks2(:,1:num_blocks(2)/2,:,1:num_blocks(1)/2,:);
   hog_blocks4 = hog_blocks4(:,1:num_blocks(2)/4,:,1:num_blocks(1)/4,:);


   g_hog_blocks = [reshape(hog_blocks1,[],size(hog_blocks1,3)) reshape(hog_blocks2,[],size(hog_blocks2,5)) reshape(hog_blocks4,[],size(hog_blocks4,5))];


   if config.DEBUG>10
       assert(isequal(g_hog_blocks, hog_blocks_reference));
   end
end

end

function [num_blocks,g_hog_blocks]=hog2features_internal(hog_c,patch_dims,config)

cell_size = config.HOG_CELL_DIMS./config.NUM_HOG_BINS;
block_size = patch_dims(2:-1:1)./cell_size(1:2);
hog_block_size = block_size-1;

[H,W,hog_hog_len] = size(hog_c);

num_blocks = max(0,[W H] - hog_block_size + 1);

block_hog_len = hog_hog_len*prod(hog_block_size);

% String them into blocks
num_num_blocks = prod(num_blocks);
g_hog_blocks = zeros(num_num_blocks,block_hog_len,'single');

if num_num_blocks>0
    for x=0:hog_block_size(1)-1
       for y=0:hog_block_size(2)-1
            g_hog_blocks(:,(x*hog_block_size(2)+y)*hog_hog_len+(1:hog_hog_len)) = reshape(hog_c(y+(1:num_blocks(2)),x+(1:num_blocks(1)),:),[num_num_blocks hog_hog_len]);
       end
    end

    % Reference implementation. Slow but more readable version that must
    % produce the same result as the real one
    if 0
        hog_blocks1 = zeros(num_num_blocks,block_hog_len,'single');
        for x=0:num_blocks(1)-1
            for y=0:num_blocks(2)-1
              hog_features=[];
              for xx=0:hog_block_size(1)-1
                   for yy=0:hog_block_size(2)-1
                        hog_features = [hog_features reshape(hog_c(y+yy+1,x+xx+1,:),[1 hog_hog_len])]; %#ok<AGROW>
                   end
              end
              hog_blocks1(x*num_blocks(2)+y+1,:) = hog_features;
            end
        end
        assert(isequal(g_hog_blocks,hog_blocks1));
    end
end
end
