function dict = text2dict(filename)
%function dict = text2Dict(filename)
% scan test file into a dictionary
% 
% Text file format:
% key1 = value1
% key2 = value2
% use '%' to comment lines
%
% use dict.keys to view all the keys
% use dict.values to view all the values
%
% Nina Lin, 28-3-2018


fid = fopen(filename);
A = textscan(fid,'%s %s','Delimiter','=','CommentStyle','%');
fclose(fid);

keys = strtrim(reshape(A{1},[1,size(A{1},1)]));
for ii = 1:numel(A{2})
    B = split(A{2}{ii},'%');
    values{ii} = strtrim(B{1});
end
dict = containers.Map(keys,values);

