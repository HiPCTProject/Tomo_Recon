% that macro is a tool to crop a reconstructed volume in 8 bits in stack of
% tif files by using a projection by maximum. If the projection exists it
% open it and ask to click on the two corners to define the selection that
% will be used to crop the volume. If the projection does not exist, it
% calculate it and open it for the selection process

% origin Paul Tafforeau ESRF 09/2007


%% names for the scan processing

function stack_max_crop_3d_slave_OAR (first,last,directory, crop1, crop2, crop3, crop4, resultdir,file_type,saving_type,compression_factor,rotate,final_nb,restart_flag)

if isdeployed
    first=str2num(first)
    last=str2num(last)
    crop1=str2num(crop1)
    crop2=str2num(crop2)
    crop3=str2num(crop3)
    crop4=str2num(crop4)
    compression_factor=str2num(compression_factor)
    rotate=str2num(rotate)
    final_nb=str2num(final_nb)
    restart_flag=str2num(restart_flag)
end

crop_values=[crop1 crop2 crop3 crop4]

check_file_type=sprintf('*.%s',file_type);
d=dir(check_file_type);
% removing max proj from process
pat='maximum_projection.tif';
index=cellfun(@isempty,regexp({d.name},pat));

fname={d(index).name};
number_of_files=size(d(index),1)

scan_dir=cleandirectoryname(pwd);
pos=findstr(scan_dir,'/');
scan_dir=scan_dir(pos(end)+1:end);

root_dir=cleandirectoryname(pwd);
pos=findstr(root_dir,'/');
scan_dir=root_dir(pos(end)+1:end);
voltif_dir=root_dir(1:pos(end)-1);

%% reading of the first picture

for i=first:last;
    
    imname=sprintf('%s/%s_%5.5i.%s',resultdir,scan_dir,i,saving_type);
    
    if restart_flag==1 && exist(imname,'file')==2
        fprintf('slice %1.0i already done\n',i);
    else
        
        
        slice_name=fname{i}
        try
        a=imread(slice_name);
        [X Y]=size(a);
        if rotate~=0
            if X==Y
                mask = create_circular_mask(X/2,Y/2,X/2,[X Y]);
                im_roi=a.*uint16(mask);
                a=imrotate(im_roi,rotate,'bicubic');
            else
                a=imrotate(a,rotate,'bicubic');
            end
        end
        
        b=imcrop(a,crop_values);
        
        fprintf('processing slice %1.0i\n',i);
        
        switch saving_type
            case 'jp2'
                imwrite_secure(b,imname,'CompressionRatio',compression_factor);
            otherwise
                imwrite(b,imname,'tif','Compression','none');
        end
        catch
            fprintf('nope\n');
        end
    end
    
end

%% extra stuff to do after full processing

if (last+2)>(first+final_nb)
    
    rawinfoname=sprintf('%s/reconstruction_log.info',root_dir)
    
    rawinfo=dir(rawinfoname)
    if size(rawinfo,1)>0
        fp=fopen(rawinfoname,'r');
        if fp~=-1 % *.info exists
            hd1=fscanf(fp,'%c');
            fclose(fp);
        end
    else
        hd1=[];
    end
    
    file=hd1;
    file=[file sprintf('------------------------\n\n')];
    file=[file sprintf('stack_max_crop_3d_slave_OAR\n------------------------\n')];
    file=[file sprintf('root_dir               :%s\n',root_dir)];
    file=[file sprintf('resultdir          :%s\n',resultdir)];
    file=[file sprintf('restart_flag       :%1.0f\n',restart_flag)];
    file=[file sprintf('first              :%1.0f\n',last-final_nb)];
    file=[file sprintf('last              :%1.0f\n',last)];    
    file=[file sprintf('crop1              :%1.0f\n',crop1)];
    file=[file sprintf('crop2              :%1.0f\n',crop2)];
    file=[file sprintf('crop3              :%1.0f\n',crop3)];
    file=[file sprintf('crop4              :%1.0f\n',crop4)];
    file=[file sprintf('file_type          :%s\n',file_type)];
    file=[file sprintf('saving_type        :%s\n',saving_type)];
    file=[file sprintf('compression_factor :%1.0f\n',compression_factor)];
    file=[file sprintf('------------------------\n\n')];
    
    logname=sprintf('%s/reconstruction_log.info',resultdir);
    fid=fopen(logname,'w+');
    fwrite(fid,file,'uchar');
    fclose(fid);
    
end
end
