function [maxModeVal,nMaxMode] = nanmode(J,dim,nanval)
%function [maxModeVal,nMaxMode] = nanmode(J,dim,nanval)
% INPUT
% J:      2D matrix
% dim:    dimension to execude mode
% nanval: value defined as NaN
% OUTPUT
% maxModeVal: the value of mode
% nMaxMode:   the frequency of the maxModeVal
%
% Nina Lin @2021


    if dim==1
        for ll = 1:size(J,2)
            [maxModeVal(ll),nMaxMode(ll)] = mode(J(find(J(:,ll)~=nanval),ll));
        end
    elseif dim==2
        for ll = 1:size(J,1)
            [maxModeVal(ll),nMaxMode(ll)] = mode(J(ll,find(J(ll,:)~=nanval)));
        end
    end

end

