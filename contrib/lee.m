function f = lee(g, nhood, niterations)
%
%Christos Loizou 2001
%Adaptive SPECKLE REDUCTION  FILTER. lemv_lee
%Eliminates noise while preserving edges and point featres in radar imagery
%It is based on the linear speckle noise model and the minimum mean square error
%(MMSE) design approach, the filter produces the enhaced data according to 
%  Is = Imean + Ks (Is-Imean).
%Date: 	4/10/2001
%Source: IEEE Transactions on Image processing 
%Yongjian Yu and Scott T. Acton, 2001
%Title: Speckle Reducing Anistropic diffusion
%Utilizes the local statistics of the noise image g(m,n )
%Example: fout = lee(a, [5 5], 3);


if isa(g, 'uint8')
  u8out = 1;
  if (islogical(g))
    % It doesn't make much sense to pass a binary image
    % in to this function, but just in case.
    logicalOut = 1;
    g = double(g);
  else
    logicalOut = 0;  
    g = double(g)/255;    
  end
else
  u8out = 0;
end

%Calculate the noise and the noise variance in the image 
%noise=noisevar(z, nhood, ma, na, g);
stdnoise=(std2(g).*std2(g))/mean2(g);
noisevar=stdnoise; %noise variance 
% stdnoise=std2(g)/mean2(g);
% noisevar=stdnoise*stdnoise; %noise variance = s*s/ m*m;

%Initialize the picture f (new picture) with zeros
f = g;

for i = 1:niterations           %Apply niteration of the algorithm to the image 
  % fprintf('\rIteration %d',i);
  if i >=2 
      g=f;
  end
  
%Estimate the local mean of f.
localMean = filter2(ones(nhood), g) / prod(nhood);

%Estimate of the weight coeficient
localVar = filter2(ones(nhood), g.^2) / prod(nhood) - localMean.^2;
cs = localVar ./ max(0.000000001, localMean.^2);


k = max(0, 1 - (noisevar./max(0.0000000001, cs)));

%Compute new image f from noise image g
f= localMean + (g - localMean) .* k ; 

end %end for i Itterations 
% fprintf('\n');

%Create and open a file for writing the statistics of the image before/after filtering
%which are calculated in statistics function 
%fid=fopen('C:\Documents and Settings\Phedra Georgiou\Desktop\images\addnoisefilter.txt','w');
%fid=fopen('addnoisefilter.txt','w');
%fprintf(fid, 'SPECKLE FILTERING BY ADDNOISEFILTER WITH NR OF ITTERATIONS:     %3.1f\n',  niterations );
%fprintf(fid, '====================================================================== \n');

%statistics(g, f, ma, na, fid);
%fclose(fid)  % close file after writing the statistics

if u8out==1,
  if (logicalOut)
    f = uint8(f);
  else
    f = uint8(round(f*255));
  end
end
%f=f./255;
%Calculate 56 texture features for the filtered image
%TAM=texfeat(double(f));
%F1=[F1,TAM'];
%save addnoisetexfs F1;


% figure, imshow(f);
% title('Image filtered by lee filter');
