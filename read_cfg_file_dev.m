% update infofile 

function [acc_nb_frames]=read_cfg_file(filename)

vdefault='NaN';

fp=fopen(filename,'r');
if fp ~= -1 % *.info exists
    hd=fscanf(fp,'%c');
    fclose(fp);
    fp=fopen(filename,'r');
    C=textscan(fp,'%s');
    cfglist=C{1};
    fclose(fp);
    
   Index = find(strcmp(cfglist, 'ccd_acq_mode'), 1);
    if ~isempty(Index);
        Index2=Index+1;
        ccd_acq_mode=C{1}{Index2};
        
    else	% what is not in header
         ccd_acq_mode= [];
    end
    
   Index = find(strcmp(cfglist, 'acc_nb_frames'), 1);
    if ~isempty(Index);
        Index2=Index+1;
        res=C{1}{Index2};
        
    else	% what is not in header
        res= 1;
    end  
    acc_nb_frames=res;
end

end