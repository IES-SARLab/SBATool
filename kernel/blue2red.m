function cmap = blue2red(steps); 
%function cmap = blue2red(steps); 

marks = [  0   0 255;...
         255 255 255;...
         255   0   0];

segmark = linspace(1,steps,size(marks,1));


segr = interp1(segmark,marks(:,1),1:steps)';
segg = interp1(segmark,marks(:,2),1:steps)';
segb = interp1(segmark,marks(:,3),1:steps)';

cmap = [segr segg segb]/255;
