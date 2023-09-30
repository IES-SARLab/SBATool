%%%% Load universal parameters from config.txt

% load all default parameters
config = text2dict('sba.config');

% load non-default parameters
configusr = text2dict(fconfig);
usrkeys   = keys(configusr);

for ii=1:numel(usrkeys)
    config(usrkeys{ii}) = configusr(usrkeys{ii});
end

npool  = eval(config('npool'));
if npool>1; doparallel=1; else; doparallel=0; end

fpmdir =  [config('projdir') config('fpmdir')];
qcdir  =  [config('projdir') config('qcdir')];
valdir  = [config('projdir') config('valdir')];

if ~exist(fpmdir,'dir')
  mkdir(fpmdir);
end
if ~exist(qcdir,'dir')
  mkdir(qcdir);
end
if ~exist(valdir,'dir')
  mkdir(valdir);
end

inpZmap = config('filename');
[~,prefix,fext] = fileparts(inpZmap);
config('prefix')=prefix;

filtwin = eval(config('filtwin'));
dolee   = eval(config('dolee'));
usemask = eval(config('usemask'));
dosplit = eval(config('dosplit'));
docluster = eval(config('docluster'));
dohandem  = eval(config('dohandem'));
ct      = eval(config('changetype'));
if ~((ct==0)|(ct==1)|(ct==3))
   error('changetype can only be 1 (Z-), 3 (Z+) or 0 (both)!')
end

method    = config('methodlow');
methodstr = method; 
if strcmp(method,'quantile')||strcmp(method,'const_q')
    methodq = eval(config('methodlowq'));
    methodstr = sprintf('%s%0.2f',method,methodq);
end
method2 = config('methodhigh');
methodstr2 = method2; 
if strcmp(method2,'quantile')||strcmp(method2,'const_q')
    methodq2 = eval(config('methodhighq'));
    methodstr2 = sprintf('%s%0.2f',method2,methodq2);
end

