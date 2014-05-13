function rose_fill(theta, bins_ctr, color)

if nargin<2
    nbins = 12;
    bins_ctr = linspace(0,2*pi,nbins+1); bins_ctr(end)=[];
end
if nargin<3
    color = 'r';
end

h = rose(theta, bins_ctr);
x = get(h, 'XData');
y = get(h, 'YData');
p = patch(x, y, 'r');