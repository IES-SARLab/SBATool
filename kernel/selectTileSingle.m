function [C1ts,C2ts] = selectTileSingle(BCt,C1t,C2t,thresh); 
%function [C1ts,C2ts] = selectTileSingle(BCt,C1t,C2t,thresh); 

C1ts = C1t;
C2ts = C2t;
%         BC   C1lower C1upper C2lower C2upper
%theshG  =[.950 -6      -1      1       6]  % for single mode
ind1 = find(  BCt>=thresh(1) & ...
              C1t>=thresh(2) & ...
              C1t<=thresh(3) );
ind2 = find(  BCt>=thresh(1) & ...
              C2t>=thresh(4) & ...
              C2t<=thresh(5) );
C1ts(setdiff(1:numel(C1t),ind1)) = 0;
C2ts(setdiff(1:numel(C2t),ind2)) = 0;
