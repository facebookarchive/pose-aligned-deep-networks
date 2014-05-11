%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function describe_people(config, data, scores)

N = length(data.test_idx);
N_ATTR = length(config.ATTR_NAME);
assert(length(scores{1}) == N);
assert(length(scores) == N_ATTR);

norm_scores = zeros(N, length(scores));

for attr_id=1:N_ATTR
    norm_scores(:,attr_id) = 1./(1+exp(-scores{attr_id}));
end

CONF_THRESH = 0.8;
for attr_id=1:N_ATTR
    idx = data.attr_labels(data.test_idx,attr_id)~=0;
    lab = (data.attr_labels(data.test_idx(idx),attr_id)>0);
    sc = norm_scores(idx,attr_id);
    [sc,srtd] = sort(sc,'descend');
    lab=lab(srtd);
    conf_thresh1 = get_confidence_thresh(sc, lab, CONF_THRESH);
    sc=sc(end:-1:1);
    lab=~lab(end:-1:1);
    conf_thresh2 = get_confidence_thresh(sc, lab, CONF_THRESH);

    uncertain = norm_scores(:,attr_id) < conf_thresh1;
    fprintf('Removing %4.2f%% of attributes %s\n', mean(uncertain)*100, config.ATTR_NAME{attr_id});
    norm_scores(uncertain,attr_id) = nan;
end

%attr_names = cell(N_ATTR,2);
% attr_names{1}={'male','female'};
% attr_names{2}={'long hair','short hair'};
% attr_names{3}={'wears hat','has no hat'};
% attr_names{4}={'wears glasses','wears no glasses'};
% attr_names{5}={'wears a dress','wears no dress'};
% attr_names{6}={'wears sunglasses','wears no sunglasses'};
% attr_names{7}={'wears short sleeves','wears long sleeves'};
% attr_names{8}={'is a baby','is not a baby'};
% attr_names{9}={'is younger than 12','is older than 12'};
% attr_names{10}={'is older than 60','is younger than 60'};
% attr_names{11}={'is asian','is not asian'};
% attr_names{12}={'is black','is not black'};
% attr_names{13}={'is white','is not white'};
% attr_names{14}={'is indian','is not indian'};
% attr_names{15}={'is hispanic','is not hispanic'};
% attr_names{16}={'is bald','is not bald'};
% attr_names{17}={'is blonde','is not blonde'};
% attr_names{18}={'is brunette','is not brunette'};
% attr_names{19}={'has white hair','does not have white hair'};
% attr_names{20}={'has formal wear','does not have formal wear'};
% attr_names{21}={'wears a t-shirt','does not wear a t-shirt'};
% attr_names{22}={'wears shorts','does not wear shorts'};
% attr_names{23}={'wears jeans','does not wear jeans'};
% attr_names{24}={'wears plaid','does not wear plaid'};
% attr_names{25}={'wears a jacket','does not wear a jacket'};
% attr_names{26}={'wears a collared shirt','does not wear a collared shirt'};
% attr_names{27}={'is smiling','is not smiling'};
% attr_names{28}={'is running','is not running'};
% attr_names{29}={'is walking','is not walking'};
% attr_names{30}={'is sitting','is not sitting'};

thresh = 0.5;
DISPLAY = 1;

if ~DISPLAY
    fid = fopen('descriptions.txt','w');
end
i = 1;
while (true)
  if DISPLAY
    imshow(load_image(data.ohits.image_id(data.test_idx(i)),config));
    hit=scale_hits(data.ohits.select(data.test_idx(i)),2);
    rectangle('position',hit.bounds,'edgecolor','r','linewidth',3);
  end

   % Age and gender
   str = [];
   if norm_scores(i,8) > thresh
       str = 'baby';
   else
       if norm_scores(i,1) < thresh
          if norm_scores(i,9) > thresh
             str = 'girl';
          elseif norm_scores(i,9) < 1-thresh
             str = 'woman';
          else
             str = 'female';
          end
       elseif norm_scores(i,1) > 1-thresh
          if norm_scores(i,9) > thresh
             str = 'boy';
          elseif norm_scores(i,9) < 1-thresh
             str = 'man';
          else
             str = 'male';
          end
       else
           str = 'person';
       end
   end
   if norm_scores(i,10) > thresh
      str = ['elder ' str];
   end

   % Hair color
   idx = [16 17 18 19];
   conf = max(norm_scores(i, idx));
   if conf > thresh
       max_idx = find(norm_scores(i, idx) == conf, 1);
       desc = {'balding','blonde','brunette','white-haired'};
       str = [desc{max_idx} ' ' str];
   end

   % Race
   idx = [11 12 13 14 15];
   conf = max(norm_scores(i, idx));
   if conf > thresh
       max_idx = find(norm_scores(i, idx) == conf, 1);
       desc = {'asian','black','white','indian','hispanic'};
       str = [desc{max_idx} ' ' str];
   end

   % Pose
   idx = [28 29 30];
   conf = max(norm_scores(i, idx));
   if conf > thresh
       max_idx = find(norm_scores(i, idx) == conf, 1);
       desc = {'running','walking','sitting'};
       str = [desc{max_idx} ' ' str];
   end

   attr={};
   attr_sc=[];

   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 2) , thresh, {'long hair','short hair'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 3) , thresh, {'hat','no hat'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 27) , thresh, {'smiling','serious'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, [4 6]) , thresh, {'glasses','sunglasses'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, [7 25]) , thresh, {'short sleeves','jacket'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, [21 26]) , thresh, {'t-shirt','collared shirt'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 20) , thresh, {'formal wear','casual wear'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 22) , thresh, {'shorts','not shorts'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 24) , thresh, {'plaid'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 5) , thresh, {'dress'});
   [attr, attr_sc] = add_attribute(attr, attr_sc, norm_scores(i, 23) , thresh, {'jeans'});

   if ~isempty(attr)
      str = [str ' with '];
      if length(attr)>1
          [srt, srtd] = sort(attr_sc,'descend');
          attr = attr(srtd);
          attr{end} = ['and ' attr{end}];
      end
      for j=1:length(attr)
         str = [str attr{j} ','];
      end
   end
   if DISPLAY
	   title(sprintf('%d %s',i,str));
       while 1
          [~,~,ch] = ginput(1);
          if isscalar(ch)
             break;
          end
       end
       switch ch
           case 27
               return;
           case 29 % ->
               if i<N
                   i=i+1;
               end
           case 28 % <-
               if i>1
                   i=i-1;
               end
           case 'g'
               answer = str2double(inputdlg('Enter index:'));
               if ~isempty(answer)
                  answer = round(answer);
                  if answer>0
                     i = max(1, min(N, answer));
                  end
               end
       end
   else
      fprintf(fid, '%d %s\n',i,str);
      i=i+1;
      if i==N+1
         break;
      end
   end

end
if ~DISPLAY
    fclose(fid);
end
end

function [attr, attr_sc] = add_attribute(attr, attr_sc, score, thresh, name)
    if length(score)>1
        % multiple attributes
        conf = max(score);
        if conf > thresh
           max_idx = find(score == conf, 1);
           attr{end+1} = name{max_idx};
           attr_sc(end+1) = conf;
        end
    else
        % single attribute
       if score > thresh
           attr{end+1} = name{1};
           attr_sc(end+1) = score;
       elseif length(name)>1 && score < 1-thresh
          attr{end+1} = name{2};
          attr_sc(end+1) = 1-score;
       end
    end
end
