% that function aims to calculate 3D binning from tif stack, resulting
% in a new 8 bits tif stack, it asks the factor to be used for the binning

% origin Paul Tafforeau ESRF 09/2007

function tif_bin_3d_slave_OAR(first,last,directory,binning_factor)


if isdeployed
    first=str2num(first)
    last=str2num(last)
    binning_factor=str2num(binning_factor)
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
resultdir=[voltif_dir '/' scan_dir sprintf('bin%1.0i',binning_factor)];

cd (directory)

%%

init_slice_name=sprintf(fname{1})
init_slice=imread(init_slice_name);

datatype=class(init_slice);




for i=first:binning_factor:last
    
    disp(sprintf('processing slice %1.0f',i));
    
    init_slice_name=sprintf(fname{i});
    init_slice=single(imread(init_slice_name));
    
    for j=1:binning_factor-1
        if i+j<number_of_files-1
            slice_name=sprintf(fname{i+j});
            slice=single(imread(slice_name));
            init_slice=init_slice+slice;
        end
    end
    
    final_slice=init_slice/binning_factor;
    
    
    switch datatype
        case 'uint8'
            final_slice=uint8(imresize(final_slice,1/binning_factor,'bilinear'));
        case 'int8'
            final_slice=int8(imresize(final_slice,1/binning_factor,'bilinear'));
        case 'uint16'
            final_slice=uint16(imresize(final_slice,1/binning_factor,'bilinear'));
        case 'int16'
            final_slice=int16(imresize(final_slice,1/binning_factor,'bilinear'));
            
    end
    
    
    final_slice_name=sprintf('%s/%s_%5.5i.tif',resultdir,scan_dir,round((i+j)/binning_factor));
    
    imwrite(final_slice,final_slice_name,'tif','Compression','none');
    
    
end

end
