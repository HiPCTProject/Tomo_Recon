% that function aims to calculate 3D binning from tif stack, resulting
% in a new 8 tif stack, parameters are the binning factor, and the cluster
% name (OAR or condor)

% origin Paul Tafforeau ESRF 09/2007

function tif_bin_3d_master_OAR(binning_factor)

if nargin<1
    disp ('usage is tif_bin_3d_master_OAR(binning_factor)')
    return
end


%% parameters for parallelization
% number_of_jobs    = 50 automatic determination for processing of 100 slices per job
start_now         = 1

secure_process    = 1;
waiting_time      = 30 ; % how long (in minutes) the system will wait before restarting the job submission
number_of_trials  = 2 ; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop


%% GPU parameters

disp('this version will start CPUs only')
gpu_cpu        =  'cpu';
walltime       =  '02:00:00'
slices_per_job =  100 ; % number of slices processed by each job to calculate automatically the number of jobs

%% selection of all the files having the same radix
d=dir('*.tif');
fname={d.name};
number_of_files=size(d,1);

first=1;
last=number_of_files;

scan_dir=cleandirectoryname(pwd);
% n2: fileprefix, taken from directory name
pos=findstr(scan_dir,'/');
scan_dir=scan_dir(pos(end)+1:end);

directory=cleandirectoryname(pwd);

cd ..
voltif_dir=cleandirectoryname(pwd);
resultdir=[voltif_dir '/' scan_dir sprintf('bin%1.0i',binning_factor)];

cd (directory)

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


%% starting of the parallel calculation

param_string=sprintf('%1.0f',binning_factor);

number_of_jobs=ceil((last-first+1)/slices_per_job);
       
    do_OAR_id19_2017('tif_bin_3d_slave_OAR',first,last,number_of_jobs,directory,start_now,gpu_cpu,walltime,param_string)    
   

%% waiting system for checking of processing evolution

 
    cd (resultdir)

   
    waiting=1;
    prec_treated=0;
    disp('the survey of the number of files will be updated every 10 seconds, do not take into account the first measurement')


    if secure_process
        non_running_time=0;
        job_restart=0;
    end



    while waiting==1

        d=dir(['*.tif']);
        number_of_files=size(d,1);



        if number_of_files<round(last-first)/binning_factor
            waiting=1;
            pause(10)

            treated=number_of_files-prec_treated;
            remaining_time=((round(last-first)/binning_factor-number_of_files)/treated)*10;


            if secure_process

                if treated==0
                    non_running_time=non_running_time+1;
                    disp('it seems that nothing new happened during the last minute, I am waiting before restarting the submission')
                else
                    non_running_time=0;
                end

                if non_running_time==waiting_time
                    cd (directory)
                    disp('some of the jobs are not starting, I resubmit all of them');
                    %! oardel_myjobs
                    do_OAR_id19_2017('tif_bin_3d_slave_OAR',first,last,number_of_jobs,directory,start_now,gpu_cpu,walltime,param_string)
                    cd (resultdir)
                    job_restart=job_restart+1;
                    non_running_time=0;
                    if job_restart==number_of_trials
                        disp('it seems impossible to do the processing, I stop the waiting loop, please investigate the problem more in details')
                        return
                    end
                end

            end




            if remaining_time>3600
                remaining_time=remaining_time/3600;
                disp(sprintf('%1.0f files processed in 10 seconds, %1.0f files on %1.0f processed, it should finish in about %1.1f hours',treated,number_of_files, round(last-first)/binning_factor,remaining_time));
            else
                if remaining_time<60
                    disp(sprintf('%1.0f files processed in 10 seconds, %1.0f files on %1.0f processed, it should finish in about %1.0f seconds',treated,number_of_files,round(last-first)/binning_factor,remaining_time));
                else
                    remaining_time=remaining_time/60;
                    disp(sprintf('%1.0f files processed in 10 seconds, %1.0f files on %1.0f processed, it should finish in about %1.1f minutes',treated,number_of_files,round(last-first)/binning_factor,remaining_time));
                end
            end


            prec_treated=number_of_files;


        else
            waiting=0;
            break
        end

    end

    disp('the binning of the volume is finished, I hope that you will enjoy the results')

   close all

end
