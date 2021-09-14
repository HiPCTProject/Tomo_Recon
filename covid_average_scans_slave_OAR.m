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



function covid_average_scans_slave_OAR (first,last,wdir,radix,test,new_refon,inscan_med_HF,inscan_med_LF,HF_LF,use_med_scans,use_med_proj,first_dir,last_dir,no_OAR)

if isdeployed
    first=str2num(first)
    last=str2num(last)
    test=str2num(test)
    new_refon=str2num(new_refon)
    inscan_med_HF=str2num(inscan_med_HF)
    inscan_med_LF=str2num(inscan_med_LF)
    HF_LF=str2num(HF_LF)
    use_med_scans=str2num(use_med_scans)
    use_med_proj=str2num(use_med_proj)
    first_dir=str2num(first_dir)
    last_dir=str2num(last_dir)
    no_OAR=str2num(no_OAR)
end


first
last
wdir
radix
test
new_refon
inscan_med_LF
inscan_med_HF
HF_LF
use_med_scans
use_med_proj
first_dir
last_dir
no_OAR


close all

cd (wdir)


dirlist=dir([radix '*']);
dirnum=size(dirlist,1);
dirname={dirlist.name};


if test>0
    first=test;
    last=test;
end




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



% read SR mode from XML
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
    
      
    
    %% first loop for each projection
    
    for i=first:new_refon:last
        
        fprintf('processing all the projections around the %4.4i one\n',i)
        
        final_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,resultdir,resultdir,i);
        
        if test>0
            figure (1)
        end
        
        tic
        
        %% initialisation on the first projection
        
        namedir=dirname{1};
        imname=sprintf('%s/%s/%s%4.4i.edf',parentdir,namedir,namedir,i);
        
        fp=fopen(imname,'r');
        hd=readedfheader(fp);
        fclose(fp);
        SRcurrent=findheader(hd,'SRCUR','float') ;
        if isempty (SRcurrent);
            SRcurrent=max_SR_current ;
        elseif SRcurrent==-1
            SRcurrent=max_SR_current ;
        else
            SRcurrent=max_SR_current ;
        end
        
        a=(single(edfread(imname))-100)/SRcurrent*max_SR_current+100;
      
        
        if use_med_scans==1
            medim(:,:,1)=a*0;
        end
        
        if use_med_proj==1
            scan_ref_HF(:,:,1)=a*0;
            scan_ref_LF(:,:,1)=a*0;
        else
            imsum=a*0;
            scan_imsum_HF=a*0;
            scan_imsum_LF=a*0;
        end
        
        
        total=0;
        
        %% loop over all the directories
        
        
        for j=first_dir:last_dir
           
           
            
            
            t1=toc;
            
            namedir=dirname{j};
            
            %% loop along each scan projections
            
            HF_scan_total=0;
            LF_scan_total=0;
            
            for k=ceil(-inscan_med_HF/2):ceil(inscan_med_HF/2)
                
                projnum=i+k;
                
                fprintf('processing projection %4.4i \r',projnum)
                
                if projnum<0
                    projnum=nvue+projnum;
                end
                
                if projnum>nvue
                    projnum=k;
                end
                
                
                imname=sprintf('%s/%s/%s%4.4i.edf',parentdir,namedir,namedir,projnum);
                
                fp=fopen(imname,'r');
                hd=readedfheader(fp);
                fclose(fp);
                SRcurrent=findheader(hd,'SRCUR','float') ;
                if isempty (SRcurrent)
                    SRcurrent=max_SR_current ;
                elseif SRcurrent==-1
                    SRcurrent=max_SR_current ;
                else
                    SRcurrent=max_SR_current ;
                end
                
                a=(single(edfread(imname))-100)/SRcurrent*max_SR_current+100;
                
                HF_scan_total=HF_scan_total+1;
                
                a_LF=blurring_rapid(a,HF_LF,'replicate');
                a_HF=a-a_LF;
                
                                
                
                if use_med_proj==1
                    scan_ref_HF(:,:,HF_scan_total)=a_HF;
                else
                    scan_imsum_HF=scan_imsum_HF+a_HF;
                end
                
                
                if k>ceil(-inscan_med_LF/2) && k<ceil(inscan_med_LF/2)+1
                        LF_scan_total=LF_scan_total+1;
                       
                        if use_med_proj==1
                            scan_ref_LF(:,:,LF_scan_total)=a_LF;
                        else
                            scan_imsum_LF=scan_imsum_LF+a_LF;
                        end
                        
                end
                                               
            end
            
            if use_med_proj==1
                scan_ref_HF=median(scan_ref_HF,3);
                scan_ref_LF=median(scan_ref_LF,3);
            else
                scan_ref_HF=scan_imsum_HF/HF_scan_total; 
                scan_ref_LF=scan_imsum_LF/LF_scan_total; 
            end
            
            scan_ref=scan_ref_HF+scan_ref_LF;
            fprintf('the average of the reference derived from this scan is %1.0f \n',mean2(scan_ref))
            
            if test>0
              
                imshow (scan_ref',[]);drawnow;
           
            end
            
            
            total=total+1;
            
             if use_med_proj==1
                scan_ref_HF=scan_ref_HF*0;
                scan_ref_LF=scan_ref_LF*0;
                 
             else
                scan_imsum_HF=scan_imsum_HF*0;
                scan_imsum_LF=scan_imsum_LF*0;    
                scan_ref_HF=scan_ref_HF*0;
                scan_ref_LF=scan_ref_LF*0;   
            end
            
            
            
            
            
            if use_med_scans==1
                medim(:,:,total)=scan_ref;
                
            else
                imsum=imsum+scan_ref;
                fprintf('the average of the averaged references derived from this scan is %1.0f \n',mean2(imsum)/total)
            end
           
            
            
            
            
            t2=toc-t1;
            t3=toc;
            
            fprintf('\n')
            fprintf('subscan %3.3i has been processed for reference %4.4i in %1.1fs   total time for this ref is %1.1fs\n',j,i,t2,t3)
                       
            t1=t2;
            
            
            
        end
        
        if use_med_scans==1
            im_final=median(medim,3);
        else
            im_final=imsum/total;
        end
        
        if test>0
            imshow(im_final',[]);drawnow
            mean2(im_final)
        end

        t3=toc;
        
        fprintf('refHST%4.4i.edf has been processed in %1.1fs\n',i,t3)
        
        if test==0
            fprintf('writing the file %s\n',final_name);
            edfwrite (final_name,im_final,'float32');
        end
        
        
        
        
        
    end
    
    
   



end





