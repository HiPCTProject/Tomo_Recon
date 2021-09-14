% macro to select the optimal parameters for the ring correction before
% using the compiled parallelized version
% argument: number of the slice for the test
% origin Paul Tafforeau ESRF 2009



function stack_rings_master_OAR(test_slice,varargin)

%% THE PARAMETERS

median_size                = 200 ; % maximum size of the rings that will be corrected
number_of_pass             = 3 ; % set to the desired number of pass of the whole filter
structure_removal_level    = 0.07 ; % threshold value to remove the samples structures before the final rings calculation, best 0.1, set to 0 to desactivate
blur_angle                 = 70 ; % minimum angular length of the rings
fusion_angle               = 70 ;% angular value for the fusion of the two picture parts in case of 180 degrees correction
strong_rings               = 5 ;  % give the filter size for direct removal of full circles
rotate_slices              = 0 ; % rotation factor in case of reconstructions with angular offset for the 180 degres algorithm.2

double_polar_corr          = 1     ; % set to 1 in case of highly structured sample creating more rings than before the correction if nothing else works


%% for parallelisation

slices_per_job  = 10    ; % number of slices processed by each job for automatic determination of the number of jobs
start_now       = true  ;  % put true to start the processing directly after parameters acceptation of false to create only the cmd file
first           = 1     ;
last            = 0     ; % set to 0 to process up to the last slice
walltime        = '10:00:00'

previous_result_overwrite = 0 ;  % 0, skipping files already in the result directory, 1 reprocessing everything

%% expert settings   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

high_contrast_cut          = 000  ; % indicate the maximum deviation for contrast around the median of the slice. set to 0 to desactivate
amedian                    = 0000  ; % median level of the slice, to be manually selected in case of high contrast exclusion needed


%% resources parameters

gpu_cpu = 'all_core_BE';

warning ('off')

if test_slice>0
    test=1;
else
    test=0;
end

warning ('off')


secure_process                = 1  ; % automatic stop and restart in case of problem
waiting_time                  = 120 ; % how long (in minutes) the system will wait before restarting the job submission
number_of_trials              = 1  ; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop

%% using the whole range for contrast determination during the correction

%define original data type
djp2=dir('*.jp2');
dtif=dir('*.tif');
njp2=size(djp2,1);
ntif=size(dtif,1);

if njp2>ntif
    file_type='jp2';
    NOF=njp2;
    d=djp2;
else
    file_type='tif'
    NOF=ntif
    d=dtif;
end


disp(sprintf('I found %1.0i slices to process in this directory',NOF));
fname={d.name};

scan_dir=cleandirectoryname(pwd)


switch file_type
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


%testing image class

testa=imread(fname{1});
class(testa)

switch class (testa)
    case 'uint16'
        amin=0
        amax=65635
    case 'single'
        amin=min2(testa);
        amax=max2(testa);
    case 'double'
        amin=min2(testa);
        amax=max2(testa);
    case 'uint8'
        amin=0
        amax=255
end
        




%%


if test_slice>0
    test=1;
    imname=sprintf(fname{test_slice});
    im=imread(imname);
    remove_rings_OAR_dev(im,median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,test,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut);
    toc


    start_processing=inputwdefault('do you want to start processing of multiple slices using parallel version ? ', 'n');
    if (start_processing == 'n')|(start_processing == 'no');

        return

    end


end


%% determination of the number of slices to process

if last==0
    last=NOF;
end


directory=cleandirectoryname(pwd);



number_of_jobs=ceil((last-first+1)/slices_per_job)

if previous_result_overwrite==1
    restart_flag=0
else
    restart_flag=1
end


param_string=sprintf('%1.0i %1.0i %4.4f %1.0f %1.0f %1.0f %1.2f %1.2f %1.2f %1.0f %1.0f %1.0f %s %1.0f %1.0f',median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut,file_type,compression_factor,restart_flag);
do_OAR_id19_2017('stack_rings_slave_OAR_dev',first,last,number_of_jobs,directory,start_now,gpu_cpu,walltime,param_string);



%% waiting loop for the rings correction

resultdir=[directory 'RC_'];
mkdir (resultdir)
disp ('the directory for the result files already existed or has been created')



%cd (resultdir)

waiting=1;
prec_treated=0;
disp('the survey of the number of files will be updated every minute, do not take into account the first measurement')


if secure_process
    non_running_time=0;
    job_restart=0;
end



while waiting==1

    switch file_type
        case 'jp2'
            d=dir([resultdir '/*.jp2']);
        case 'tif'
            d=dir([resultdir '/*.tif']);
    end
    
    number_of_files=size(d,1);


    if number_of_files<last
        waiting=1;
        pause(60)

        treated=number_of_files-prec_treated;
        remaining_time=((last-number_of_files)/treated)*60;


        if secure_process

            if treated==0
                non_running_time=non_running_time+1;
                disp('it seems that nothing new happened during the last minute, I am waiting before restarting the submission')
            else
                non_running_time=0;
            end

            if non_running_time==waiting_time
                job_restart=job_restart+1;
                if job_restart>number_of_trials
                    disp('it seems impossible to do the processing, I stop the waiting loop, please investigate the problem more in details')
                    return
                end

                disp('some of the jobs are not starting, I resubmit all of them');
                
                restart_flag=1
                param_string=sprintf('%1.0i %1.0i %4.4f %1.0f %1.0f %1.0f %1.2f %1.2f %1.2f %1.0f %1.0f %1.0f %s %1.0f %1.0f',median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut,file_type,compression_factor,restart_flag);
                do_OAR_id19_2017('stack_rings_slave_OAR_dev',first,last,number_of_jobs,directory,start_now,gpu_cpu,walltime,param_string);
                cd (resultdir)
                non_running_time=0;
            end

        end






        if remaining_time>3600
            remaining_time=remaining_time/3600;
            disp(sprintf('%1.0f files have been treated in one minute, a total of %1.0f files on %1.0f have been treated, it should finish in about %1.1f hours ',treated,number_of_files, last,remaining_time));
        else
            if remaining_time<60
                disp(sprintf('%1.0f files have been treated in one minute, a total of %1.0f files on %1.0f have been treated, it should finish in about %1.0f seconds ',treated,number_of_files,last,remaining_time));
            else
                remaining_time=remaining_time/60;
                disp(sprintf('%1.0f files have been treated in one minute, a total of %1.0f files on %1.0f have been treated, it should finish in about %1.1f minutes ',treated,number_of_files,last,remaining_time));
            end
        end


        prec_treated=number_of_files;


    else
        waiting=0;
        break
       % ! oardel_myjobs
    end

end



%%

disp('checking integrity of the reconstructed files, to be done in a clever way with Vincent')

    [ProcessDone,FileError]=stack_checker(resultdir,file_type,number_of_files)

    if FileError>0
        
        restart_flag=1

        param_string=sprintf('%1.0i %1.0i %4.4f %1.0f %1.0f %1.0f %1.2f %1.2f %1.2f %1.0f %1.0f %1.0f %s %1.0f %1.0f',median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut,file_type,compression_factor,restart_flag);
        do_OAR_id19_2017('stack_rings_slave_OAR_dev',first,last,number_of_jobs,directory,start_now,gpu_cpu,walltime,param_string);
        
        

        %% waiting loop for the rings correction

resultdir=[directory 'RC_'];
mkdir (resultdir)
disp ('the directory for the result files already existed or has been created')



%cd (resultdir)

waiting=1;
prec_treated=0;
disp('the survey of the number of files will be updated every minute, do not take into account the first measurement')


if secure_process
    non_running_time=0;
    job_restart=0;
end



while waiting==1

    switch file_type
        case 'jp2'
            d=dir([resultdir '/*.jp2']);
        case 'tif'
            d=dir([resultdir '/*.tif']);
    end
    
    number_of_files=size(d,1);


    if number_of_files<last
        waiting=1;
        pause(60)

        treated=number_of_files-prec_treated;
        remaining_time=((last-number_of_files)/treated)*60;


        if secure_process

            if treated==0
                non_running_time=non_running_time+1;
                disp('it seems that nothing new happened during the last minute, I am waiting before restarting the submission')
            else
                non_running_time=0;
            end

            if non_running_time==waiting_time
                job_restart=job_restart+1;
                if job_restart>number_of_trials
                    disp('it seems impossible to do the processing, I stop the waiting loop, please investigate the problem more in details')
                    return
                end

                disp('some of the jobs are not starting, I resubmit all of them');
                
                restart_flag=1
                param_string=sprintf('%1.0i %1.0i %4.4f %1.0f %1.0f %1.0f %1.2f %1.2f %1.2f %1.0f %1.0f %1.0f %s %1.0f %1.0f',median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut,file_type,compression_factor,restart_flag);
                do_OAR_id19_2017('stack_rings_slave_OAR_dev',first,last,number_of_jobs,directory,start_now,gpu_cpu,walltime,param_string);
                cd (resultdir)
                non_running_time=0;
            end

        end






        if remaining_time>3600
            remaining_time=remaining_time/3600;
            disp(sprintf('%1.0f files have been treated in one minute, a total of %1.0f files on %1.0f have been treated, it should finish in about %1.1f hours ',treated,number_of_files, last,remaining_time));
        else
            if remaining_time<60
                disp(sprintf('%1.0f files have been treated in one minute, a total of %1.0f files on %1.0f have been treated, it should finish in about %1.0f seconds ',treated,number_of_files,last,remaining_time));
            else
                remaining_time=remaining_time/60;
                disp(sprintf('%1.0f files have been treated in one minute, a total of %1.0f files on %1.0f have been treated, it should finish in about %1.1f minutes ',treated,number_of_files,last,remaining_time));
            end
        end


        prec_treated=number_of_files;


    else
        waiting=0;
        break
       % ! oardel_myjobs
    end

end


        
        
        
        
        
        
            
    end
    
    
    
disp('checking integrity of the reconstructed files, in case of problem, go for manual correction')

    [ProcessDone,FileError]=stack_checker(resultdir,file_type,number_of_files)




disp('the rings correction of the whole stack of slices is finished')


%% adding reconstruction parameters to the reconstruction_log.info file


 % writting info file
    info=dir('*info');
    infoname={info.name};
    number_of_info=size(info,1);
    fprintf('found %1.0f info files\n',number_of_info);
    file=[];
    hd=[];
    for ii=1:number_of_info
        info_to_read=infoname{ii};
        fprintf('reading %s\n',info_to_read);
        fp=fopen(info_to_read,'r');
        if fp ~= -1
            hd=fscanf(fp,'%c');
        else
            fprintf('cannot read %s\n',info_to_read);
            hd=[];
        end
        file=[file sprintf('\nprevious info from pyhst\n------------------------\n')];
        file=[file hd];
    end
    
    fprintf('adding current program parameters\n')
    file =[file sprintf('\rings_dev\n------------------------\n')];
    file =[file sprintf('median_size=%1.0f\n ',median_size)];
    file =[file sprintf('number_of_pass=%1.0f\n ',number_of_pass)];  
    file =[file sprintf('structure_removal_level=%1.2f\n ',structure_removal_level)];    
    file =[file sprintf('blur_angle=%1.0f\n ',blur_angle)]; 
    file =[file sprintf('fusion_angle=%1.0f\n ',fusion_angle)];    
    file =[file sprintf('strong_rings=%1.0f\n ',strong_rings)];    
    file =[file sprintf('rotate_slices=%1.0f\n ',rotate_slices)];    
    file =[file sprintf('double_polar_corr=%1.0f\n ',double_polar_corr)];
    
        
    logname=sprintf('%s/reconstruction_log.info',resultdir);
    fid=fopen(logname,'a+');
    fwrite(fid,file,'uchar');
    fclose(fid);





%%






end
