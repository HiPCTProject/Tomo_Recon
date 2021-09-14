% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% origin Paul Tafforeau ESRF 2020



ladaf_2020_27_Llung_FSC  =0;

ladaf_2020_27_heart      =0;
ladaf_2020_27_left_lung  =0;

ladaf_2020_31_brain      =0;


%% general parameters



if  ladaf_2020_27_Llung_FSC == 1
    disp('using the parameters defined for the ladaf-2020_27_left_lung FSC experiment of June 2021')
    left_pad_one         = 200  ; % add pixels at 1 on the left border to avoid large low frequencies issues
    num_pass             = 2  ; % number of iterations for the corrections
    lateral_shift        = 994  ; % displacement in horizontal direction in pixels for the concatenation of the two scans. 
    border_Vcorr_width   = 200   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections 
    back_16              = 1     ; % if set to 1, force the division by the accumulation number
    BF_corr              = 0    ;  % width of the low frequencies normalisation to 1 from the left (in proportion)
    BF_slope             = 4000    ; % approximate width of the transition zone in pixels
    force_BF_1           = 0     ; % for each line it calculates the median and then devide the line by this median to force it to 1
    force_max_1          = 1.2 ; % apply a 5 pixels blurring and cut-off the values above 1 for the lower frequencies. To correct for bordesr and bubbles
    double_ref           = 0   ; % in case references have been taken before and after the scans to use a linera interpolation between the two series
end



if ladaf_2020_31_brain   == 1
    disp('using the parameters defined for the LADAF 2020-31 brain')
    lateral_shift        = 970   ; % displacement in horizontal direction in pixels for the concatenation of the two scans. 
    left_pad_one         = 100  ; % add pixels at 1 on the left border to avoid large low frequencies issues
    num_pass             = 3  ; % number of iterations for the corrections
    border_Vcorr_width   = 300   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections 
    back_16              = 1     ; % if set to 1, force the division by the accumulation number
    BF_corr              = 0.05    ;  % width of the low frequencies normalisation to 1 from the left (in proportion)
    BF_slope             = 3000    ; % approximate width of the transition zone in pixels
    force_BF_1           = 1     ; % for each line it calculates the median and then devide the line by this median to force it to 1
    force_max_1          = 1.1 ; % apply a 5 pixels blurring and cut-off the values above 1 for the lower frequencies. To correct for bordesr and bubbles
    double_ref           = 0   ; % in case references have been taken before and after the scans to use a linera interpolation between the two series

end




if ladaf_2020_27_heart == 1
    disp('using the parameters defined for the LADAF 2020-27 heart')
    lateral_shift        = 962   ; % displacement in horizontal direction in pixels for the concatenation of the two scans. 
    left_pad_one         = 100  ; % add pixels at 1 on the left border to avoid large low frequencies issues
    num_pass             = 3  ; % number of iterations for the corrections
    border_Vcorr_width   = 300   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections 
    back_16              = 1     ; % if set to 1, force the division by the accumulation number
    BF_corr              = 0    ;  % width of the low frequencies normalisation to 1 from the left (in proportion)
    BF_slope             = 3000    ; % approximate width of the transition zone in pixels
    force_BF_1           = 1     ; % for each line it calculates the median and then devide the line by this median to force it to 1
    force_max_1          = 1.1 ; % apply a 5 pixels blurring and cut-off the values above 1 for the lower frequencies. To correct for bordesr and bubbles
    double_ref           = 0   ; % in case references have been taken before and after the scans to use a linera interpolation between the two series

end




if ladaf_2020_27_left_lung == 1
    disp('using the parameters defined for the LADAF 2020-27 left_lung')
    left_pad_one         = 100  ; % add pixels at 1 on the left border to avoid large low frequencies issues
    num_pass             = 2  ; % number of iterations for the corrections
    lateral_shift        = 974  ; % displacement in horizontal direction in pixels for the concatenation of the two scans. 
    border_Vcorr_width   = 300   ; % vertical correction on the left border to reduce the effect of the misalignment of the tubes between reference and projections 
    back_16              = 1     ; % if set to 1, force the division by the accumulation number
    BF_corr              = 0.3    ;  % width of the low frequencies normalisation to 1 from the left (in proportion)
    BF_slope             = 3000    ; % approximate width of the transition zone in pixels
    force_BF_1           = 1     ; % for each line it calculates the median and then devide the line by this median to force it to 1
    force_max_1          = 1.02  ; % apply a 5 pixels blurring and cut-off the values above 1 for the lower frequencies. To correct for bordesr and bubbles
    double_ref           = 0   ; % in case references have been taken before and after the scans to use a linera interpolation between the two series

end




parallel             = 1   ; % put to 0 to make the calculation without OAR

%% defining the two directories to be concatenated

parentdir=cleandirectoryname(pwd);

HA_scan=dir(sprintf('%s*HA_%3.3i_',radix,scannum));
TA_scan=dir(sprintf('%s*TA_%3.3i_',radix,scannum));
HA_scan={HA_scan.name};
TA_scan={TA_scan.name};
HA_scan=HA_scan{1};
TA_scan=TA_scan{1};
fprintf ('processing the scans %s and %s \n',HA_scan,TA_scan);


%% OAR PARAMS
number_of_jobs  = 50    ; % maximum available processor is 200
start_now       = true  ; % put true to start the processing directly after parameters acceptation of false to create only the cmd file
first           = 0     ; % set to 0 to start at the first slice
last            = 0     ; % set to 0 to automatically determine the number of slices to process

warning ('OFF')
gpu_cpu = 'both';
walltime='4:00:00';

% security of the process usinsg automatic restart
secure_process                = 1 ; % activate a test, in case of blocked process during more than the waiting time below, the corresponding step is completely restarted without removing the previously prepared data
waiting_time                  = 30 ; % how long (in minutes) the system will wait before restarting the job submission
number_of_trials              = 2; % in case of blocked jobs, how many times will be the system resubmitted before exiting of the loop
overwrite                     = 0; % in case of crash, 0 for skipping images already done; 1 to overwrite all images


%%  creating result directory


    mkdir_withoutbackup ('PROCESSING')
    cd 'PROCESSING'
    resultdir_radix=cleandirectoryname(pwd);
    cd (parentdir)
    
    resultdir = sprintf('%s/%s%3.3i_HATA_',resultdir_radix,radix,scannum);
    namestr   = sprintf('%s%3.3i_HATA_',radix,scannum);

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
        
        param_string=sprintf('%s %s %s %s %1.0f %1.0f %1.0f %1.0f %1.0f %1.2f %1.0f %1.0f %1.0f %1.3f %1.3f %1.3f %1.0f',resultdir,namestr,HA_scan,TA_scan,left_pad_one,num_pass,nvue,acc_nb_frames,lateral_shift,max_SR_current,border_Vcorr_width,back_16,force_BF_1,BF_corr,BF_slope,force_max_1,double_ref)
        
        do_OAR_id19_2017('covid_tetra_acquisition_slave_OAR',first,last,number_of_jobs,parentdir,start_now,gpu_cpu,walltime,param_string);
        
        waiting=1;
        restart_flag=0;
        job_restart=0;
        checkingtime=30;
        waiting_time=50;
        file_type='edf';
        secure_process=1;
        number_of_trials=1;
        slices_per_job=50;
        final_nb=last;
        
        [waiting, number_of_jobs,restart_flag,job_restart]=OAR_process_checker(resultdir,checkingtime,waiting_time,file_type,secure_process,number_of_trials,job_restart,slices_per_job,final_nb);
        
        
        fid=fopen('tetra_acquisition.info','w+');
        fwrite(fid,'done','uchar');
        fclose(fid);
        ! chmod 777  tetra_acquisition.info
    else
        if test>0
        first=test;
        last=test;
        else
           % first=0
             last=nvue;
        end
        
        fprintf('starting the slave \n')

        covid_tetra_acquisition_slave_OAR(first,last,parentdir,resultdir,namestr,HA_scan,TA_scan,left_pad_one,num_pass,nvue,acc_nb_frames,lateral_shift,max_SR_current,border_Vcorr_width,back_16,force_BF_1,BF_corr,BF_slope,force_max_1,double_ref)
    end


end
