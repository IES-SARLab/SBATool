function logging(logfile,cmdstr)
%function logging(logfile,cmdstr)
% logfile: log file name; 1 for screen output only
%          

  if logfile==0
      fprintf(1,sprintf('%s\n',cmdstr));
  else
    if exist(logfile,'file')
        fprintf(1,sprintf('%s\n',cmdstr));
    else  
        fprintf(sprintf('%s\n',cmdstr));
        fid = fopen(logfile,'a');
        fprintf(fid, '%s == %s\n', datestr(now),cmdstr);
        fclose(fid);
    end
  end

end
