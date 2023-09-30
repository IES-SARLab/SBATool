function [GAts,GMts,GSts,varargout] = selectTile(BCt,ADt,SRt,ASt,NIAt,GAt,GMt,GSt,thresh,Gtype,varargin); 
%function [GAts,GMts,GSts,[G2Ats,G2Mts,G2Sts]] = selectTile(BCt,ADt,SRt,ASt,NIAt,GAt,GMt,GSt,thresh,Gtype,[G2At,G2Mt,G2St]); 

doG2 = 0;

if numel(varargin)>0;  G2At = varargin{1}; doG2=1; end
if numel(varargin)>1;  G2Mt = varargin{2}; end
if numel(varargin)>2;  G2St = varargin{3}; end

if (Gtype==1)
    GAts = GAt;
    GMts = GMt;
    GSts = GSt;
    %            AD   BC  SR   AS    M  
    %threshG1  = [1.6 .970 .10 0.005 -1.5];
    ind  = find( (BCt>thresh(2)) & (ADt>thresh(1)) & (SRt>thresh(3)) & (GMt<thresh(5)));
    GAts(setdiff(1:numel(GAt),ind)) = 0;
    GMts(setdiff(1:numel(GMt),ind)) = 0;
    GSts(setdiff(1:numel(GSt),ind)) = 0;
    if doG2
        if numel(varargin)>0; G2Ats=G2At; G2Ats(setdiff(1:numel(G2At),ind))=0; varargout{1}=G2Ats; end
        if numel(varargin)>1; G2Mts=G2Mt; G2Mts(setdiff(1:numel(G2Mt),ind))=0; varargout{2}=G2Mts; end
        if numel(varargin)>2; G2Sts=G2St; G2Sts(setdiff(1:numel(G2St),ind))=0; varargout{3}=G2Sts; end
    end
elseif (Gtype==3)
    GAts = GAt;
    GMts = GMt;
    GSts = GSt;
    %             AD   BC  SR   AS    M  NIA
    %threshG3   = [1.9 .980 .05 0.02  2.5 0.4];
    %              M   SR
    threshG3s  = [2.0 .50]; % for excluding single-bump like result
    ind   = find( ( (ADt>thresh(1)) & (GMt>thresh(5)) ) & ...
                    (BCt>thresh(2))  & ...
                    (SRt>thresh(3)) & ...
                    (ASt>thresh(4)) & ...
                    (NIAt>thresh(6)));
    indG3s  = find( (GMt<threshG3s(1)) & (SRt>=threshG3s(2)) );
    GAts(setdiff(1:numel(GAt),ind)) = 0;
    GMts(setdiff(1:numel(GMt),ind)) = 0;
    GSts(setdiff(1:numel(GSt),ind)) = 0;
    GAts(indG3s) = 0;
    GMts(indG3s) = 0;
    GSts(indG3s) = 0;
    if doG2
        if numel(varargin)>0; G2Ats=G2At; G2Ats(setdiff(1:numel(G2At),ind))=0; G2Ats(indG3s)=0; varargout{1}=G2Ats; end
        if numel(varargin)>1; G2Mts=G2Mt; G2Mts(setdiff(1:numel(G2Mt),ind))=0; G2Mts(indG3s)=0; varargout{2}=G2Mts; end
        if numel(varargin)>2; G2Sts=G2St; G2Sts(setdiff(1:numel(G2St),ind))=0; G2Sts(indG3s)=0; varargout{3}=G2Sts; end
    end
end

