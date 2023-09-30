function [GAo,GMo,GSo] = fillStat(GAi,GMi,GSi,method,varargin)
%function statOut = fillStat(statIn,method,varargin)

GAo = GAi;
GMo = GMi;
GSo = GSi;

indg1  = find(GMi~=0);
indg1n = setdiff(1:numel(GMi),indg1);

switch method
    case 'wmean'
        GAo(indg1n) = mean(GAi(indg1));
        GMo(indg1n) = mean(GMi(indg1));
        GSo(indg1n) = mean(GSi(indg1));
        tmpA    = imgaussfilt(GAo,1);
        scaleA = GAo(indg1)./tmpA(indg1);
        tmpM    = imgaussfilt(GMo,1);
        scaleM = GMo(indg1)./tmpM(indg1);
        tmpS    = imgaussfilt(GSo,1);
        scaleS = GSo(indg1)./tmpS(indg1);
        GAo = tmpA*quantile(scaleA(:),1);        
        GMo = tmpM*quantile(scaleM(:),1);        
        GSo = tmpS*mean(scaleS(:)); 
    case 'mean'
        GAo(indg1n) = mean(unique(GAi(indg1)));
        GMo(indg1n) = mean(unique(GMi(indg1)));
        GSo(indg1n) = mean(unique(GSi(indg1)));
        tmpA    = imgaussfilt(GAo,1);
        scaleA = GAo(indg1)./tmpA(indg1);
        tmpM    = imgaussfilt(GMo,1);
        scaleM = GMo(indg1)./tmpM(indg1);
        tmpS    = imgaussfilt(GSo,1);
        scaleS = GSo(indg1)./tmpS(indg1);
        GAo = tmpA*quantile(scaleA(:),1);        
        GMo = tmpM*quantile(scaleM(:),1);        
        GSo = tmpS*mean(scaleS(:)); 
    case 'quantile'
        methodq = varargin{1};
        GAo(indg1n) = mean(unique(GAi(indg1)));
        GMo(indg1n) = quantile(unique(abs(GMi(indg1))),methodq)*sign(mean(GMi(indg1)));
        GSo(indg1n) = mean(unique(GSi(indg1)));
        tmpA    = imgaussfilt(GAo,1);
        scaleA = GAo(indg1)./tmpA(indg1);
        tmpM    = imgaussfilt(GMo,1);
        scaleM = GMo(indg1)./tmpM(indg1);
        tmpS    = imgaussfilt(GSo,1);
        scaleS = GSo(indg1)./tmpS(indg1);
        GAo = tmpA*mean(scaleA(:));        
        GMo = tmpM*quantile(scaleM(:),1);        
        GSo = tmpS*mean(scaleS(:)); 
    case 'const_mean'
        GAo = GAi*0+mean(unique(GAi(indg1)));
        GMo = GMi*0+mean(unique(GMi(indg1)));
        GSo = GSi*0+mean(unique(GSi(indg1)));
    case 'const_med'
        GAo = GAi*0+median(unique(GAi(indg1)));
        GMo = GMi*0+median(unique(GMi(indg1)));
        GSo = GSi*0+median(unique(GSi(indg1)));
    case 'const_max'
        GAo = GAi*0+mean(unique(GAi(indg1)));
        GMo = GMi*0+quantile(unique(abs(GMi(indg1))),0.95)*sign(mean(GMi(indg1)));
        GSo = GSi*0+mean(unique(GSi(indg1)));
    case 'const_q'
        methodq = varargin{1};
        GAo = GAi*0+mean(unique(GAi(indg1)));
        GMo = GMi*0+quantile(unique(abs(GMi(indg1))),methodq)*sign(mean(GMi(indg1)));
        GSo = GSi*0+quantile(unique(abs(GSi(indg1))),methodq);
        GSo = GSi*0+mean(unique(GSi(indg1)));
    case 'invdist'
        error('invdist interpolation not supported in HSBA')
end  

