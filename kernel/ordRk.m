function [tbond, rkval]=ordRk(tsizelist,Rk,qhigh,qmid,qlow)
%function [tbond, rkval]=ordRk(tsizelist,Rk,qhigh,qmid,qlow)
%
% tbound: the tsizes from the highest Rk to the lowest Rk
%
% Nina @ 2021

tsizelistbk = tsizelist;
tsizelist   = tsizelist(isfinite(Rk));
Rk          = Rk(isfinite(Rk));

if numel(Rk) == 0
    tbond = [];
    rkval = [];
else
    Rk50 = quantile(Rk,qmid);
    Rklow = quantile(Rk,qlow);
    Rkhigh = quantile(Rk,qhigh);
    tchoose = tsizelist( findmin(Rk,Rk50) );
    tbond1  = tsizelist( findmin(Rk,Rklow) );
    tbond2  = tsizelist( findmin(Rk,Rkhigh) );
    tbond   = [tbond2(1) tchoose(end) tbond1(end)];
    rkval   = [Rk(tsizelist==tbond(1)) Rk(tsizelist==tbond(2)) Rk(tsizelist==tbond(3))];
end
