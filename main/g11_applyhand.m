function g11_applyhand(fconfig,varargin)
%function g11_applyhand(fconfig,[inputfile])
% Apply hand to the detection result;
% pixels with handem values less than the threshold will be multiplied by -1
% 
%   fconfig: user-specified configuration file
% inputfile: user-selected input change detection file to
%            execute handem masking
%
% If 'inputfile' is not specified, the script will locate the
%    files listed in ./qc/finalfile.txt to execute handem masking
%
% NinaLin@2023

loadparam;
dosmode  = eval(config('dosmode'));
methodlow = config('methodlow');
eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
bwp1low  = initBWarea(eventImg,config,'minpatchlow');
bwp1high = initBWarea(eventImg,config,'minpatchhigh');

handthresh = eval(config('handthresh'));
if numel(handthresh)~=2
    error('Error in handthresh! Exit without applying handem.');
end
if handthresh(1)==handthresh(2)
    error('Error in handthresh! Exit without applying handem.');
end

if isnan(handthresh(2))
    boundtype = 1;  % keep values below
elseif isnan(handthresh(1))
    boundtype = 2;  % keep values above
else 
    boundtype = 0;  % keep values in between
end

if numel(varargin)>0
    fpmfilelist{1} = varargin{1};
else
    fpmfilelist=readFinal(config);
end
    
for ii=1:numel(fpmfilelist)

    fpmfile = fpmfilelist{ii};
    
    if ~exist(fpmfile,'file')
        fprintf(1,'File %s does not exist. Skip this file.\n',fpmfile)
        continue;
    end        

    lookRk  = initLook(fpmfile,config,'lookRk');
    fprintf(1,sprintf('Apply HANDEM on %s\n',fpmfile));
    [patch1,X,Y,info] = readRaster(fpmfile);
    handfile = dir(sprintf('%s_hand.*',prefix));
    if numel(handfile) == 0
        error('Cannot find HANDEM file in the current folder!');
    end
    if numel(handfile) > 1
        error(1,'Multiple HANDEM files detected! Please leave only one in the working folder.')
    end
    auxhand  = readRaster(handfile.name);
    if mean(diff(X))>1 
        ctype = 2;  %projected
    else
        ctype = 1;  %geographic 
    end
    if numel(auxhand)~=numel(patch1)
        error('The change file and handem file do not have some dimensions!');
    end
   
    [fpath,fname,fext]=fileparts(fpmfile);
    if boundtype==1
        outname  = sprintf('%s/%s_hand%d_%s.tif',fpmdir,prefix,handthresh(1),fname(numel(prefix)+2:end));
        qcfigname= sprintf('%s/11_hand%d_%s.png',qcdir,handthresh(1),fname(numel(prefix)+2:end));
        handmask = (auxhand>handthresh(1));  % remove pixels above thresh
    elseif boundtype==2
        outname  = sprintf('%s/%s_hand%d_%s.tif',fpmdir,prefix,handthresh(2),fname(numel(prefix)+2:end));
        qcfigname= sprintf('%s/11_hand%d_%s.png',qcdir,handthresh(2),fname(numel(prefix)+2:end));
        handmask = (auxhand<handthresh(2));  % remove pixels below thresh
    else
        outname = sprintf('%s/%s_hand%d-%d_%s.tif',fpmdir,prefix,handthresh(1),handthresh(2),fname(numel(prefix)+2:end));
        qcfigname= sprintf('%s/11_hand%d-%d_%s.png',qcdir,handthresh(1),handthresh(2),fname(numel(prefix)+2:end));
        handmask = (auxhand<handthresh(1))+(auxhand>handthresh(2));  % remove pixels above and below thresh
    end

   
    patch1r1 = patch1;
    patch1r1(handmask)=patch1(handmask)*0; % negative for unwanted
    mat2geotiff(patch1r1,X,Y,outname,'geotiff',ctype,16,[],info)
    fprintf(1,sprintf('Output to %s\n',outname));

    % Ignore downlooking cause it takes long time
    %patch1LK  = LookDown(patch1,   lookRk, lookRk, 'mode');
    %patch1r1LK = LookDown(patch1r1,lookRk, lookRk, 'mode');

    patch1LK   = patch1;
    patch1r1LK = patch1r1;
    
    figure('rend','painters','pos',[100 100 800 400]); 
    gap = [.02 .05];
    marg_h = [.08 .08];
    marg_w = [.08 .05];

    tight_subplot(1,2,1,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(patch1LK,'AlphaData',(patch1LK~=0));
    colormap(gca,'jet');
    if mod(ii,3)==1
        title('Nonclustered, Before HANDEM')
    elseif mod(ii,3)==2
        title('Clustered, Before HANDEM')
    elseif mod(ii,3)==0
        title('Large Cluster, Before HANDEM')
    end

    tight_subplot(1,2,2,'gap',gap,'marg_h',marg_h,'marg_w',marg_w);
    imagesc(patch1r1LK,'AlphaData',(patch1r1LK~=0));
    colormap(gca,'jet');
    if mod(ii,3)==1
        title('Nonclustered, After HANDEM')
    elseif mod(ii,3)==2
        title('Clustered, After HANDEM')
    elseif mod(ii,3)==0
        title('Large Cluster, After HANDEM')
    end
    set(gca,'YTickLabel',[])

    print(gcf, qcfigname, '-dpng', '-r300');
end


