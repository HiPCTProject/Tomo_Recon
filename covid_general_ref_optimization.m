% macro to inject multi-references calculated from a series of scans in
% local tomography to cope with the low frequencies problems. It will use
% the high frequencies of the median of all the projections from all scans,
% but will keep the low frequencies from each original reference to keep
% the overall correction effect of local tomography in case of of-axis case.
% origin Paul Tafforeau ESRF 2020


function covid_general_ref_optimization (radix,preset)

close all

switch preset
    
    case 'large_field'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=20           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=20    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=100   ; % length of the filter for removal of horizontal structures in the ring picture
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
        
    case 'core_biopsies'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=50           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=50    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=100   ; % length of the filter for removal of horizontal structures in the ring picture
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
      
    case 'zoom6_on_axis'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=50           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=50    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=100   ; % length of the filter for removal of horizontal structures in the ring picture
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
        
    case 'zoom6'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=50           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=50    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=100   ; % length of the filter for removal of horizontal structures in the ring picture
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
        
    case 'zoom6_hard'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=50           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=50    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=100   ; % length of the filter for removal of horizontal structures in the ring picture
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
        
    case 'zoom2'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=100           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=50    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=100   ; % length of the filter for removal of horizontal structures in the ring picture
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
        
    case 'zoom1'
        new_refon=100         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=100           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=100    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=200   ; % length of the filter for removal of horizontal structures in the ring picture    
        test_darkening=0        ;
        LF_by_max=0           ; % if 1, the low frequencies larger than 10 pixels are combined by max projection instead fo median projection. The median is used for fine details
       
    case 'tubes'
        new_refon=500         ; % creates a new set of reference every new_refon from the general reference calculated from all the scans
        ring_size=0           ; % if >0, uses the normalized average of projections to correct for the main ring artefacts by checking differences with the general ref
        ring_hori_Vsize=0    ; % size of the filter for exclusion of horizontal artefacts
        ring_hori_Hsize=0   ; % length of the filter for removal of horizontal structures in the ring picture    
        test_darkening=0        ;
        LF_by_max=10           ; % if >0 the low frequencies larger than the given value are combined by max projection instead fo median projection. The median is used for fine details

end

dirlist=dir([radix '*_']);
dirnum=size(dirlist,1);
dirname={dirlist.name};

parentdir=cleandirectoryname(pwd)


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

%% read SR mode from XML
xmlfilename = sprintf('%s/%s.xml',n1,n2);



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
    
end
%% Dealing with accumulation
cfgfilename=sprintf('%s/%s.cfg',n1,n2');
fp2=fopen(cfgfilename,'r');
if fp2~=-1;
    [acc_nb_frames]=str2num(read_cfg_file_dev(cfgfilename))
    fclose(fp2);
else
    acc_nb_frames=1;
end
fprintf('--------------------------------------\nAccumulation=             %i\n--------------------------------------\n\n',acc_nb_frames);


%%

if exist ('proj_max_SRcur_norm.edf')
    disp('the preprocessing looks OK, I continue the process')
    general_dark=edfread('proj_max_SRcur_norm.edf')*0;
else
    disp('no normalized projection, please run first covid_total_mean');
    cd (parentdir)
    return
end




if exist ('dark.edf')
    general_dark=edfread('dark.edf');
    if std2(general_dark)>0
        real_dark=1;
        total=1;
    else
        real_dark=0;
        general_dark=general_dark*0+100*acc_nb_frames;
        
    end
else
    
    general_dark=general_dark*0+100*acc_nb_frames;
    real_dark=0;
    
end


cd (parentdir)



%% processing of the dark

if real_dark==1
    disp('processing of the dark')
    for i=2:dirnum
        
        namedir=dirname{i};
        cd(namedir)
        dark=edfread('dark.edf');
        general_dark=general_dark+dark;
        total=total+1;
        cd (parentdir)
    end
    general_dark=general_dark/total;
    edfwrite('general_dark.edf',general_dark,'float32');
end

%% processing of the normalized projections for references, putting all of them in a large matrix

ref_matrix=zeros(size(general_dark,1),size(general_dark,2),dirnum);

if LF_by_max>0
   ref_max_matrix=ref_matrix; 
end

ref_levels=zeros(1,1,dirnum);
max_ref_level=0;
min_ref_level=1e20;


for i=1:dirnum
    
    namedir=dirname{i};
    cd(namedir)
    ref=edfread('proj_max_SRcur_norm.edf');
    ref_level=mean2(ref-general_dark);
    
    if ref_level>max_ref_level
        max_ref_level=ref_level;
    end
    
    if ref_level<min_ref_level
        min_ref_level=ref_level;
    end
    
    ref_matrix(:,:,i)=ref;
    
    if LF_by_max>0
       ref_max_matrix(:,:,i)=blurring_rapid(ref,LF_by_max,'replicate'); 
    end
    
    ref_levels(:,:,i)=ref_level;
    cd(parentdir)
    
end

if test_darkening>0
    if max_ref_level/min_ref_level>1.05
        disp('there was apparently more than 5% of darkening of the optic, we take it into account')
        correct_darkening=1;
        for i=1:size(ref_matrix,3)
            ref_norm=ref_matrix(:,:,i);
            ref_matrix(:,:,i)=ref_norm/mean2(ref_norm)*max_ref_level;
            if LF_by_max
                ref_max_norm=ref_max_matrix(:,:,i);
                ref_max_matrix(:,:,i)=ref_max_norm/mean2(ref_norm)*max_ref_level;
            end
            
            
        end
    else
        correct_darkening=0;
    end
else
    correct_darkening=0;
end



if LF_by_max>0
    ref_med=median(ref_matrix,3);
    ref_med2=ref_med-blurring_rapid(ref_med,LF_by_max,'replicate');
    ref_max=max(ref_max_matrix,[],3);
    final_ref=ref_med2+ref_max+general_dark;
    
else
    final_ref=median(ref_matrix,3)+general_dark;
end


%  figure;imshow(final_ref',[]);


edfwrite('general_ref.edf',final_ref,'float32');


%%

% application of the general ref and dark to the different scans taking into account the darkening of the optic if detected.

for i=1:dirnum
    
    namedir=dirname{i};
    cd(namedir)
    
    
    n1=cleandirectoryname(pwd);
    pos=findstr(n1,'/');
    n2=n1(pos(end)+1:end);
    
    %% application of ring artefacts pre-correction
    if ring_size>0
        
        if exist('proj_max_SRcur_norm.edf');
        
        disp('trying to optimize the scan for ring artefacts using the normalized projection of all the radiographs')
        ring_im=edfread('proj_max_SRcur_norm.edf');
        ring_im=((ring_im-general_dark)/ref_levels(:,:,i)*max_ref_level)./(final_ref-general_dark);
        %   ring_im=(ring_im-1)*ref_levels(:,:,i);
        
        
        ring_im=ring_im-medfilt_rapid(ring_im,[ring_size ring_size],'replicate');
        
        % removing of horizontal structures that are probably due to the sample
        ring_hori=ring_im-medfilt_rapid(ring_im,[ring_hori_Vsize ring_hori_Vsize],'symmetric');
        ring_hori=medfilt_rapid(ring_hori,[ring_hori_Hsize 1],'symmetric');
        ring_hori=medfilt_rapid(ring_hori,[ring_hori_Hsize 1],'symmetric');
        ring_hori=medfilt_rapid(ring_hori,[ring_hori_Hsize 1],'symmetric');
        ring_hori=ring_hori-medfilt_rapid(ring_hori,[ring_hori_Vsize ring_hori_Vsize],'symmetric');
        ring_im=ring_im-ring_hori;
        ring_im=-ring_im;
        
        
        edfwrite('rings_im.edf',ring_im,'float32');
      %  figure;imshow(ring_im',[]); drawnow
      
        end
                
        
    end
    
    if correct_darkening==1
        
        % checking first picture of the scan
        
        fname=sprintf('%s%04d.edf',n2,50);
        
        fp2=fopen(fname);
        
        if fp2~=-1
            hd2=fscanf(fp2,'%c',1024);
            fclose(fp2);
            
            SCAN_SRcurrent=findheader(hd2,'SRCUR','float');
            
        end
        
        first_im=edfread(fname);
        first_im_abs_level=mean2(first_im-general_dark)/SCAN_SRcurrent*max_SR_current;
        
        
        % checking first picture of the scan
        
        fname=sprintf('%s%04d.edf',n2,nvue);
        
        fp2=fopen(fname);
        
        if fp2~=-1
            hd2=fscanf(fp2,'%c',1024);
            fclose(fp2);
            
            SCAN_SRcurrent=findheader(hd2,'SRCUR','float');
            
        end
        
        last_im=edfread(fname);
        last_im_abs_level=mean2(last_im-general_dark)/SCAN_SRcurrent*max_SR_current;
        
        % calculation of darkening factor during the scan
        
        darkening_factor=first_im_abs_level/last_im_abs_level
        
        if darkening_factor<1
            disp('there is something weird with the darkening, it seems to have reduced during the scan')
        end
        
        
    end
    
    
    %%  creating the new set of references from the general ones for compensation of SRcurrent and eventually of optic darkening
    
    
    for j=0:new_refon:nvue
        
        fname=sprintf('%s%04d.edf',n2,j);
        
        fp2=fopen(fname);
        
        if fp2~=-1
            hd2=fscanf(fp2,'%c',1024);
            fclose(fp2);
            
            SCAN_SRcurrent=findheader(hd2,'SRCUR','float');
            
        end
        
        new_refname=sprintf('refHST%4.4i.edf',j);
        new_ref=(final_ref-general_dark)/max_SR_current*SCAN_SRcurrent;
        
        
        if ring_size>0
            
            new_ref=new_ref./((ring_im+1)*mean2(new_ref))*mean2(new_ref);
            
            
        end
        
        
        if correct_darkening==1
            new_ref=new_ref/max_ref_level*ref_levels(:,:,i);
            
            % intra-scan correction to cope with the darkning during the scan
            
            dark_factor=(darkening_factor-1)/nvue*j+1-(darkening_factor-1)/2;
            new_ref=(new_ref)/dark_factor;
            
        end
        
        
        new_ref=new_ref+general_dark;
        %  mean2(new_ref)
        
        edfwrite(new_refname,new_ref,'float32');
        fprintf('the new reference %4.4i of the scan %2.2i has been written \r',j,i);
        
    end
    
    %%
    
    if ~exist('dark_orig.edf') && real_dark==1
        cmd='mv dark.edf dark_orig.edf';
        system(cmd);
    else
        fprintf('the original dark has already been saved \n');
    end
    
    
    edfwrite('dark.edf',general_dark,'float32')
    
    %% writing the general dark
    
    cd (parentdir)
    
    
    
    
    
    
    
    %% updating info file with the correct refon in case of use of multiple references
    
    infoname=sprintf('%s/%s.info',n1,n2);
    fid = fopen(infoname,'r');
    info=fscanf(fid,'%c');
    fclose(fid);
    
    stringbeg='REF_ON=                ';
    posbeg1 = findstr(info,stringbeg)+size(stringbeg,2);
    stringend='REF_N=                ';
    posend1 = findstr(info,stringend);
    
    new_string1=sprintf('%1.0i\n',new_refon);
    new_info=[info(1:posbeg1-1) new_string1 info(posend1:end)];
    
    fid2=fopen(infoname,'w');
    fwrite(fid2,new_info,'uchar');
    fclose(fid2);
    
    fprintf('the new info file has been updated for the refon \n');
    
    
    
    
    
end


end



