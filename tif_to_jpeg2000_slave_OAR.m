% that function aims to calculate 3D binning from tif stack, resulting
% in a new 8 bits tif stack, it asks the factor to be used for the binning

% origin Paul Tafforeau, ESRF 09/2007

function tif_to_jpeg2000_slave_OAR(first,last,directory,compression_factor)


if isdeployed
    first=str2num(first)
    last=str2num(last)
    compression_factor=str2num(compression_factor)
end

cd (directory)

cleandirectoryname(pwd)


% selection of all the files having the same radix
d=dir('*.tif');
fname={d.name};
number_of_files=size(d,1);

scan_dir=cleandirectoryname(pwd);
% n2: fileprefix, taken from directory name
pos=findstr(scan_dir,'/');
scan_dir=scan_dir(pos(end)+1:end);

cd ..
voltif_dir=cleandirectoryname(pwd);
resultdir=[voltif_dir '/' scan_dir sprintf('jp2-%1.0i_',compression_factor)];


%%%%%%%%%%%%%%%%%
% create result directory if not-existing
%%%%%%%%%%%%%%%%%
newdirectory=isempty(what(resultdir));
if newdirectory
    unix(sprintf('mkdir %s',resultdir))
    stat = 1;
    if stat
        disp(sprintf('New directory %s created successfully',resultdir))
        unix(sprintf('chmod 777 %s',resultdir));
    else
        disp('Problems creating new directory, permissions ???')
        return % EXITING PROGRAM !!!
    end
end
 

cd (directory)

%%


for i=first:last
    
    disp(sprintf('processing slice %1.0f',i));
    
    slice_name=sprintf(fname{i});
    slice=imread(slice_name);
    final_slice_name=[resultdir '/' slice_name(1:end-3) 'jp2'];
    
    imwrite(slice,final_slice_name,'CompressionRatio',compression_factor);
    
    
end

if last>=number_of_files 
    dinfo=dir(['reconstruction_log.info']);
    infoname={dinfo.name};
    
    if size(infoname,1)>0
        infoname=infoname{1};
        
        fp=fopen(infoname,'r');
        if fp~=-1 % *.info exists
            hd=fscanf(fp,'%c');
            fclose(fp);     
        end
        
    else
        
        hd=[];
        
    end

    file=hd;
    file=[file sprintf('tif_to_jpeg2000_slave_OAR\n')]; 
    file=[file sprintf('number_of_files=%1.0f\n',number_of_files)];
    file=[file sprintf('wdir=%s\n',directory)];
    file=[file sprintf('compression_factor=%1.0f\n',compression_factor)];
    file=[file sprintf('------------------------\n\n')];
    
    logname=sprintf('%s/reconstruction_log.info',resultdir);
	fid=fopen(logname,'a+');
    fwrite(fid,file,'uchar');
    fclose(fid);
end

end
