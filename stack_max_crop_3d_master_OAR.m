% that macro is a tool to crop a reconstructed 16 bits stack 
% by using a projection by maximum. If the projection exists it
% open it and ask to click on the two corners to define the selection that
% will be used to crop the volume. If the projection does not exist, it
% calculate it and open it for the selection process
% origin Paul Tafforeau ESRF 09/2007
% update Vincent 06/2016: works for original tif and jp2 and can save as
% tif or jp2, no matter what the orinigal data format is.
%
% update Vincent 03/2018: adding parsers; save-test to display the cropping
% mask array for scripting; multi_crop to allow seperating several portion
% of the data set in sub-volumes. rotate, to rotate all the slices. 
%
% usage: stack_max_crop_3d_master_OAR (resultdir_short, varargin)
%
% must be used within a folder
%
%Requiered parameters include:
%   
%   resultdir_short         name of the result directory. within quotes.
%                           if is empty, automatically add '_crop_' at the
%                           of the original folder
%
% Optional Parameters include:
% 
%   'Save'                  Define the saving format: 'tif': 16 bits stack
%                           of tif; 'jp2': 16 bits jpeg 2000, default
%                           compression factor to 10; default 'save' is
%                           'auto': will use the keep the same format as
%                           original data.by choosing 'test', the program
%                           show you the script which can be copied if you
%                           want to run mutiple crops in different volumes.
%                           
% 
%   'multi_crop             Available options: 'yes'/ 'no'. by selecting
%                           'yes', you can divide the volume in several
%                           subvolume (if the data to crop is a column with
%                           several sample, it allows to separate each
%                           sample in an individual data set). After
%                           defining the crop on the projection along the
%                           vertical axis, you will be prompted to define
%                           the number of sub-volume. the projection along
%                           the lateral axis will open as may times as
%                           there are sub-volumes and for each you will
%                           have to define the top and bottom cropping.
%                           Sub-volume can overlap. 
%
%   'rotate'                integer defining the rotation of all the slices
%                           to align the sample with the canvas (usefull
%                           for slab for instance). default is 0. 
%
%   'identical_crop'        variable to force cropping with certain values.
%                           set to 1 when using
%                           master_stack_max_crop_3d_master_OAR to crop
%                           multiple volumes with the exact same cropping
%                           values. can be defined as an array to set the
%                           cropping values as well. Array is defined as
%                           such: 
%                           [set_ic crop1 crop2 crop3 crop4 first last]
%                           with: 
%                           set_ic: 1 to activate identical crop
%                           crop1 to crop 4: position of the 4 corner of
%                           the cropping maskon the projection along the
%                           vertical axis
%                           first and last: defined top and bottom for the
%                           cropped volume; 
%                           use 'save','test' to display the values of the 
%                           array. Default is 0
%                      
%
%   'mode'                  'auto','auto2' or 'manual': parameter to define
%                           the cropping mask. 'auto' and 'auto2' and test
%                           that have not been fully conclusive. Default is
%                           'manual'
%
% examples: 
%
% stack_max_crop_3d_master_OAR ('')
%                           for 'auto' saving mode and automatic naming
%
% stack_max_crop_3d_master_OAR ('','save','jp2')
%                           saving cropped images in jpeg 2000 with 10 compression
%



%% names for the scan processing

function stack_max_crop_3d_master_OAR (resultdir_short,varargin) % bug with the directory system


slices_per_job = 250 ; % number of slices processed by each job for automatic calculation of the total number of jobs
gpu_cpu = 'cpu';
%gpu_cpu = 'all_core_BE';
walltime='02:00:00';

secure_process                = 1 ; % activate a test, in case of blocked process during more than the waiting time below, the corresponding step is completely restarted without removing the previously prepared data
waiting_time                  = 60 ; % how long (in minutes) the system will wait before restarting the job submission
number_of_trials              = 3 ; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop
restart_flag                  = 0; % set to 1 if you want to check if the result image already exist first and not overwrite it; 0 writes without checking
checkingtime                  = 20; % interval between two checking loop, in seconds
start_now                     = 1 ;
debug=0
%% Other variable
waiting                       = 1; % let to 1, variable for the checking loop
job_restart                   = 0; % let to 0, it for the checking loop

identical_crop=0;

%% PARSER
p = inputParser;
%   Make input string case independant
p.CaseSensitive = false;

%   Specifies the required inputs
addRequired(p,'resultdir_short');

%   Sets the default values for the optional parameters
defaultSave = 'auto';
defaultIdentical_crop = 0;
defaultRotate         = 0;
defaultMode = 'manual';
defautlMultiCrop = 'no';

%   Specifies valid strings for the optional parameters
validSave = {'auto','tif','jp2','test'};
validMode = {'auto','auto2','manual'};

%   Funtion handles to determine wheter a proper input string has been used
checkSave = @(x) any(validatestring(x,validSave));
checkMode = @(x) any(validatestring(x,validMode));

%   Create optional inputs
addParamValue(p,'save',defaultSave,checkSave);
addParamValue(p,'identical_crop',defaultIdentical_crop);
addParamValue(p,'rotate',defaultRotate,@isnumeric);
addParamValue(p,'mode',defaultMode,checkMode);
addParamValue(p,'multi_crop',defautlMultiCrop);

%   Pass all parameters and input to the parse method
parse(p,resultdir_short,varargin{:});
p.Results

%%


close all

%define original data type
djp2=dir('*.jp2');
dtif=dir('*.tif');
% removing max proj from process
pat='projection.tif';
index=cellfun(@isempty,regexp({dtif.name},pat));
njp2=size(djp2,1);
ntif=size(dtif(index),1);

if njp2>ntif
    file_type='jp2';    
    fname={djp2.name};
    number_of_files=njp2;
else
    file_type='tif';
    fname={dtif(index).name};
    number_of_files=ntif
end

%define saved data type
switch p.Results.save
    case 'jp2'
        saving_type='jp2';
    case 'tif'
        saving_type='tif';        
    otherwise
        saving_type=file_type;        
end


fprintf('original data are %s file\nnew data will be saved as %s\n',file_type,saving_type);

%%
        
root_dir=cleandirectoryname(pwd);
pos=findstr(root_dir,'/');
scan_dir=root_dir(pos(end)+1:end);
voltif_dir=root_dir(1:pos(end)-1);

switch saving_type
    case 'jp2'
        pos2=findstr(scan_dir,'jpeg2000-');
        compression_factor=str2num(scan_dir(pos2+9:pos2+10));
        
        if isempty (compression_factor)
            pos2=findstr(scan_dir,'jp2-');
            compression_factor=str2num(scan_dir(pos2+4:pos2+5));            
        end
        
        if isempty (compression_factor)
            disp('it was not possible to find the compression factor, I use 10 by default')
            compression_factor=10;
        else
            fprintf('saving type compression factor: %1.0f\n',compression_factor);
        end
        
        if compression_factor<1
            disp('error in compression_factor, I force it to 10');
            compression_factor=10;
        end
        if compression_factor>20
            disp('error in compression_factor, I force it to 10');
            compression_factor=10;
        end
    otherwise
        compression_factor=0;
        
end

if isempty (resultdir_short)
    resultdir=[voltif_dir '/' scan_dir 'crop_']
else
    resultdir=sprintf('%s/%s',voltif_dir,resultdir_short)
end

%% reading of the maximum projection

% test to know if the maximum projection is present
if p.Results.identical_crop(1,1)==0

%     f1 = fopen('Z_maximum_projection.tif','r');
    
    %if exist('Z_projection.tif','file')~=2
    if exist('Z_maximum_projection.tif','file')~=2    
%     if f1==-1        
        disp('the X,Y,Z maximum projections were not calculated, I do it now');
        max_proj_XYZ; % nested_function
%              
%     else        
%         fclose (f1);
    end    

% getting Z proj crop values
    im_ref=imread('Z_maximum_projection.tif');
    [X Y]=size(im_ref);
    if p.Results.rotate~=0
        if X==Y; mask = create_circular_mask(X/2,Y/2,X/2,[X Y]);
                 im_roi=im_ref.*uint16(mask);
                 im_ref=imrotate(im_roi,p.Results.rotate,'bicubic');
        else     im_ref=imrotate(im_ref,p.Results.rotate,'bicubic');
        end
    end
    
    switch p.Results.mode
        case 'manual'
            [rb,re,cb,ce]=getcorners_paul(im_ref,'Indicate top left corner','Indicate bottom right corner');
        case 'auto'
            auto_crop;
        case 'auto2'
            auto_crop2;
    end
    
    fprintf('the final size of each slice should be %1.0f * %1.0f pixels\ninstead of %1.0f * %1.0f pixels\n',ce-cb,re-rb,X,Y);
    
    crop1=cb;
    crop2=rb;
    crop3=ce-cb-1;
    crop4=re-rb-1;
    
    % getting X and Y proj crop values    
    switch p.Results.multi_crop
        case 'no'
            [first,last]=get_crop_Z_axis    ;        
        case 'yes'
            [first,last,result_dir_list]=get_crop_sub_scan;
            
    end

else
    %crop from input
    crop1=p.Results.identical_crop(1,2)
    crop2=p.Results.identical_crop(1,3)
    crop3=p.Results.identical_crop(1,4)
    crop4=p.Results.identical_crop(1,5)
    first=p.Results.identical_crop(1,6)
    last=min(p.Results.identical_crop(1,7),number_of_files)
end

% display command to copy in a script
switch p.Results.multi_crop
    case 'no'
        switch  p.Results.save
            case 'test'
                resultdir
                fprintf('\ncd %s\n',scan_dir);
                if p.Results.rotate>0
                    fprintf('stack_max_crop_3d_master_OAR (''%s'',''rotate'',''%1.0f'',''identical_crop'',[1 %1.0f %1.0f %1.0f %1.0f %1.0f %1.0f ])\n',resultdir_short,p.Results.rotate,crop1,crop2,crop3,crop4,first,last)
                else
                    fprintf('stack_max_crop_3d_master_OAR (''%s'',''identical_crop'',[1 %1.0f %1.0f %1.0f %1.0f %1.0f %1.0f ])\n',resultdir_short,crop1,crop2,crop3,crop4,first,last)
                end
                fprintf('cd %s\n',voltif_dir);
                fprintf('\n')
                return
        end
        
        fprintf('you will process %1.0i slices on a total of %1.0i\n',(last-first),number_of_files);
        close all
end




%% starting of the parallel calculation

switch p.Results.multi_crop
    case 'no'
        
        if isempty (resultdir_short)
            resultdir=[voltif_dir '/' scan_dir 'crop_'];
        else
            resultdir=sprintf('%s/%s',voltif_dir,resultdir_short);
        end
        
        makedir(resultdir)
        
        final_nb=last-first;
        
        start_full_process(first,last,final_nb,resultdir)
        
    case 'yes'
        number_of_sub_dir = size(result_dir_list,2);
        
        for k=1:number_of_sub_dir
            resultdir=result_dir_list{k};
            makedir(resultdir)
            
            final_nb=last{k}-first{k};
            
            fprintf('%1.0f/%1.0f: Processing multi scan crop:\n%s\nSlice %1.0f to %1.0f\n',k,number_of_sub_dir,result_dir_list{k},first{k},last{k})
            
            start_full_process(first{k},last{k},final_nb,resultdir)
        end
        
        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% start full process and check
    function start_full_process(FIRST,LAST,final_nb,resultdir)
        if debug==0
            
            reset_oar_params % nested function
            
            while waiting==1
                
                njobs=ceil((final_nb+1)/slices_per_job);
                
                
                param_string=sprintf('%1.0f %1.0f %1.0f %1.0f %s %s %s %1.0f %1.0f %1.0f %1.0f',crop1, crop2, crop3, crop4, resultdir,file_type,saving_type,compression_factor,p.Results.rotate,final_nb,restart_flag);
                
                
                job_abstract (FIRST,LAST,njobs,root_dir,start_now,gpu_cpu,walltime,crop1, crop2, crop3, crop4, resultdir,file_type,saving_type,compression_factor,restart_flag)
                
                %recording terminal display to get oar_job_id
                fndate=datestr(now,'yyyy-mm-dd-HH:MM:SS');
                random_num=sprintf('_%4.4i',round(rand*1000));  % to avoid similar names
                
                diary_file=sprintf('%s/%s_%s_%s.m',root_dir,scan_dir,fndate,random_num);
                diary(diary_file);
                diary on
                
                % starting process
                do_OAR_id19_2019('stack_max_crop_3d_slave_OAR',FIRST,LAST,njobs,root_dir,start_now,gpu_cpu,walltime,param_string);
                
                diary off
                
                [oar_id_list oar_array]=oar_jobs_from_log(diary_file,njobs);
                
                [waiting,njobs,restart_flag,job_restart]=OAR_process_checker2(resultdir...
                    ,checkingtime...
                    ,waiting_time...
                    ,saving_type...
                    ,secure_process...
                    ,number_of_trials...
                    ,job_restart...
                    ,slices_per_job...
                    ,final_nb...
                    ,oar_id_list...
                    ,oar_array...
                    ,'gpu_cpu',gpu_cpu);
                
            end
        else
            %stack_max_crop_3d_slave_OAR (first,last,directory, crop1, crop2, crop3, crop4, resultdir,file_type,saving_type,compression_factor,rotate,final_nb,restart_flag)
            stack_max_crop_3d_slave_OAR (FIRST,LAST,root_dir, crop1, crop2, crop3, crop4, resultdir,file_type,saving_type,compression_factor,p.Results.rotate,final_nb,restart_flag)
        end
    

        % createing infofile
        file=[];
        dinfo=dir(['*.info']);
        infoname={dinfo.name};
        
        if size(infoname,1)>0
            for ii=1:size(infoname,1)
                infofile=infoname{ii};
                
                fp=fopen(infofile,'r');
                if fp~=-1 % *.info exists
                    hd=fscanf(fp,'%c');
                    fclose(fp);
                else
                    hd=[];
                end
                file=[file hd];
            end
        end
        
        file=[file sprintf('\n------------------------\nstack_max_crop_3d_master\n------------------------\n\n')];
        file=[file sprintf('crop1=%1.0f\n',crop1)];
        file=[file sprintf('crop2=%1.0f\n',crop2)];
        file=[file sprintf('crop3=%1.0f\n',crop3)];
        file=[file sprintf('crop4=%1.0f\n',crop4)];
        file=[file sprintf('first=%1.0f\n',FIRST)];
        file=[file sprintf('last=%1.0f\n',LAST)];
        file=[file sprintf('root_dir=%s\n',root_dir)];
        file=[file sprintf('resultdir=%s\n',resultdir)];
        file=[file sprintf('file_type=%s\n',file_type)];
        file=[file sprintf('saving_type=%s\n',saving_type)];
        file=[file sprintf('compression_factor=%1.0f\n',compression_factor)];
        file=[file sprintf('p.Results.rotate=%1.0f\n',p.Results.rotate)];
        file=[file sprintf('------------------------\n\n')];
        
        logname=sprintf('%s/reconstruction_log.info',resultdir);
        fid=fopen(logname,'a+');
        fwrite(fid,file,'uchar');
        fclose(fid);
    end

%% test for auto crop 
    function auto_crop
        
        binaryImageName=[resultdir '/segmentation_mask_Z_maximum_projection.tif'];
            %reducing size if necessary to accelerate segmentation
            %calculation
            if size(im_ref,1)>512;  resize_factor=round(size(im_ref,1)/512);
            else                    resize_factor=1;
            end
            
            if resize_factor>1;     max_proj_im2=imresize(im_ref,1/resize_factor,'nearest');
            end
            
            max_proj_im2=medfilt_rapid(max_proj_im2,[75 75],'replicate');
            
            % blank segmentation mask
            segmask=zeros(size(max_proj_im2));
            segmask(250:end-250,250:end-250) = 1;
            
            % activecontour with 500 iteration to get a good view of the
            % sample
            fprintf('Creating Mask...')
            %figure;imshow(max_proj_im2,[]);title('max_proj')
            bw = imcomplement(activecontour(max_proj_im2,segmask,500));
            %figure;imshow(bw,[]);title('active contour')
            % back to original size if necessary
            if resize_factor>1;           bw=imresize(bw,[size(im_ref,1) size(im_ref,2)],'nearest');
            end
            
            % Get the bounding box
            sedil=strel('disk',500);% to remove isolated dot
            sedil2=strel('disk',600);% to go back to original mask plus 25 extra pixels for safety
            binaryImage  =imerode(imdilate(bw,sedil),sedil2);
            fprintf('Done\n')
            
            fprintf('Writting segmentation mask file...')
            imwrite(binaryImage,binaryImageName,'tif','Compression','none');
            fprintf('Done\n')
            
            labeledImage = bwlabel(~binaryImage);
            measurements = regionprops(labeledImage, 'BoundingBox');
            stat = regionprops(labeledImage, 'Centroid')
            %centroid = measurements2(1).Centroid
            boundingBox = measurements(1).BoundingBox
            
            figure;imshow(im_ref)
            hold on 
            
            for x = 1: numel(stat)
                plot(stat(x).Centroid(1),stat(x).Centroid(2),'bo');
                rectangle('Position',[stat(x).Centroid(1)-800 stat(x).Centroid(2)-800 1600 1600],'EdgeColor','b', 'LineWidth', 3)
            end 
            
            cb=stat(1).Centroid(1)-800;
            ce=stat(1).Centroid(1)+800;
            rb=stat(1).Centroid(2)-800;
            re=stat(1).Centroid(2)+800 ;
    end

%% second test for auto crop
    function auto_crop2
        
        binaryImageName=[resultdir '/segmentation_mask_Z_maximum_projection.tif'];
            %reducing size if necessary to accelerate segmentation
            %calculation
            if size(im_ref,1)>512;  resize_factor=round(size(im_ref,1)/512);
            else                    resize_factor=1;
            end
            
            if resize_factor>1;           max_proj_im2=imresize(im_ref,1/resize_factor,'nearest');
            end
            
            max_proj_im2=medfilt_rapid(max_proj_im2,[75 75],'replicate');
            
            % blank segmentation mask
            segmask=zeros(size(max_proj_im2));
            segmask(10:end-10,10:end-10) = 1;
            
            % activecontour with 500 iteration to get a good view of the
            % sample
            fprintf('Creating Mask...')
            %figure;imshow(max_proj_im2,[]);title('max_proj')
            bw = imcomplement(activecontour(max_proj_im2,segmask,500));
            %figure;imshow(bw,[]);title('active contour')
            % back to original size if necessary
            if resize_factor>1;           bw=imresize(bw,[size(im_ref,1) size(im_ref,2)],'nearest');
            end
            
            % Get the bounding box
            sedil=strel('disk',100);% to remove isolated dot
            sedil2=strel('disk',200);% to go back to original mask plus 25 extra pixels for safety
            binaryImage  =imerode(imdilate(bw,sedil),sedil2);
            fprintf('Done\n')
            
            fprintf('Writting segmentation mask file...')
            imwrite(binaryImage,binaryImageName,'tif','Compression','none');
            fprintf('Done\n')
            
            labeledImage = bwlabel(~binaryImage);
            measurements = regionprops(labeledImage, 'BoundingBox');
            stat = regionprops(labeledImage, 'Centroid')
            %centroid = measurements2(1).Centroid
            boundingBox = measurements(1).BoundingBox
            
            figure;imshow(im_ref)
            hold on 
            
            for x = 1: numel(stat)
                plot(stat(x).Centroid(1),stat(x).Centroid(2),'bo');
                rectangle('Position',[stat(x).Centroid(1)-750 stat(x).Centroid(2)-750 1500 1500],'EdgeColor','b', 'LineWidth', 3)
            end 
            
            cb=stat(1).Centroid(1)-750;
            ce=stat(1).Centroid(1)+750;
            rb=stat(1).Centroid(2)-750;
            re=stat(1).Centroid(2)+750; 
    end

%% Making max projection in X Y Z axis
    function max_proj_XYZ
        % names for the scan processing        
        vertical_step=ceil(number_of_files/512);        
        % reading of the first picture        
        tic        
        initial_name=fname{1};
        a=imread(initial_name);
        init_im=a;
        
        if size(a,1)>512
            resize_factor=round(size(a,1)/512);
            fprintf('the pictures are quite large, I reduce them by %1.0i and read only one every %1.0i to accelerate the calculations\n',resize_factor,vertical_step);
        else
            resize_factor=1;
        end
        
        if resize_factor>1
            a=imresize(a,1/resize_factor,'nearest');
        end
        
        immax=a;
        line1=max(a);
        line2=max(a');
        
        for i=2:vertical_step:number_of_files;
            
            slice_name=fname{i}
            fprintf('processing slice number %1.0i on %1.0i  \r',i,number_of_files);
            b=imread(slice_name);
            if resize_factor>1
                b=imresize(b,1/resize_factor,'nearest');
            end
            
            immax=max(immax,b);
            line1b=max(b);
            line1=[line1' line1b']';
            line2b=max(b');
            line2=[line2' line2b']';
        end
        
        
        disp('extrapolating the projections pictures to fit with the original size')
        
        immax=imresize(immax,[size(init_im,1) size(init_im,2)],'bilinear');
        line1=imresize(line1,[number_of_files size(init_im,1)],'bilinear');
        line2=imresize(line2,[number_of_files size(init_im,2)],'bilinear');
        
        
        imwrite(immax,'Z_maximum_projection.tif','tif','Compression','none');
        imwrite(line1,'X_maximum_projection.tif','tif','Compression','none');
        imwrite(line2,'Y_maximum_projection.tif','tif','Compression','none');
        
        ! chmod 777 *projection*
        
        toc
    end
% Open X and Y axis images for vertical crop
    function [FIRST,LAST]=get_crop_Z_axis
        im_refX=imread('X_maximum_projection.tif');
        im_refY=imread('Y_maximum_projection.tif');
        im_refXY=[im_refX im_refY]';
        
        switch p.Results.mode
            case 'manual'
                
                if size(im_refXY,1)>10000 || size(im_refXY,2)>10000
                    
                    im_refXY10=imresize(im_refXY,0.1,'bilinear');
                    [rb10,re10,cb10,ce10]=getcorners_paul(im_refXY10,'Indicate top','Indicate bottom');
                    rb=rb10*10;
                    re=re10*10;
                    cb=cb10*10;
                    ce=ce10*10;
                    
                else
                    [rb,re,cb,ce]=getcorners_paul(im_refXY,'Indicate top','Indicate bottom');
                end
                
                FIRST=max(cb,1);
                LAST=min(ce,number_of_files);
            case {'auto','auto2'}
                FIRST=1;
                LAST=number_of_files
        end
    end

%%Open X and Y axis images for vertical crop
function [FIRST,LAST,result_dir_list]=get_crop_sub_scan
        im_refX=imread('X_maximum_projection.tif');
        im_refY=imread('Y_maximum_projection.tif');
        im_refXY=[im_refX im_refY]';
        
        figure(1); imshow(im_refXY',[]);title('Indicate number of sub scans as prompted');impixelinfo
        
        prompt=sprintf('How many subscans do you wish to create?');
        default=sprintf('1');
        number_of_sub_dir=inputwdefaultnumeric(prompt,default);
        if number_of_sub_dir<1
            fprintf('number of sub dir must be a positive integer\n');
            return
        end
        
        for l=1:number_of_sub_dir
            text1       = sprintf('Indicate top of scan %1.0f',l);
            text2       = sprintf('Indicate bottom of scan %1.0f',l);
            [~,~,cb,ce] = getcorners_paul(im_refXY,text1,text2)  ;     
    
            result_dir_list{l}      = sprintf('%s%03d_',resultdir,l);
            dir_num_ok=0;
            dir_num=l;
            while dir_num_ok==0 % case of previsous processing, avoid redoing the same things
                if exist(result_dir_list{l},'dir')==7
                    dir_num=dir_num+1;
                    result_dir_list{l}      = sprintf('%s%03d_',resultdir,dir_num);
                else
                    dir_num_ok=1;
                    makedir(result_dir_list{l})
                end
            end
               
            FIRST{l}  = max(cb,1);
            LAST{l}   = min(ce,number_of_files);
            fprintf('%s will go from slice %1.0f to %1.0f\n',result_dir_list{l} ,FIRST{l},LAST{l});
        end      

    end
%%
    function reset_oar_params
        slices_per_job = 250 ; % number of slices processed by each job for automatic calculation of the total number of jobs
        gpu_cpu = 'cpu';
        %gpu_cpu = 'all_core_BE';
        walltime='02:00:00';
        
        secure_process                = 1 ; % activate a test, in case of blocked process during more than the waiting time below, the corresponding step is completely restarted without removing the previously prepared data
        waiting_time                  = 60 ; % how long (in minutes) the system will wait before restarting the job submission
        number_of_trials              = 3 ; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop
        restart_flag                  = 0; % set to 1 if you want to check if the result image already exist first and not overwrite it; 0 writes without checking
        checkingtime                  = 20; % interval between two checking loop, in seconds
        start_now                     = 1 ;
        debug=0
        %% Other variable
        waiting                       = 1; % let to 1, variable for the checking loop
        job_restart                   = 0; % let to 0, it for the checking loop
        
        
    end
end


function [oar_id_list,oar_array]=oar_jobs_from_log(diary_file,njobs)

%getting oar_job_id from reccorded terminal display
fp=fopen(diary_file,'r');

if fp ~= -1 % *.info exists
    hd=fscanf(fp,'%c');
    DIARY=textscan(hd,'%s','delimiter','= \b\t','MultipleDelimsAsOne',1);
    fclose(fp);
end

if njobs==1
    oar_id_list=str2num(DIARY{1}{find(strcmp(DIARY{1},'OAR_JOB_ID'), 1)+1});
    oar_array=0;
else
    index_list=find(strcmp(DIARY{1},'OAR_JOB_ID'), njobs);
    oar_id_list=zeros(njobs,1);
    for i=1:njobs
        oar_id_list(i)=str2num(DIARY{1}{index_list(i)+1});
    end
    index_list=find(strcmp(DIARY{1},'OAR_ARRAY_ID'), njobs);
    oar_array=str2num(DIARY{1}{index_list+1});
end


end

function job_abstract (first,last,njobs,root_dir,start_now,gpu_cpu,walltime,crop1, crop2, crop3, crop4, resultdir,file_type,saving_type,compression_factor,restart_flag)
fprintf('\nFirst            :%1.0f\n',first);
fprintf('last               :%1.0f\n',last);
fprintf('njobs              :%1.0f\n',njobs);
fprintf('wdir               :%s\n',root_dir);
fprintf('start_now          :%1.0f\n',start_now);
fprintf('gpu_cpu            :%s\n',gpu_cpu);
fprintf('walltime           :%s\n',walltime);
fprintf('resultdir          :%s\n',resultdir);
fprintf('restart_flag       :%1.0f\n',restart_flag);
fprintf('crop1              :%1.0f\n',crop1);
fprintf('crop2              :%1.0f\n',crop2);
fprintf('crop3              :%1.0f\n',crop3);
fprintf('crop4              :%1.0f\n',crop4);
fprintf('file_type          :%s\n',file_type);
fprintf('saving_type        :%s\n',saving_type);
fprintf('compression_factor :%1.0f\n',compression_factor);
end

