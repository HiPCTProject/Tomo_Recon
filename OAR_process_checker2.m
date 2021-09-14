% origin Vincent Fernandez ESRF

function [waiting, number_of_jobs,restart_flag,job_restart,final_nb]=OAR_process_checker2(resultdir,checkingtime,waiting_time,file_type,secure_process,number_of_trials,job_restart,slices_per_job,final_nb,oar_id_list,oar_array,varargin)
tic
waiting=1;

%% PARSER
p = inputParser;
%   Make input string case independant
p.CaseSensitive = false;

%   Specifies the required inputs
addRequired(p,'resultdir');
addRequired(p,'checkingtime',@isnumeric);
addRequired(p,'waiting_time',@isnumeric);
addRequired(p,'file_type');
addRequired(p,'secure_process',@isnumeric);
addRequired(p,'number_of_trials',@isnumeric);
addRequired(p,'job_restart',@isnumeric);
addRequired(p,'slices_per_job',@isnumeric);
addRequired(p,'final_nb',@isnumeric);
addRequired(p,'oar_id_list');
addRequired(p,'oar_array');

%   Sets the default values for the optional parameters
defaultGpu_cpu = 'unknown';
defaultOverwrite = 0;

%   Specifies valid strings for the optional parameters
% validGpu_cpu= {'all_core_BE','crop'};

%   Funtion handles to determine wheter a proper input string has been used
%checkGpu_cpu = @(x) any(validatestring(x,validGpu_cpu));

%   Create optional inputs
addParamValue(p,'gpu_cpu',defaultGpu_cpu);
addParamValue(p,'overwrite',defaultOverwrite,@isnumeric);

%   Pass all parameters and input to the parse method
parse(p,resultdir,checkingtime,waiting_time,file_type,secure_process,number_of_trials,job_restart,slices_per_job,final_nb,oar_id_list,oar_array,varargin{:});
p.Results


fprintf('----------------------------------------------\nStarting processing survey (updated every %3.0f sec)\n----------------------------------------------\n',checkingtime)
file_checker=sprintf('%s/*%s',resultdir,file_type);
fprintf('checking for %s\n',file_checker);
if secure_process
    fprintf('This is a secured waiting loop\nif all jobs are finished but there is still some slices to process,\nthe process will be restarted\n');
    fprintf('Attempt number: %1.0f/%1.0f\n',job_restart+1,number_of_trials);
end

if p.Results.overwrite==0;  fprintf('The few first time estimation might be irrelevant\n')
else                        fprintf('No time estimation as file are being overwritten\nOnly monitoring OAR jobs')
end

number_of_jobs=0;
restart_flag=0;
prec_treated=0;
restart_process=0;
njobs=size(oar_id_list,1);

fprintf('OAR job type %s; Checking %1.0f job(s); OAR ID checked:',p.Results.gpu_cpu, njobs);
for i=1:njobs
    fprintf(' %1.0f',oar_id_list(i))
end

if oar_array~=0; fprintf('\nOAR_ARRAY_ID: %1.0f\n',oar_array);
else             fprintf('\n----------------------------------------------\n');
end

if secure_process; non_running_time=0;
end

%% case volumes vs stacks
switch file_type
    case {'raw','vol'}
        file_type=sprintf('%s*',file_type); % to include info and xml files
        final_nb=njobs*3; % patch to protect when all jobs are not started for some obscure reasons
end
            


job_started=zeros(njobs,1);

timeloop=1;

while waiting==1
    
    %% CHECKING JOBS
    
    job_running=0;
    job_waiting=0;
    job_terminated=0;
    job_error=0;
    % loop to get oar job number 
    for i=1:njobs
        
        [status result]=unix(sprintf('oarstat -j %1.0i',oar_id_list(i)));
        index=findstr(result,sprintf('%1.0f',oar_id_list(i)));
        
        if ~isempty(index)            
            cellA=textscan(result(index:end),'%s');
            job_state=cellA{1}{2};
            
            switch job_state                
                case{'R','L','F'}; job_running=job_running+1;
                                   job_started(i,1)=1;
                case 'W';          job_waiting=job_waiting+1;
                case 'T';          job_terminated=job_terminated+1;
                case 'E';          job_error=job_error+1;
            end
        else
            job_error=job_error+1;
        end
    end
    
    %patch for instability in OAR
    job_error=job_error+(njobs-job_running-job_waiting-job_terminated-job_error);
    
    fprintf('Job Running: %1.0f; Job Waiting: %1.0f; Job Finished: %1.0f',job_running,job_waiting,job_terminated);
    
    if job_error>0
        if strcmp(p.Results.gpu_cpu,'all_core_BE')==1;    fprintf('; Job Error (or Best Effort change of ID): %1.0f\n',job_error);
        else                                              fprintf('; Job Error: %1.0f\n',job_error);
        end
    else                                                  fprintf('\n');
    end
   
   
    if sum(job_started(:,1))>0 || job_terminated==njobs% if at least 1 job started or it crashed immediatly
        
        if p.Results.overwrite==0
            %% CHECKING FILES
            d=dir([resultdir '/*' file_type]);
            number_of_files=size(d,1);
        else
            number_of_files=final_nb;
        end
        
        if number_of_files<final_nb;                                                 checkfile=1;
        elseif p.Results.overwrite==1 && job_terminated~=njobs;                      checkfile=1;
        elseif strcmp(p.Results.gpu_cpu,'all_core_BE') && number_of_files<final_nb;  checkfile=1;
        else                                                                         checkfile=0;
        end
        
       
        
        
        if checkfile==1 % if checkfile is 0, then all job are finished in overwrite mode or all files are there
            waiting=1;
            pause (checkingtime);
            
           % Time Estimator
            if p.Results.overwrite==0 % if file are being overwritten, no checking of processed files is possible
                
%                 treated=number_of_files-prec_treated;
                
                sliceEvolution(timeloop)=number_of_files-prec_treated;
                timerunning=round(toc);
                if size(sliceEvolution,2)<3
                    treated=sliceEvolution(timeloop);
                    remaining_time=(timerunning/number_of_files)*(final_nb-number_of_files);
                else
                    treated=mean2(sliceEvolution(timeloop-2:timeloop)); 
                    remaining_time=((final_nb-number_of_files)/treated)*(checkingtime*3); 
                end
                
                timeloop=timeloop+1;
                
%                 if treated==0;   timerunning=round(toc);
%                                  remaining_time=(timerunning/number_of_files)*(final_nb-number_of_files);
%                 else             remaining_time=((final_nb-number_of_files)/treated)*(checkingtime);  
%                 end

                
                if remaining_time>3600;                     remaining_time=remaining_time/3600;
                    fprintf('%1.0f files treated in %3.0f seconds (total: %1.0f/%1.0f), %1.1f hour(s) remaining',treated,checkingtime,number_of_files,final_nb,remaining_time);
                else
                    if remaining_time<60;                   fprintf('%1.0f files treated in %3.0f seconds (total: %1.0f/%1.0f), %1.0f second(s) remaining',treated,checkingtime,number_of_files,final_nb,remaining_time);
                    else                                    remaining_time=remaining_time/60;
                        fprintf('%1.0f files treated in %3.0f seconds (total: %1.0f/%1.0f), %1.1f minute(s) remaining',treated,checkingtime,number_of_files,final_nb,remaining_time);
                    end
                end
                if treated==0;   non_running_time=non_running_time+1;
                    fprintf(' %% Failled attempt: %1.0f/%1.0f\n',non_running_time,waiting_time)
                else             non_running_time=0; fprintf('\n');
                end
                prec_treated=number_of_files;
                
            end
            
           % Nothing is happening, cases trigggering a restart
            if secure_process
                
              % Restarting conditions
                switch p.Results.gpu_cpu
                    case 'all_core_BE'
                        % the only condition to kill a job in id potent
                        % best effort is nothing is running for more than
                        % 'waiting time'
                        if non_running_time==waiting_time
                            restart_process=1; fprintf('Nothing happened for the last %1.0f minutes, killing jobs and restarting\n\n',waiting_time);
                        end
                    otherwise

                        if (job_error+job_terminated)==njobs && number_of_files<final_nb-1 && p.Results.overwrite==0 && non_running_time>1
                            restart_process=1; fprintf('Nothing happened for the last %1.0f minutes, killing jobs and restarting\n\n',waiting_time);
                        elseif non_running_time==waiting_time && number_of_files<final_nb-1
                            restart_process=1; fprintf('Nothing happened for the last %1.0f minutes, killing jobs and restarting\n\n',waiting_time);
                        end
                end
                
               % Restarting the process
                if restart_process==1
                    % diplaying error message if there was any
                    hd='';
                    joberr=0;
                    for i=1:njobs                        
                        oarid=sprintf('/tmp_14_days/oar/log/*%1.0f.err',oar_id_list(i));
                        try
                            o=dir(oarid);                            
                            if o.bytes>0
                                joberr=joberr+1;
                                oid=fopen(['/tmp_14_days/oar/log/' o(1).name],'r')     ;
                                hdtmp=fscanf(oid,'%c')        ;
                                hd=[hd sprintf('\n---------------------------\nERROR MESSAGE FROM JOB %1.0f:\n---------------------------\n',oar_id_list(i)) hdtmp];
                                fclose(oid);
                            end
                        catch
                            fprintf('Cannot check job\n')
                        end
                    end

                    if joberr>0
                        disp(hd)
                        fprintf('\n---------------------------\n%1.0f JOBS with error message\n',joberr);
                        fprintf('Above is the list of error message from OAR, do Ctrl+c to stop this process if the problem cannot be solved with simple relaunching of jobs\n');
                        fprintf('waiting 30 seconds to show you this message\n')
                        pause(30)
                    end
                    % restarting
                    
                    restart_flag=1;
                    number_of_jobs=50;
                    job_restart=job_restart+1;
                    
                    if job_restart==number_of_trials
                        disp('it seems impossible to do the processing, Stopping waiting loop, please investigate the problem more in details')
                        waiting=0;
                        return
                    end
                    
                    fprintf('I resubmit all of them with exclusion of processes already done\n');
                    if oar_array~=0
                        cmd=sprintf('oardel --a %i',oar_array);
                        unix(cmd)
                    else
                        for i=1:njobs
                            cmd=sprintf('oardel %i',oar_id_list(i));
                            unix(cmd)
                        end
                    end
                    break
                end
            else
                fprintf('\n');
            end
            
        else
            % final number of fil reached or no job running in overwrite
            % mode
            %fprintf('\ntemporary debugging text: nb of files: %1.0f; final: %1.0f; job mode %s; overwritting mode %1.0f\n',number_of_files,final_nb,p.Results.gpu_cpu,p.Results.overwrite);
            waiting=0;
            
            timefinish=round(toc);
            if timefinish>60
                if timefinish>3600
                    time_hour=floor(timefinish/3600);
                    time_min=floor((timefinish-(time_hour*3600))/60);
                    time_sec=round(timefinish-(time_min*60)) ;
                    fprintf('the processing is now finished; it took %1.0f:%02d:%02d minutes\n----------------------------------------------\n\n',time_hour,time_min, time_sec)
                    break
                else
                    time_min=floor(timefinish/60);
                    time_sec=round(timefinish-(time_min*60))    ;
                    fprintf('the processing is now finished; it took %1.0f:%02d minutes\n----------------------------------------------\n\n',time_min, time_sec)
                    break
                end
            else
                fprintf('the processing is now finished; it took %1.2f secondes\n----------------------------------------------\n\n',timefinish)
                break
            end
        end
    else
        pause(checkingtime/2)
    end
end

end
