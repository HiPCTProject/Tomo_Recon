% macro to start the sequence of processing linked to the preparation of md1252 experiment scans about covid done in local tomography and hald-acquisition
% available preset are 'core_biopsies' and 'zoom6'
% origin Paul Tafforeau ESRF 2020

function covid_pipeline (radix,preset)


switch preset
    
    case 'large_field'
        do_cleaning      =1   % remove all the previous reconstruction files as well as the previous references
        do_proj          =0   % for scans on axis, calculate the normalized projection of all the radiographs using SRCurrent
        do_ref_scan      =1   % uses a reference scan to generate the new references for each sub-scan
        do_ref_from_scan =0   % generate off axis references from series of scans based on the radix with defined parameters for HR/LR calculations. If 1 uses all the scans, if >1 uses scans up to this number
        do_ref_opt       =0   % general optimization of the references for first integration of ring artefacts and eventual compensation of optic darkening
        do_scan_opt      =1   % starts covid_half_acquisition_master_OAR that will generate a new scan with all SRCurrent and darkening taken into account, with only two homogeneous references and back in 16 b
        
     case 'large_field_off_axis'
        do_cleaning      =1  
        do_proj          =0  
        do_ref_scan      =0  
        do_ref_from_scan =1  
        do_ref_opt       =0  
        do_scan_opt      =1  
            
     case 'zoom6_on_axis'
        do_cleaning      =1  
        do_proj          =1  
        do_ref_scan      =0   
        do_ref_from_scan =0  
        do_ref_opt       =0   
        do_scan_opt      =1   
       
    case 'zoom6'
        do_cleaning      =1  
        do_proj          =0  
        do_ref_scan      =0   
        do_ref_from_scan =1  
        do_ref_opt       =0   
        do_scan_opt      =1   
   
    case 'zoom6_hard'
        do_cleaning      =1   
        do_proj          =0   
        do_ref_scan      =1  
        do_ref_from_scan =0   
        do_ref_opt       =0   
        do_scan_opt      =1   
       
    
    case 'core_biopsies'
        do_cleaning      =1   
        do_proj          =0   
        do_ref_scan      =0   
        do_ref_from_scan =1  
        do_ref_opt       =1  
        do_scan_opt      =1  
        
    case 'zoom2'
        do_cleaning      =1   
        do_proj          =0   
        do_ref_scan      =1   
        do_ref_from_scan =1  
        do_ref_opt       =0   
        do_scan_opt      =1   
        
    case 'zoom1'
        do_cleaning      =1   
        do_proj          =0   
        do_ref_scan      =0   
        do_ref_from_scan =1  
        do_ref_opt       =1   
        do_scan_opt      =1    
        
    case 'tubes'  % to be used for samples scanned in tubes also in the lid, and that are reconstructed using the local tomography option of pyhst2
        do_cleaning      =1   
        do_proj          =1   
        do_ref_scan      =0  % to be tested if it is more efficient or not considering that the processing can be done with local tomo option in pyhst2
        do_ref_from_scan =0  
        do_ref_opt       =1  
        do_scan_opt      =0   
        
end



%%%%%%%%%%%%%%%%%%%%%
% details of preset %
%%%%%%%%%%%%%%%%%%%%%

switch preset
    
    case 'large_field'
        
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=1000; %   number of projections used to calculated the high frequencies in the references
        inscan_med_LF=200; %  number of projections used to calculate the low frequencies in the references
        HF_LF=50; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)
 
    case 'large_field_off_axis'
        
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=600; %   number of projections used to calculated the high frequencies in the references
        inscan_med_LF=200; %  number of projections used to calculate the low frequencies in the references
        HF_LF=50; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)
 
    case 'zoom6_on_axis'
        
        % preset for do_ref_scan
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=1000; %  number of projections used to calculated the high frequencies in the references
        inscan_med_LF=500; % number of projections used to calculate the low frequencies in the references
        HF_LF=100; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)
 
    case 'zoom6'
        
        % preset for do_ref_scan
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=100; %  number of projections used to calculated the high frequencies in the references
        inscan_med_LF=400; % number of projections used to calculate the low frequencies in the references
        HF_LF=100; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)
  
    case 'zoom6_hard'
        
        % preset for do_ref_scan
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=1000; %   number of projections used to calculated the high frequencies in the references
        inscan_med_LF=200; %  number of projections used to calculate the low frequencies in the references
        HF_LF=100; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)
        
    case 'core_biopsies'
        
        % preset for do_ref_scan
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=600; %  number of projections used to calculated the high frequencies in the references
        inscan_med_LF=200; %   number of projections used to calculate the low frequencies in the references
        HF_LF=250; % filter size to separate the LF and HF in the projections
        use_med_scans=1; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)
    
    case 'zoom2'
        
        % preset for do_ref_scan and ref_from_scan
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=600; %  number of projections used to calculated the high frequencies in the references
        inscan_med_LF=200; %  number of projections used to calculate the low frequencies in the references
        HF_LF=200; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)    
  
    case 'zoom1'
        
        % preset for do_ref_scan and ref_from_scan
        new_refon=100 ;   % calculate new references every N projections
        inscan_med_HF=600; %  number of projections used to calculated the high frequencies in the references
        inscan_med_LF=200; %  number of projections used to calculate the low frequencies in the references
        HF_LF=400; % filter size to separate the LF and HF in the projections
        use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)         

     case 'tubes'
        
        % preset for do_ref_scan
        new_refon=500 ;   % calculate new references every N projections
        inscan_med_HF=1000; %  number of projections used to calculated the high frequencies in the references
        inscan_med_LF=500; %   number of projections used to calculate the low frequencies in the references
        HF_LF=250; % filter size to separate the LF and HF in the projections
        use_med_scans=1; % do the integration using a median of the scans (1) or an average (0)
        use_med_proj=1; % do the integration of the projections using a median (1) or an average (0)
        
end





dirlist=dir([radix '*_']);
dirnum=size(dirlist,1);
dirname={dirlist.name};

fprintf ('I found %1.0f scans to be processed \n',dirnum);

%% cleaning all the scans to ensure proper start

if do_cleaning==1
    
    clean_scan_series ([radix '*'])
    cmd=sprintf('rm -rf %s*_/refHST*',radix);
    unix(cmd)
    
    
end

%% preparing the normalized projections of each scan and calculating the general projection and dark

if do_proj==1
    
    
    covid_total_mean_master_OAR (radix)
    
    add_ref_scan=0;
    
    if do_ref_scan==1
        disp('preparing also the projection for the reference scan')
        
        
        ref_scan_list=dir([radix '*REF*'])
        ref_scan_num=size(ref_scan_list,1);
        
        if ref_scan_num==1
            ref_scan_name={ref_scan_list.name};
            ref_scan_name=ref_scan_name{1};
            disp('I found one corresponding reference scan, I use it for the processing')
        elseif ref_scan_num>1
            disp('I found more than one reference scan for this series, please investigate')
            return
        else
            disp('There is no available reference scan for this series. Either the name is not correct : radix*REF*, or it does not exists. Please rename the scan if existing, or select another strategy for the references')
            return
        end
        
        covid_total_mean_master_OAR (ref_scan_name)
        
        add_ref_scan=1;
        
    end
    
    
    projlist=dir([radix '*/proj_max_SRcur_norm.edf']);
    projnum=size(projlist,1);
    t=0;
    pause(60)
    
   
    
    while projnum<dirnum+add_ref_scan
        
        projlist=dir([radix '*/proj_max_SRcur_norm.edf']);
        projnum=size(projlist,1);
        t=t+1;
        fprintf('processing of the scans normalized projections is still running after %3.3i minutes, typical time is lower than 120 minutes, %2.2i files ready on a total of %2.2i \r',t,projnum,dirnum+add_ref_scan)
        pause(60)
        
        if t>120
            disp('please check if the process is still running, I stop the processing for the moment')
            return
        end
        
    end
    
end


%% preparing a new set of references from a reference scan whose name is using the radix

if do_ref_scan>0
    
    ref_scan_list=dir([radix '*REF*'])
    ref_scan_num=size(ref_scan_list,1);
    
    if ref_scan_num==1
        ref_scan_name={ref_scan_list.name};
        ref_scan_name=ref_scan_name{1};
        disp('I found one corresponding reference scan, I use it for the processing')
    elseif ref_scan_num>1
        disp('I found more than one reference scan for this series, please investigate')
        return
    else
        disp('There is no available reference scan for this series. Either the name is not correct : radix*REF*, or it does not exists. Please rename the scan if existing, or select another strategy for the references')
        return
    end
    
    
    
    if do_proj==0
        
        disp('configuration for a scan off axis with partial angular projections from a reference scan') 
    
        covid_pipeline_scan_ref_master_OAR(ref_scan_name,new_refon,inscan_med_HF,inscan_med_LF,HF_LF,use_med_scans,use_med_proj,1,1,0)
 
   
    
    reflist=dir('refHST/refHST*.edf');
    refnum=size(reflist,1);
    t=0;
    fprintf('checking every minute if the processing is finished or not. in case of no progress, I will stop after 120 minutes without new files \r')
    processed_files=refnum;
    
    
    while refnum<floor(6000/new_refon+1)
        pause(60)
        reflist=dir('refHST/refHST*.edf');
        refnum=size(reflist,1);
        t=t+1;
        if refnum>processed_files
            t=0;
        end
        fprintf('processing of the references from reference scan is still running after %3.3i minutes, typical time is lower than 120 minutes, %2.2i files ready on a total of %2.2i \r',t,refnum,floor(6000/new_refon+1))
        pause(60)
        
        if t>120
            disp('nothing happened during the last 120 minutes, please check if the calculation of the references from the ref scan is still running, I stop the processing for the moment')
            return
        end
        
    end
    
    
    else
    
        disp ('configuration for a scan on axis with references from a reference scan using a single projection of all the angles')
        
        
    covid_simple_ref_writing (ref_scan_name,new_refon)
        
        
        
        
    end
    
    
    covid_scan_local_tomo_ref_update (radix,new_refon)
    
    
end


%% preparing a new set of references from a reference scan whose name is using the radix

if do_ref_from_scan>0
    
    if do_ref_from_scan==1
        first_dir=1
        last_dir=1
    else
        first_dir=1
        last_dir=do_ref_from_scan
    end
    
        
    covid_pipeline_scan_ref_master_OAR(radix,new_refon,inscan_med_HF,inscan_med_LF,HF_LF,use_med_scans,use_med_proj,first_dir,last_dir,0)
    
    
    reflist=dir('refHST/refHST*.edf');
    refnum=size(reflist,1);
    t=0;
    fprintf('checking every minute if the processing is finished or not. in case of no progress, I will stop after 60 minutes without new files \r')
    processed_files=refnum;
    
    
    while refnum<floor(6000/new_refon+1)
        pause(60)
        reflist=dir('refHST/refHST*.edf');
        refnum=size(reflist,1);
        t=t+1;
        if refnum>processed_files
            t=0;
        end
        fprintf('processing of the references from reference scan is still running after %3.3i minutes, typical time is lower than 60 minutes, %2.2i files ready on a total of %2.2i \r',t,refnum,floor(6000/new_refon+1))
        pause(60)
        
        if t>60
            disp('nothing happened during the last 60 minutes, please check if the calculation of the references from the ref scan is still running, I stop the processing for the moment')
            return
        end
        
    end
    
    
    covid_scan_local_tomo_ref_update (radix,new_refon)
    
    
end



%% starting the process of scans optimization, darkening of optic compensation and pre-correction of the rings

if do_ref_opt
    
    disp ('starting the process of scans optimization, darkening compensation and pre-correction of the rings')
    
    covid_general_ref_optimization (radix,preset)
    
end

%% preparation of corrected scans with optimization of the half-acquisition parameters

if do_scan_opt
    
    covid_master_half_acquisition_master_OAR (radix,preset)
    
end

end

%
% cmd=sprintf('du -h PROCESSING/%s*',radix);
% unix(cmd)
%
% cd ('PROCESSING')
%
% fprintf('if everything is OK and all the scans are of the same size, you can start octave to prepare the reconstruction using fastsetup3_PT and ftseries3_PT followed by ftseries3_column_PT \n')
%
% ! octave
%
% fprintf('after the fasttomo/octave, you can start the reconstruction process using covid_tomo_rec_series(radix_without_star,'covid_HR')
%
%
% end


