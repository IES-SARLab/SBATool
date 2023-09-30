function [GAo,GMo,GSo,varargout] = selectMap(BC,AD,SR,AS,NIA,GA,GM,GS,thresh,Gtype,varargin); 

doG2 = 0;

if numel(varargin)>0;  G2A = varargin{1}; doG2=1; end
if numel(varargin)>1;  G2M = varargin{2}; end
if numel(varargin)>2;  G2S = varargin{3}; end

if (Gtype==1)
    GAo = GA;
    GMo = GM;
    GSo = GS;
    %            AD   BC  SR   AS    M  
    %threshG1  = [1.6 .970 .10 0.005 -1.5];
    ind  = find( (BC>thresh(2)) & (AD>thresh(1)) & (SR>thresh(3)) & (GM<thresh(5)));
    GAo(setdiff(1:numel(GAt),ind)) = 0;
    GMo(setdiff(1:numel(GMt),ind)) = 0;
    GSo(setdiff(1:numel(GSt),ind)) = 0;
    if doG2
        if numel(varargin)>0; G2Ao=G2A; G2Ao(setdiff(1:numel(G2At),ind))=0; varargout{1}=G2Ao; end
        if numel(varargin)>1; G2Mo=G2M; G2Mo(setdiff(1:numel(G2Mt),ind))=0; varargout{2}=G2Mo; end
        if numel(varargin)>2; G2So=G2S; G2So(setdiff(1:numel(G2St),ind))=0; varargout{3}=G2So; end
    end
elseif (Gtype==3)
    GAo = GA;
    GMo = GM;
    GSo = GS;
    %             AD   BC  SR   AS    M  NIA
    %threshG3   = [1.9 .980 .05 0.02  2.5 0.4];
    %              M   SR
    threshG3s  = [2.0 .50]; % for excluding single-bump like result
    ind   = find( ( (AD>thresh(1)) | (GM>thresh(5)) ) & ...
                    (BC>thresh(2))  & ...
                    (SR>thresh(3)) & ...
                    (AS>thresh(4)) & ...
                    (NIA>thresh(6)));
    indG3s  = find( (GM<threshG3s(1)) & (SRt>=threshG3s(2)) );
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

