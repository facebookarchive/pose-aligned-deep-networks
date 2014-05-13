function run_poselets_on_pascal(setname,mode, config)
addpath poselet_detection;
addpath ../poselet_detection;

root = '~lubomir/poselets/data';

fid = fopen(sprintf('%s/test%s.txt',root,setname),'r');
imgnames = textscan(fid,'%s');
fclose(fid);
imgnames = imgnames{1};

result_dir = sprintf('%s/results%s%s',root,setname,mode);
if ~exist(result_dir,'file')
  mkdir(result_dir);
  system(sprintf('chmod 777 %s',result_dir));
end

qqq = load('../data/person/model.mat');
model = qqq.model;
clear qqq;

tic;
parfor i=1:length(imgnames)
   disp(imgnames{i});
   savename=sprintf('%s/%s.mat', result_dir, imgnames{i});
   if exist(savename,'file')
     qqq=load(savename);
     bounds_predictions{i}=qqq.x;
     disp('loaded');
   else
     img = imread(sprintf('%s/VOC%s/JPEGImages/%s.jpg',root,setname,imgnames{i}));
     bounds_predictions{i}=detect_objects_in_image(img,model,config);
     save1(savename,bounds_predictions{i});
   end
end

toc;
matlabpool('close');
all_filename=sprintf('%s/results%s%s.mat', root, setname,mode);
save(all_filename,'bounds_predictions','imgnames');

%bp=load(all_filename);
%bp=bp.bounds_predictions;
bp=hit_list;
imname = {};
for i=1:length(bounds_predictions)
  bp=bp.append(bounds_predictions{i});
  imname = [imname; repmat(imgnames(i),bounds_predictions{i}.size,1)];
end

[~,srtd] = sort(-bp.score);
bp=bp.select(srtd);
imname=imname(srtd);

bounds = round(bp.bounds);
bounds(3:4,:) = bounds(3:4,:) + bounds(1:2,:);

results_filename = [result_dir '/comp4_det_test_person.txt'];
fid = fopen(results_filename,'w');
for i=1:bp.size
  fprintf(fid,'%s %6.3f %d %d %d %d\n', imname{i}, bp.score(i), bounds(:,i));
end
fclose(fid);

ap=compute_pascal_ap(['VOC' setname], results_filename);
fprintf('ap=%4.2f\n', ap*100);

end


function save1(filename,x)
  save(filename,'x');
end
