function [flist,plist] = readFinal(config); 

qcdir  = [config('projdir') config('qcdir')];
fpmdir = [config('projdir') config('fpmdir')];
prefix = config('prefix');
eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
methodlow = config('methodlow');
methodstr = methodlow;
if strcmp(methodlow,'quantile')||strcmp(methodlow,'const_q')
    methodq = eval(config('methodlowq'));
    methodstr = sprintf('%s%0.2f',methodlow,methodq);
end
bwp1low  = initBWarea(eventImg,config,'minpatchlow');
bwp1high = initBWarea(eventImg,config,'minpatchhigh');
dosmode = eval(config('dosmode'));

flist{1} = sprintf('%s/%s_clstX_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
pat1 = '_bw(\d*)_(\d*).';
fparts = regexp(flist{1}, pat1, 'split');
plist{1} = sprintf('%s_prob.tif',fparts{1});
if dosmode 
    flist{2} = sprintf('%s/%s_clstX_smode_%s_bw%d_%d.tif',fpmdir,prefix,methodstr,bwp1low,bwp1high);
    plist{2} = plist{1}; %Not correct yet; need to calculate this prob. later
end

%ffinal = sprintf('%s/finalfile_%s_bw%d_%d.txt',qcdir,methodstr,bwp1low,bwp1high);
%fnames = textread(ffinal,'%s'); 
%if exist(ffinal,'file')
%    pat1 = '_lo(\d*)_';
%    tok1 = regexp(fnames{1}, pat1, 'tokens');
%    tsizel = str2num(tok1{1}{1});
%    pat2 = '_hi(\d*)_';
%    tok2 = regexp(fnames{2}, pat2, 'tokens');
%    tsizeh = str2num(tok2{1}{1});
%end
