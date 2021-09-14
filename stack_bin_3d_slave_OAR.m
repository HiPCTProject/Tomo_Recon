% that function aims to calculate 3D binning from tif stack, resulting
% in a new 8 bits tif stack, it asks the factor to be used for the binning

% origin Paul Tafforeau ESRF 09/2007

function stack_bin_3d_slave_OAR(first,last,directory,binning_factor,FileExtension,compression_factor,restart_flag)


if isdeployed
    first              =str2num(first)
    last               =str2num(last)
    binning_factor     =str2num(binning_factor)
    compression_factor =str2num(compression_factor)
    restart_flag       =str2num(restart_flag)
    
end

switch FileExtension
    case 'jp2'
        if compression_factor==0
            fprintf('compression factor cannot be 0 for jp2 files, forcing to 10\n');
            compression_factor=10;
        end
end

cd (directory)

cleandirectoryname(pwd)


% selection of all the files having the same radix
d=dir(['*.' FileExtension]);
tmpname={d.name};
%removing max proj from processing
pat='maximum_projection.tif';
index=cellfun(@isempty,regexp(tmpname,pat));
fname={d(index).name};


%fname={d.name};
number_of_files=size(d(index),1);

suffix=sprintf('bin%1.0i_',binning_factor);

wdir=cleandirectoryname(pwd);
pos=findstr(wdir,'/');
root_dir=wdir(1:pos(end));
scandir=wdir(pos(end)+1:end);
resultdir=[root_dir '/' scandir suffix];

%%

init_slice_name=sprintf(fname{1})
init_slice=imread(init_slice_name);
datatype=class(init_slice)

for i=first:binning_factor:last
    
    fprintf('processing slice %1.0f\n',i);
    
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
    
%     datatype
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
%     whos final_slice
    
    final_slice_name=sprintf('%s/%s_%5.5i.%s',resultdir,scandir,round((i+j)/binning_factor),FileExtension);
    
    switch FileExtension
        case 'tif'
            imwrite(final_slice,final_slice_name,'tif','Compression','none');
        case 'jp2'
            imwrite(final_slice,final_slice_name,'CompressionRatio',compression_factor);
    end
    
    
end

end
