function [tlistfinallow,tlistfinalhigh] = getFinalTsize(config);
%function [tlistfinallow,tlistfinalhigh] = getFinalTsize(config);
%
% Get the final tsizes for change detections with the following priority:
%    1. tlistfinallow and tlistfinalhigh in config file (can be more than 1)
%    2. tlistlowplot and tlisthighplot in config file (will choose only the middle one)
%    3. 09_tlistlowplot.txt and 09_tlisthighplot.txt (will choose only the middle one)

qcdir =  [config('projdir') config('qcdir')];
Rklow  = config('Rkfinallow'); 
Rkhigh = config('Rkfinalhigh'); 

if isKey(config,'tlistfinallow')
    tlistfinallow  = eval(config('tlistfinallow'));
else
    if isKey(config,'tlistlowplot')
        tlistlow = eval(config('tlistlowplot'));
    else
        if exist(sprintf('%s/09_tlistlowplot.txt',qcdir),'file')
            tlistlow = load(sprintf('%s/09_tlistlowplot.txt',qcdir));
        else %hsba
            tlistlow = nan;
        end
    end
    if ~isnan(tlistlow)
        switch Rklow
            case 'high'
                tlistfinallow = tlistlow(1);
            case 'low'
                tlistfinallow = tlistlow(3);
            otherwise %med
                tlistfinallow = tlistlow(2);
        end
    else
        tlistfinallow = nan;
    end
end
if isKey(config,'tlistfinalhigh')
    tlistfinalhigh = eval(config('tlistfinalhigh'));
else
    if isKey(config,'tlisthighplot')
        tlisthigh = eval(config('tlisthighplot'));
    else
        if exist(sprintf('%s/09_tlisthighplot.txt',qcdir),'file')
            tlisthigh = load(sprintf('%s/09_tlisthighplot.txt',qcdir));
        else %hsba
            tlisthigh = nan;
        end
    end
    if ~isnan(tlisthigh)
        switch Rkhigh
            case 'high'
                tlistfinalhigh = tlisthigh(1);
            case 'low'
                tlistfinalhigh = tlisthigh(3);
            otherwise %med
                tlistfinalhigh = tlisthigh(2);
        end
    else
        tlistfinalhigh = nan;
    end
end

