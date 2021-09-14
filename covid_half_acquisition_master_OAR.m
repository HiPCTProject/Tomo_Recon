% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% origin Paul Tafforeau ESRF 2020


function covid_half_acquisition_master_OAR(radix,scannum,test,preset)


close all

switch preset
  
    case 'classical_scan'
       
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 0   ; % apply a median filter of the filter size on the final picture and use the max, min or avg value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'max' ; % can be 'min' 'max' 'avg'
        HA_opt               = 0  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 0 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 0   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
     
    case 'large_field'
        
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 500   ; % apply a median filter of the filter size on the final picture and use the max, min or avg value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 20 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 500   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
       
   case 'large_field_off_axis'
        
        border_Vcorr_width   = 50   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 500   ; % apply a median filter of the filter size on the final picture and use the max, min or avg value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 20 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 500   ; 
    
    case 'core_biopsies'
        
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 1000   ; % apply a median filter of the filter size on the final picture and use the max, min or avg value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 20 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 500   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
        
  case 'zoom6_on_axis'
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 300   ; % apply a median filter of the filter size on the final picture and use the max value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 10 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 300   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
        
  case 'zoom6'
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 300   ; % apply a median filter of the filter size on the final picture and use the max value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 10 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 300   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
        
    case 'zoom6_hard'
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 500   ; % apply a median filter of the filter size on the final picture and use the max value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 1.00  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 10 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 500   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
  
    case 'zoom2'
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 1000   ; % apply a median filter of the filter size on the final picture and use the max value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 20 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 500   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
             
        
    case 'zoom1'
        border_Vcorr_width   = 0   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections
        back_16              = 1     ; % if set to 1, force the division by the accumulation number
        force_BF_1           = 2000   ; % apply a median filter of the filter size on the final picture and use the max value found to force each line to move to 1 using the mode defined below
        force_BF_mode        = 'avg' ; % can be 'min' 'max' 'avg'
        HA_opt               = 1  ; % make a basic concatenation of the two sides to allow forcing of values and normlisation on full width.
        BF_max_trans_level   = 0  ; % cut of all the parts lighter than the value considering that there should not be air
        BF_max_trans_size    = 20 ; % minimum size of the structures to be corrected by the BF_max_trans_level (using a median filter) done in two pass, the first with 5 times the filter size before other processing, the second at the end with the requested filter size
        BF_corr              = 00   ; % lateral normalisation to 1 based on measurements on the borders with exclusion of the center
                  
        
        
        
end

parallel             = 1   ; % put to 0 to make the calculation without OAR

%% defining the two directories to be concatenated

parentdir=cleandirectoryname(pwd);

HA_scan=dir(sprintf('%s*%3.3i*_',radix,scannum));
HA_scan={HA_scan.name};
HA_scan=HA_scan{1};
fprintf ('processing the scans %s  \n',HA_scan);


%% OAR PARAMS
number_of_jobs  = 100    ; % maximum available processor is 200
start_now       = true  ; % put true to start the processing directly after parameters acceptation of false to create only the cmd file
first           = 0     ; % set to 0 to start at the first slice
last            = 0     ; % set to 0 to automatically determine the number of slices to process

warning ('OFF')
gpu_cpu = 'all_core_BE';
walltime='2:00:00';

% security of the process usinsg automatic restart

checkingtime                  = 30;
secure_process                = 1 ; % activate a test, in case of blocked process during more than the waiting time below, the corresponding step is completely restarted without removing the previously prepared data
waiting_time                  = 20 ; % how long (in minutes) the system will wait before restarting the job submission
number_of_trials              = 4; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop


%%  creating result directory


    mkdir_withoutbackup ('PROCESSING')
    cd 'PROCESSING'
    resultdir_radix=cleandirectoryname(pwd);
    cd (parentdir)
    
    resultdir = sprintf('%s/%s%3.3i_',resultdir_radix,radix,scannum);
    namestr   = sprintf('%s%3.3i_',radix,scannum);

if test==0 
    
    newdirectory=isempty(what(resultdir));
    if newdirectory
        unix(sprintf('mkdir %s',resultdir))
        stat = 1;
        if stat
            disp(sprintf('New directory %s created successfully',resultdir));
            unix(sprintf('chmod 777 %s',resultdir));
        else
            disp('Problems creating new directory, permissions ???');
            return % EXITING PROGRAM !!!
        end
    end
    
end


%% information from the first scan

    fp=fopen([HA_scan '/' HA_scan,'.info'],'r');
    if fp~=-1 % *.info exists
        hd=fscanf(fp,'%c');
        fclose(fp);
        nvue =findheader(hd,'TOMO_N','integer');
        refon=findheader(hd,'REF_ON','integer');
      
        
    else	% *.info does not exist
        
        disp([HA_scan,'.info could not be found!' sprintf('\n')]);
        return
    end

%% read SR mode from XML
xmlfilename = sprintf('%s/%s.xml',HA_scan,HA_scan);



if exist(xmlfilename,'file')==2
    
    try
        filling_mode = read_xml_file(xmlfilename,'acquisition','machineMode');
        
        switch filling_mode
            case '4 bunch'
                max_SR_current=35;
            case '16 bunch'
                max_SR_current=95;
            otherwise
                max_SR_current=200;
        end
    catch
        max_SR_current=200;
    end
  
        
%% Dealing with accumulation
cfgfilename=sprintf('%s/%s.cfg',HA_scan,HA_scan');
fp2=fopen(cfgfilename,'r');
if fp2~=-1
    [acc_nb_frames]=str2num(read_cfg_file_dev(cfgfilename));
    fclose(fp2);    
else
    acc_nb_frames=1;
end
fprintf('--------------------------------------\nAccumulation=             %i\n--------------------------------------\n\n',acc_nb_frames);
  
       
%%

    if test==0 && parallel==1
        
        last=nvue;
        
        param_string=sprintf('%s %s %s %1.0f %1.0f %1.0f %1.2f %1.0f %1.0f %1.0f %s %1.3f %1.0f %1.4f %1.0f',resultdir,namestr,HA_scan,nvue,refon,acc_nb_frames,max_SR_current,border_Vcorr_width,back_16,force_BF_1,force_BF_mode,BF_corr,HA_opt,BF_max_trans_level,BF_max_trans_size)
        
        do_OAR_id19_2017('covid_half_acquisition_slave_OAR',first,last,number_of_jobs,parentdir,start_now,gpu_cpu,walltime,param_string);
        
   

    else
        if test>0
        first=test;
        last=test;
        else
           % first=0
             last=nvue;
        end
        
        fprintf('starting the slave \n')

        covid_half_acquisition_slave_OAR(first,last,parentdir,resultdir,namestr,HA_scan,nvue,refon,acc_nb_frames,max_SR_current,border_Vcorr_width,back_16,force_BF_1,force_BF_mode,BF_corr,HA_opt,BF_max_trans_level,BF_max_trans_size)
    end

%% waiting system for checking of processing evolution

 
   % cd (resultdir)

   
    waiting=1;
    prec_treated=0;
    disp('the survey of the number of files will be updated every 10 seconds, do not take into account the first measurement')


    if secure_process
        non_running_time=0;
        job_restart=0;
    end



    while waiting==1
        
          d=dir([ resultdir '/' namestr '*.edf']);
         
        number_of_files=size(d,1);



        if number_of_files<round(last-first)
            waiting=1;
            pause(checkingtime)

            treated=number_of_files-prec_treated;
            remaining_time=((last-first-number_of_files)/treated)*checkingtime;


            if secure_process

                if treated==0
                    non_running_time=non_running_time+1;
                    disp('it seems that nothing new happened during the last minute, I am waiting before restarting the submission')
                else
                    non_running_time=0;
                end

                if non_running_time==waiting_time
                    if job_restart==number_of_trials
                        disp('it seems impossible to do the processing, I stop the waiting loop, please investigate the problem more in details')
                        return
                    end
                    
                   % cd (directory)
                    disp('some of the jobs are not starting, I resubmit all of them');
                    %! oardel_myjobs
                    do_OAR_id19_2017('covid_half_acquisition_slave_OAR',first,last,number_of_jobs,parentdir,start_now,gpu_cpu,walltime,param_string);
 
                    job_restart=job_restart+1;
                    non_running_time=0;
                    
                end

            end




            if remaining_time>3600
                remaining_time=remaining_time/3600;
                disp(sprintf('%1.0f files processed in 10 seconds, %1.0f files on %1.0f processed, it should finish in about %1.1f hours',treated,number_of_files, last-first,remaining_time));
            else
                if remaining_time<60
                    disp(sprintf('%1.0f files processed in 10 seconds, %1.0f files on %1.0f processed, it should finish in about %1.0f seconds',treated,number_of_files,last-first,remaining_time));
                else
                    remaining_time=remaining_time/60;
                    disp(sprintf('%1.0f files processed in 10 seconds, %1.0f files on %1.0f processed, it should finish in about %1.1f minutes',treated,number_of_files,last-first,remaining_time));
                end
            end


            prec_treated=number_of_files;


        else
            break
        end

    end

end
