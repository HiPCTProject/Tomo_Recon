% macro for OAR parallelization of ring correction on reconstructed
% slices
% origin Paul Tafforeau ESRF 2009

function rings_slave_OAR(first,last,directory,filename_radix,median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut)


! hostname

global GPU2USE 


%% -------------------------------------------------
% In case of interactive processingm this program is not used
% GPU2USE will then keep the right value
%% /////////////////////////////////////////////////

env_GPU2USE = getenv('GPU2USE');

disp('in rings_slave_dev env_GPU2USE  is')
env_GPU2USE
GPU2USE=-1 ;
if env_GPU2USE=='0'
  GPU2USE=0 ;
end
if env_GPU2USE=='1'
  GPU2USE=1 ;
end
if env_GPU2USE=='2'
  GPU2USE=2 ;
end
if env_GPU2USE=='3'
  GPU2USE=3 ;
end

disp(sprintf('in rings_slave_dev GPU2USE  is %1.0f',GPU2USE));

if GPU2USE ~=-1
  disp('going to select GPU card')
  res=cudadistribute(1,1,GPU2USE)
end



if nargin<10
    disp(' the correct usage is rings_OAR(first,last,directory,filename_radix,median_size,rotation_range,number_of_pass,structure_removal_level,blur_angle,fusion_angle,vertical_correction,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut)');
end

if isdeployed % conversion of strings into numerical values
    first=str2num(first);
    last=str2num(last);
    median_size=str2num(median_size);
    number_of_pass=str2num(number_of_pass);
    structure_removal_level=str2num(structure_removal_level);
    blur_angle=str2num(blur_angle);
    fusion_angle=str2num(fusion_angle);
    rotate_slices=str2num(rotate_slices);
    amin=str2num(amin);
    amax=str2num(amax);
    amedian=str2num(amedian);
    strong_rings=str2num(strong_rings);
    double_polar_corr=str2num(double_polar_corr);
    high_contrast_cut=str2num(high_contrast_cut);
  
end

  visualization=0;

%% analysis of the directory structure
 cd(directory)
 

% selection of all the files having the same radix
d=dir([filename_radix '*.vol']);
fname={d.name};
number_of_files=size(d,1);
disp(sprintf('you will process %1.0f files',number_of_files));


%%
  filename=sprintf(fname{1});
      
    %HST_header=HST_info(filename);
    %Z=max(1:HST_header.volSizeZ)
    
    % using info file due unsolvable problem with HST_info due to
    % modifications by someone. 
    
    info_filename=[filename '.info'];
    
    fp=fopen(info_filename);
    if fp~=-1 % *.info exists
      hd=fscanf(fp,'%c');
      fclose(fp);
      X=findheader(hd,'NUM_X','integer');
      Y=findheader(hd,'NUM_Y','integer');
      Z=findheader(hd,'NUM_Z','integer');
      byte_order=findheader(hd,'BYTEORDER','string');
      
      if strcmp(byte_order,'HIGHBYTEFIRST')==1
          bo='b';
          disp('the volume is coded in big indian')
      else
          bo='l';
          disp('the volume is coded in little indian')
      end
      
    end

    resultdir=sprintf('%s/%s',directory,filename_radix);
    mkdir (resultdir)
    disp ('the directory for the result files already existed or has been created')
    
    
   % reading and correcting the slices
  for slice_number=first:last
      volname_number=floor((slice_number-1)/Z)+1;
      volname=sprintf(fname{volname_number});
      slice_sub_num=slice_number-(volname_number-1)*Z;
      
      %try
      tic
      % direct reading of the file due to problems with HSTVolReader
      im=single(volread(volname,'float32',X*Y*4*(slice_sub_num-1),X,Y,1,bo));
      
      
      %im=HSTVolReader(volname,'xrange','all','zrange',slice_sub_num,'yrange','all');
      im2=remove_rings_OAR(im,median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,visualization,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut);
      new_name=filename(1:end-4);
      new_name=sprintf('%s/%sRC_%4.4i.edf',resultdir,new_name,slice_number)
      edfwrite(new_name,im2','float32');
     
     time=toc;
    basic_remaining_time=round((last-slice_number)*time);

    if basic_remaining_time>3600;
        remaining_time=basic_remaining_time/3600;
        disp(sprintf('processing slice %1.0f on %1.0f in %1.1f seconds. It should end in about %1.1f hours',slice_number-first,last-first,time,remaining_time));
    else
 
        if basic_remaining_time<60;
        remaining_time=basic_remaining_time;
        disp(sprintf('processing slice %1.0f on %1.0f in %1.1f seconds. It should end in about %1.1f seconds',slice_number-first,last-first,time,remaining_time));
                
        else
        remaining_time=basic_remaining_time/60;
        disp(sprintf('processing slice %1.0f on %1.0f in %1.1f seconds. It should end in about %1.1f minutes',slice_number-first,last-first,time,remaining_time));
        end
    end 
    
  
  end
  
  
 

end
