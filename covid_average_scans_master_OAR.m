% macro to generate a series of references to cope with local tomography on
% large columns, even if off axis, using averageing or median of
% projections and over scan series. The result will be a series of refHST
% files that can be added to the scans to correct with a retro-fit of the
% SRcurrent values based on the closest projection each time. A simple
% modification of the info file would then make possible to use these new
% references.
% origin Paul 15/06/2020 for covid-19 experiments
% results of this program can be injected in a scan using the macro
% covid_scan_local_tomo_ref_update
% origin Paul Tafforeau ESRF 2020



function covid_average_scans_master_OAR (radix,test,varargin)

close all


new_refon=100 ;   % calculate new references every N projections
inscan_med_HF=1000; % best 400 for reference scan off axis  number of projections used to calculated the high frequencies in the references
inscan_med_LF=200; % best 50 for reference scan off axis  number of projections used to calculate the low frequencies in the references
HF_LF=200; % filter size to separate the LF and HF in the projections
use_med_scans=0; % do the integration using a median of the scans (1) or an average (0)
use_med_proj=0; % do the integration of the projections using a median (1) or an average (0)


dirlist=dir([radix '*']);
dirnum=size(dirlist,1);
dirname={dirlist.name};


switch nargin
    case 2
        first_dir=1;
        last_dir=dirnum;
    case 3
        first_dir=varargin{1};
        last_dir=dirnum;
    case 4
        first_dir=varargin{1};
        last_dir=varargin{2};
end



%% OAR PARAMS

no_OAR=0  ; %put to 1 to deactivate the oar submission

start_now       = true  ; % put true to start the processing directly after parameters acceptation of false to create only the cmd file


warning ('OFF')
gpu_cpu = 'both';
walltime='2:00:00';



%%


fprintf('you will calculate the averaging of %1.0i scans\n',dirnum)

parentdir=cleandirectoryname(pwd)

resultdir='refHST';  % this will directly generate pictures to be usable as multi-refHST for all the other scans


%% initialisation of parameters using the first scan

cd (dirname{1})

% names for the scan processing

n1=cleandirectoryname(pwd);
pos=findstr(n1,'/');
n2=n1(pos(end)+1:end);

% information from info-file

fp=fopen([n1 '/' n2,'.info'],'r');
if fp~=-1 % *.info exists
    hd=fscanf(fp,'%c');
    fclose(fp);
    nvue =findheader(hd,'TOMO_N','integer');
    
    
else	% *.info does not exist
    
    disp([n2,'.info could not be found!']);
    nvue=input('please indicate the number of projections  ');
    
end


cd (parentdir)





%% starting of test or of parallelisation

if test>0 || no_OAR==1
    if test>0
        first=test
        last=test
    else
        first=0
        last=nvue
    end
    
    
    covid_average_scans_slave_OAR (first,last,pwd,radix,test,new_refon,inscan_med_HF,inscan_med_LF,HF_LF,use_med_scans,use_med_proj,first_dir,last_dir,no_OAR);
    
else
    
    number_of_jobs  = floor(nvue/new_refon) +1   ;
    fprintf('you are starting %1.0i jobs in OAR \n',number_of_jobs)
    
    first=0
    last=number_of_jobs*(new_refon-1)
        
   
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
        
    
    
        param_string=sprintf('%s  %1.0f   %1.0i   %1.0f   %1.0f  %1.0f  %1.0f   %1.0f   %1.0f   %1.0f  %1.0f',radix,test,new_refon,inscan_med_HF,inscan_med_LF,HF_LF,use_med_scans,use_med_proj,first_dir,last_dir,no_OAR)
        
        do_OAR_id19_2017('covid_average_scans_slave_OAR',first,last,number_of_jobs,parentdir,start_now,gpu_cpu,walltime,param_string);
     
      
    
    
end


 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    






end



