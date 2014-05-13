function [ap,oldap,prec,recall] = compute_pascal_ap(datasetname, filename)
addpath /home/lubomir/poselets/data/VOCcode;
id='comp4';
cls='person';
VOCopts = VOCinit_custom(datasetname,'trainval','test');
if exist('filename','var')
    copyfile(filename, sprintf(VOCopts.detrespath,id,cls));
end
[recall,prec,ap] = VOCevaldet(VOCopts,id,cls,false);
oldap = VOCold_ap(recall,prec);
fprintf('ap=%4.2f%%  oldap=%4.2f%%\n',ap*100,oldap*100);
end
