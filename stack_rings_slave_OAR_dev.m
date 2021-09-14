% macro for condor parallelization of ring correction on reconstructed
% slices. The resulting edf files are no longer transposed version of the
% original slices
% origin Paul Tafforeau ESRF 2009



function stack_rings_slave_OAR(first,last,directory,median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut,file_type,compression_factor,restart_flag)



if nargin<10
    disp(' the correct usage is tif_rings_slave_dev(first,last,directory,filename_radix,median_size,rotation_range,number_of_pass,structure_removal_level,blur_angle,fusion_angle,vertical_correction,rotate_slices,amin,amax,strong_rings,compression_factor)');
end

if isdeployed % conversion of strings into numerical values
    first=str2num(first)
    last=str2num(last)
    median_size=str2num(median_size)
    number_of_pass=str2num(number_of_pass)
    structure_removal_level=str2num(structure_removal_level)
    blur_angle=str2num(blur_angle)
    fusion_angle=str2num(fusion_angle)
    rotate_slices=str2num(rotate_slices)
    amin=str2num(amin)
    amax=str2num(amax)
    amedian=str2num(amedian)
    strong_rings=str2num(strong_rings)
    double_polar_corr=str2num(double_polar_corr)
    high_contrast_cut=str2num(high_contrast_cut)
    compression_factor=str2num(compression_factor)
    restart_flag=str2num(restart_flag)
end

visualization=0;

%% analysis of the directory structure
cd (directory)


% selection of all the files having the same radix

switch file_type

    case 'jp2'
        d=dir('*.jp2');
    case 'tif'
        d=dir('*.tif');
end

NOF=size(d,1);
fname={d.name};


%%

resultdir=[directory 'RC_'];
pos=findstr(resultdir,'/');
namestr=resultdir(pos(end)+1:end);
mkdir (resultdir)
disp ('the directory for the result files already existed or has been created')
cd (directory)


% reading and correcting the slices
for slice_number=first:last
    
    slice_name=sprintf(fname{slice_number});
    
    if restart_flag==1
        switch file_type
            case 'tif'
                 result_slice_name=sprintf('%s/%s%5.5i.tif',resultdir,namestr,slice_number);
            case 'jp2'
                 result_slice_name=sprintf('%s/%s%5.5i.jp2',resultdir,namestr,slice_number);
        end
        
        fp=fopen(result_slice_name,'r');
                 
        if fp == -1
            skip_slice=0;
        else
            skip_slice=1;
            disp(sprintf('the slice %s has already been processed, we skip it',result_slice_name));
        end
        
    else
        
        skip_slice=0;
    end
    
    tic
    
    if skip_slice==0
        
    
    
    im=imread(slice_name);
    
    
    im2=remove_rings_OAR_dev(im,median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,visualization,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut);
   
    
    
    switch file_type
         case 'tif'
                new_name=sprintf('%s/%s%5.5i.tif',resultdir,namestr,slice_number);
                imwrite(im2,new_name,'tif','Compression','none');
                fprintf('processing picture %1.0i over %1.0i \n',slice_number,NOF);
            case 'jp2'
                new_name=sprintf('%s/%s%5.5i.jp2',resultdir,namestr,slice_number);
                imwrite_secure(im2,new_name,'CompressionRatio',compression_factor);
                fprintf('processing picture %1.0i over %1.0i \n',slice_number,NOF); 
    
    end
    
    end
    
    process_time=toc;
    
    
    
    basic_remaining_time=round(((last-first)-(slice_number-first))*process_time);
    
    if basic_remaining_time>3600;
        remaining_time=basic_remaining_time/3600;
        disp(sprintf('processing slice %1.0f on %1.0f in %1.1f seconds. It should end in about %1.1f hours',slice_number,last,process_time,remaining_time));
    else
        
        if basic_remaining_time<60;
            remaining_time=basic_remaining_time;
            disp(sprintf('processing slice %1.0f on %1.0f in %1.1f seconds. It should end in about %1.1f seconds',slice_number,last,process_time,remaining_time));
            
        else
            remaining_time=basic_remaining_time/60;
            disp(sprintf('processing slice %1.0f on %1.0f in %1.1f seconds. It should end in about %1.1f minutes',slice_number,last,process_time,remaining_time));
        end
    end
    
    
    
end




end
