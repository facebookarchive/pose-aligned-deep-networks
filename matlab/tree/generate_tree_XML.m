%%
 %  Copyright (c) 2014, Facebook, Inc.
 %  All rights reserved.
 %
 %  This source code is licensed under the BSD-style license found in the
 %  LICENSE file in the root directory of this source tree. An additional grant 
 %  of patent rights can be found in the PATENTS file in the same directory.
 %
 %%
function  generate_tree_XML(filename, rootArray)
% generate_tree_XML(filename, rootArray)
% rootArray is a cell array of trees, one for each aspect ratio.
% XML format
%<stage_classifiers>
%<aspect w="96" h="64">
%  <stage_classifier id="0" offset="0">
%      <weights>
% 1.2 3.2 -4.3 ...
%      </weights>
%      <next>
% 1 -2 -6 -12
%      </next>
%  </stage_classifier>
%
% Convention: 
%  - each aspect has a whole list of classifiers, 
%  -id starts from 0, offset starts from 0 (first stripe), 
%  -length of weights is
% hogbins x width + 2 where the first hogbins x width is the hyperplane, the next one is the weight of the context and 
% the last one is the bias
% weights are listed in row major order, so the innermost loop is the
% hogbins
%  -next contains a list of ids of next classifiers to evaluate, if the number is negative it means actual poselets
% the poselet ids start from *-1* and go to *-150* 
    asp_N = length(rootArray);
    fid = fopen(filename, 'w'); 
    if isempty(fid), error('Can''t open file %s\n', filename); end
    fprintf(fid, '<?xml version="1.0" encoding="utf-8"?>\n');
    fprintf(fid, '<stage_classifiers>\n');
    for asp_I = 1:asp_N
        generate_XML_per_aspect(rootArray(asp_I), fid); 
    end
    fprintf(fid, '</stage_classifiers>\n');
    fclose(fid);    
end

function generate_XML_per_aspect(root, fid)
    nodeArray = collect_nodes(root, struct('node',[],'parent',0),0);
    nodeArray = nodeArray(2:end);
    parent = [nodeArray(:).parent];
    t = nodeArray(1).node;
    fprintf(fid, '<aspect w="%d" h="%d" num_initial="%d">\n', t.bin_dims(2), t.bin_dims(1), sum(parent==1));
    
    for i=1:length(parent) % skip root node
        t = nodeArray(i).node;
        % print weights
        fprintf(fid, '\t<stage_classifier id="%d" offset="%d">\n', i-1, t.stripe_id-1);
        fprintf(fid, '\t\t<weights>\n');
        % need to flip dimensions
        w = t.weights;
        assert(length(w) == t.bin_dims(2)*36 + 2);
        fprintf(fid, '%s\n', num2str([w(1:end)], '%.7f '));
        fprintf(fid, '\t\t</weights>\n');
        % print next classifier ids/pids
        children = find(parent==i) - 1;
        if isempty(children), children = -t.pids; end
        fprintf(fid, '\t\t<next>\n');
        fprintf(fid, '%s\n', num2str(children,'%d '));
        fprintf(fid, '\t\t</next>\n');
        fprintf(fid, '\t</stage_classifier>\n');
    end
    fprintf(fid, '</aspect>\n');
end

function nodeArray = collect_nodes(t, nodeArray, myID)
    child_idx = length(nodeArray);
    for i=1:length(t.children)
        child = t.children(i);
        child.children = [];
        nodeArray = [nodeArray struct('node', child, 'parent', myID)];
    end
    for i=1:length(t.children)
        nodeArray = collect_nodes(t.children(i), nodeArray, child_idx+i-1);
    end
end
