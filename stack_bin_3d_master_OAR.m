% 3D binning of volumes in tif or jpeg2000
% origin Paul Tafforeau and Vincent Fernandez ESRF 2012


function stack_bin_master_OAR(binning_factor)


if nargin<1
    disp ('usage is stack_bin_3d_master_OAR(binning_factor)')
    return
end
fprintf('Starting Binning of the data with a factor of %1.0f\n',binning_factor);
%%
compression_factor = 10; % only used in case of jp2 compression
test=0;
%% OAR AND WAITING LOOP PARAMS

first             = 1;
last              = 0;
start_now         = 1;
secure_process    = 1;
waiting_time      = 30 ; % how long (in minutes) the system will wait before restarting the job submission
checkingtime      = 10; % interval between two checking loop, in seconds
number_of_trials  = 3 ; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop
restart_flag      = 1 ;
gpu_cpu           = 'cpu';
walltime          = '02:00:00';
slices_per_job    = 500 ; % number of slices processed by each job to calculate automatically the number of jobs
waiting           = 1;
job_restart       = 0; % let to 0, it for the checking loop

%% Dev and debug modes
devmode           = 0; %set to one when doing development to test dev versions
debug             = 0 ;

%% selection of all the files having the same radix

f=dir('*.tif');
if size(f,1)<5 ; f=dir('*.jp2');  FileExtension='jp2';
else                              FileExtension='tif';        
end

tmpname={f.name};
%removing max proj from processing
pat='maximum_projection.tif';
index=cellfun(@isempty,regexp(tmpname,pat));
number_of_files=size(f(index),1);

if last==0 && test==0
    first=1;
    last=number_of_files;
elseif test>0
    first=test;
    last=test;    
end

fprintf(' - I found %1.0i slices to process\n',number_of_files);

% suffix to add to resultdir
suffix=sprintf('bin%1.0i_',binning_factor);

wdir=cleandirectoryname(pwd);
pos=findstr(wdir,'/');
root_dir=wdir(1:pos(end));
scandir=wdir(pos(end)+1:end);
resultdir=[root_dir '/' scandir suffix];

makedir(resultdir)

%% STARTING SLAVE

ProcessAttemptRestart=0;

if test==0 && debug==0
    while waiting==1       
        
        number_of_jobs=ceil((last-first+1)/slices_per_job);
        
        if number_of_jobs>50
            number_of_jobs=50;
        end
        
        final_nb=round(last-first)/binning_factor;
        
        param_string =              sprintf('%1.0f ',binning_factor);
        param_string =[param_string sprintf('%s ',FileExtension)];
        param_string =[param_string sprintf('%1.0f ',compression_factor)];
        param_string =[param_string sprintf('%1.0f',restart_flag)];
        fprintf('param_string:\n%s\n',param_string);
        
        %recording terminal display to get oar_job_id
        fndate=datestr(now,'yyyy-mm-dd-HH:MM:SS');
        random_num=sprintf('_%4.4i',round(rand*1000));  % to avoid similar names
        
        diary_file=sprintf('OAR_LOG_%s%s%s.m',scandir,fndate,random_num);
        diary(diary_file);
        diary on
        
        % starting process
        switch devmode
            case 0
            do_OAR_id19_2017('stack_bin_3d_slave_OAR',first,last,number_of_jobs,wdir,start_now,gpu_cpu,walltime,param_string);
            case 1
            do_OAR_id19_2017('stack_bin_3d_slave_OAR',first,last,number_of_jobs,wdir,start_now,gpu_cpu,walltime,param_string);
        end
        
        diary off
        
        [oar_id_list oar_array]=oar_jobs_from_log(diary_file,number_of_jobs);
        
        [waiting, number_of_jobs,restart_flag,job_restart]=OAR_process_checker2(resultdir,checkingtime,waiting_time,FileExtension,secure_process,number_of_trials,job_restart,slices_per_job,final_nb,oar_id_list,oar_array,'gpu_cpu',gpu_cpu)
        
        [ProcessDone,FileError]=stack_checker(resultdir,FileExtension,final_nb)
        if ProcessDone==0
            ProcessAttemptRestart=ProcessAttemptRestart+1;
            if ProcessAttemptRestart<4
                fprintf('Processing failed to complete, attempting restart (attempt %1.0f/%1.0f)\n',ProcessAttemptRestart,number_of_trials)
                waiting=1;
                restart_flag=1;
            else
                fprintf('Processing failed to complete, max number of attempt reached, stopping loop, please investigate\n')
                waiting=0;
                restart_flag=0;
            end
        end
        
        
        
    end
else
    switch devmode
        case 0
            stack_bin_3d_slave_OAR(first,last,wdir,binning_factor,FileExtension,compression_factor,restart_flag)
        case 1
            stack_bin_3d_slave_OAR(first,last,wdir,binning_factor,FileExtension,compression_factor,restart_flag)
    end
end

if test==0
    
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
        file=[file hd];        
    end

    fprintf('adding current program parameters\n')
    file =[file sprintf('\nstack_bin_3d_master_oar\n------------------------\n')];
    file =[file sprintf('binning_factor=%1.0f\n ',binning_factor)];
    file =[file sprintf('compression_factor=%1.0f\n ',compression_factor)];
    file =[file sprintf('FileExtension=%s\n ',FileExtension)];
    %file =[file sprintf('=%s\n ',)];
    file =[file sprintf('restart_flag=%1.0f\n',restart_flag)];
    
    logname=sprintf('%s/reconstruction_log.info',resultdir);
    fid=fopen(logname,'a+');
    fwrite(fid,file,'uchar');
    fclose(fid);
    
end


end

