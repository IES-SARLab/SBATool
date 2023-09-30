function cmap = blueyellowred(steps); 
%function cmap = blueyellowred(steps); 

marks = [ 43 131 186;...
         171 221 164;...
         255 255 191;...
         253 174  97;...
         215  25  28];

segmark = linspace(1,steps,size(marks,1));


segr = interp1(segmark,marks(:,1),1:steps)';
segg = interp1(segmark,marks(:,2),1:steps)';
segb = interp1(segmark,marks(:,3),1:steps)';

cmap = [segr segg segb]/255;
