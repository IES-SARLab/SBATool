function pboth = getPboth(plow,phigh,FPMboth)
%function pboth = getPboth(plow,phigh,FPMboth)
%
% plow,phigh both in percentage

pboth = max(plow,phigh);
pboth1 = pboth;
pboth2 = pboth;
rmask  = randi([-45 0],size(pboth,1),size(pboth,2));
rmask(FPMboth~=0)=0;
pboth1(FPMboth==0)=0;
pboth2(FPMboth~=0)=0;
pboth2 = pboth2*0.75;
%pboth2(pboth2>=50)=45;
%pboth2 = pboth2+rmask;
pboth2 = imgaussfilt(pboth2,1);
pboth2(FPMboth~=0)=0;
pboth = pboth1+pboth2;
        
