function [CSI,ACC,Fscore,Kappa,TPR,FPR,valout] = getValMetrics(pFboth,val)
%function [CSI,ACC,Fscore,Kappa,MCC,valout] = getValMetrics(pFboth,val)
%
% output:
% CSI: critical success index
% ACC: accuracy
% Fscore: F-score
% Kappa:  kappa
% MCC:    Matthew's Correlation Coefficient
% valout: confusion matrix in map view
%         TP= 1, FP=2
%         TN=-1, FN=-2

valout = pFboth*0;
indBelow  = find( pFboth < 0 );
indAbove  = find( pFboth > 0 );
indWithin = find( pFboth == 0 );
indTP     = intersect(find(val==1),[indBelow;indAbove]);
indTN     = intersect(find(val==0),indWithin);
indFP     = intersect(find(val==0),[indBelow;indAbove]);
indFN     = intersect(find(val==1),indWithin);
valout(indTP) =  1;
valout(indTN) = -1;
valout(indFP) =  2;
valout(indFN) = -2;
valout(isnan(pFboth)) = nan;
valout(isnan(val)) = nan;

TP       = numel(indTP);
TN       = numel(indTN);
FP       = numel(indFP);
FN       = numel(indFN);
P        = TP+FN;
N        = FP+TN;
CSI      = TP/(TP+FP+FN);
ACC      = (TP+TN)/(P+N);
TPR      = TP/(TP+FN); %true positive rate
FPR      = FP/(FP+TN); %false positive rate
Po       = ACC;
Pc       = ( ((TP+FN)*(TP+FP))+((TN+FN)*(TN+FP)) )/((P+N)^2);
Kappa    = (Po-Pc)./(1-Pc);
Fscore    = (TP*2)/(TP*2+FP+FN);
MCC      = (TP*TN-FP*FN)/sqrt( (TP+FP)*(TP+FN)*(TN+FP)*(TN+FN) );

