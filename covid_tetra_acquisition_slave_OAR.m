% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% origin Paul Tafforeau ESRF 2020


function covid_tetra_acquisition_slave_OAR(first,last,parentdir,resultdir,namestr,HA_scan,TA_scan,left_pad_one,num_pass,nvue,acc_nb_frames,lateral_shift,max_SR_current,border_Vcorr_width,back_16,force_BF_1,BF_corr,BF_slope,force_max_1,double_ref)

if isdeployed
    first=str2num(first)
    last=str2num(last)
    left_pad_one=str2num(left_pad_one)
    num_pass=str2num(num_pass)
    nvue=str2num(nvue)
    acc_nb_frames=str2num(acc_nb_frames)
    lateral_shift=str2num(lateral_shift)
    max_SR_current=str2num(max_SR_current)
    border_Vcorr_width=str2num(border_Vcorr_width)
    back_16=str2num(back_16)
    force_BF_1=str2num(force_BF_1)
    BF_corr=str2num(BF_corr)
    BF_slope=str2num(BF_slope)
    force_max_1=str2num(force_max_1)
    double_ref=str2num(double_ref)
end

if first==last
    test=first;
else
    test=0;
end


do_preprocessing=1

%% reading of the two max SRcurrent references for HA and TA scans

if double_ref==0
    if exist('HA_REF.edf')
        HA_REF=single(edfread('HA_REF.edf'));
    else
        fprintf('I cannot find the generic reference for HA scans that should be called HA_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end

    if exist('TA_REF.edf')
        TA_REF=single(edfread('TA_REF.edf'));
    else
        fprintf('I cannot find the generic reference for TA scans that should be called TA_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end
else
    if exist('HA_B_REF.edf')
        HA_B_REF=single(edfread('HA_B_REF.edf'));
    else
        fprintf('I cannot find the generic reference for the beginning of HA scans that should be called HA_B_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end

    if exist('TA_B_REF.edf')
        TA_B_REF=single(edfread('TA_B_REF.edf'));
    else
        fprintf('I cannot find the generic reference for the beginning of TA scans that should be called TA_B_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end 
    if exist('HA_E_REF.edf')
        HA_E_REF=single(edfread('HA_E_REF.edf'));
    else
        fprintf('I cannot find the generic reference for the end of HA scans that should be called HA_E_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end

    if exist('TA_E_REF.edf')
        TA_E_REF=single(edfread('TA_E_REF.edf'));
    else
        fprintf('I cannot find the generic reference for the end of TA scans that should be called TA_E_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end 
    
    
    scannum=str2num(HA_scan(end-3:end-1));
    scan_radix=(HA_scan(1:end-4));
    nos=size(dir([scan_radix '*']),1);
    
    W2=scannum/nos;
    W1=1-W2;
    
    HA_REF=W1*HA_B_REF+W2*HA_E_REF;
    TA_REF=W1*TA_B_REF+W2*TA_E_REF;
    
        
    
end


%% preparing a dark picture

fp=fopen(sprintf('%s/%s/dark.edf',parentdir,HA_scan));
if fp~=-1
    dark=edfread(sprintf('%s/%s/dark.edf',parentdir,HA_scan));
    disp('reading dark file')
    
    if mean2(dark)<acc_nb_frames*100*0.9
        disp ('there is a problem with dark, I replace it by accumulation*100')
        dark=HA_REF*0+100*acc_nb_frames;
    end
    
else
    
    
    disp('I found no dark');
    if replace_ref==1
        disp('I create a dark at 100*accumulation in average');
        dark=HA_REF*0+100*acc_nb_frames;
    end
    
    
end

dark_level=mean2(dark);

general_ref_level=max(max2(medfilt_rapid(HA_REF-dark,[50 50],'replicate')),max2(medfilt_rapid(TA_REF-dark,[50 50],'replicate')));


%% main loop for concatenation

if  do_preprocessing>0
    preprocessing=1;
    firstim=1;
   if test>0
       step=ceil(nvue/18);
   else
       step=ceil(nvue/72);
   end
    lastim=nvue;
    itnum=1;
    disp('preprocessing');
else
    preprocessing=0;
    firstim=first;
    lastim=last;
    step=1;
    itnum=2;
end


for m=itnum:2


for i=firstim:step:lastim
    
    
    HA_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,i);
    
    fp2=fopen(HA_im_name);
    
    if fp2~=-1
        hd2=fscanf(fp2,'%c',1024);
        fclose(fp2);
        SCAN_SRcurrent=findheader(hd2,'SRCUR','float');
    end
    
    HA_im=((single(edfread(HA_im_name))-dark)/SCAN_SRcurrent*max_SR_current)./(HA_REF-dark);
    
    
    
    
    TA_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,TA_scan,TA_scan,i);
    
    fp2=fopen(TA_im_name);
    
    if fp2~=-1
        hd2=fscanf(fp2,'%c',1024);
        fclose(fp2);
        SCAN_SRcurrent=findheader(hd2,'SRCUR','float');
    end
    
    TA_im=((single(edfread(TA_im_name))-dark)/SCAN_SRcurrent*max_SR_current)./(TA_REF-dark);
    
    
    
    %% concatenation
    
    % cropping in 4 parts
    part1=imcrop(TA_im,[1 1 size(TA_im,2) size(TA_im,1)-lateral_shift-1]);
    common1=imcrop(TA_im,[1 size(TA_im,1)-lateral_shift+1 size(TA_im,2) lateral_shift]);
    part2=imcrop(HA_im,[1 lateral_shift+1 size(HA_im,2) size(HA_im,1)-lateral_shift]);
    common2=imcrop(HA_im,[1 1 size(HA_im,2) lateral_shift-1]);
    
    % processing of the common part
    
    if test>0 && preprocessing==0
        common_test=abs(common1-common2);
        test_val=mean2(common_test)*1000;
        fprintf('score value of the alignment of the common part is %0.3f. The lateral_shift value should be optimized to have the minimum score \n',test_val)
    end
    
    
    common=(common1+common2)/2; % simple version with only average
    
    for j=1:size(common1,1) % moving average for smooth concatenation
        
        Wcom1=1-(j)/(size(common1,1));
        Wcom2=1-Wcom1;
        %    fprintf('j  %4.4i  Wcom1  %0.5f  Wcom2  %0.5f \n',j,Wcom1, Wcom2)
        common(j,:,:)=common1(j,:,:)*Wcom1+common2(j,:,:)*Wcom2;
        
    end
    
    
    % concatenation
    
    concat_im=[part1' common' part2']';
    
    
    %% projections corrections
    
 
    
    
    
    for k=1:num_pass   
       
         
 if border_Vcorr_width > 0
     
        border_HF_size=border_Vcorr_width;
        border_dil=20;
        border_blur=5;
        border_threshold=0.015;
        
        %% first pass for high frequencies
        
        
        border_HF=imcrop(concat_im,[1   1    size(concat_im,2)    border_Vcorr_width-1]);
        border_HF=medfilt_rapid(border_HF,[1 ceil(size(concat_im,2)/2)],'replicate');
        border_HF=border_HF-medfilt_rapid(border_HF,[border_Vcorr_width 1],'replicate');
        border_HF=max(min((max(abs(border_HF),border_threshold)-border_threshold)*1e20,1),0);
        
        se = strel('disk',border_dil);
        border_HF=medfilt2(imdilate(border_HF,se),[3 3]);
        
        border_zeros=zeros(size(concat_im,1)-border_Vcorr_width,size(concat_im,2));
        border_HF_mask=[border_HF' border_zeros']';
        border_HF_mask=blurring_rapid(border_HF_mask,border_blur,'replicate');
        
       
        HF_border_filter=concat_im-medfilt_rapid(concat_im,[border_HF_size 1],'replicate');
        HF_border_filter=HF_border_filter.*border_HF_mask;
        
        zero_padd=zeros(border_Vcorr_width,size(concat_im,2));
        HF_padd=[zero_padd' HF_border_filter']';
        
              
        HF_border_filter=medfilt_rapid(HF_padd,[1 50],'symmetric');
        HF_border_filter=medfilt_rapid(HF_border_filter,[1 50],'symmetric');
        HF_border_filter=HF_border_filter-medfilt_rapid(HF_border_filter,[border_HF_size 1],'replicate');
        
       
        HF_border_filter=imcrop(HF_border_filter,[1 border_Vcorr_width+1 size(concat_im,2) size(concat_im,1)-1]);   
       
        concat_im=concat_im-HF_border_filter;
        
        %% second pass for lower frequencies
               
        LF_border_filter=medfilt_rapid(concat_im,[30 30],'replicate');
        LF_border_filter=LF_border_filter-medfilt_rapid(LF_border_filter,[border_Vcorr_width 1],'symmetric');
        
        border_LF=imcrop(LF_border_filter,[1   1    size(concat_im,2)    border_Vcorr_width-1]);
        border_zeros=zeros(size(concat_im,1)-border_Vcorr_width,size(concat_im,2));
        LF_border_filter=[border_LF' border_zeros']';
        
        zero_padd=zeros(border_Vcorr_width,size(concat_im,2));
        LF_padd=[zero_padd' LF_border_filter']';
       
        LF_border_filter=medfilt_rapid(LF_padd,[1 50],'symmetric');
        LF_border_filter=medfilt_rapid(LF_border_filter,[1 50],'symmetric');   

        LF_border_filter=LF_border_filter-medfilt_rapid(LF_border_filter,[border_Vcorr_width 1],'symmetric');
        LF_border_filter=imcrop(LF_border_filter,[1 border_Vcorr_width+1 size(concat_im,2) size(concat_im,1)-1]);  
            
        concat_im=concat_im-LF_border_filter;
        
%                       
%         concat_im(1:ceil((border_Vcorr_width)/2)-1,:,:)=left_border(1:ceil((border_Vcorr_width)/2)-1,:,:);
%         
%         
%         for l=1:border_Vcorr_width %ceil(border_Vcorr_width/2):ceil(border_Vcorr_width*1.5)
%             
%             Wcom1=1-(l/(border_Vcorr_width));
%             Wcom2=1-Wcom1;
%             %fprintf('column  %4.4i  Wcom1  %0.5f  Wcom2  %0.5f \n',l+ceil(border_Vcorr_width/2),Wcom1, Wcom2)
%             concat_im(l+ceil((border_Vcorr_width)/2),:,:)=left_border(l+ceil((border_Vcorr_width)/2),:,:)*Wcom1+concat_im(l+ceil((border_Vcorr_width)/2),:,:)*Wcom2;
%             
%         end
%         
    end
    
        
        
        
        
        
        
    
    
    %%
  
        
    
    if force_BF_1>0
        
        concat_max=imresize(median(concat_im),[size(concat_im,1) size(concat_im,2)]);
        concat_im=concat_im./concat_max*median(median(concat_max));
     
    end
    
    if force_max_1>0 
        concat_im_LF=blurring_rapid(concat_im,5,'symmetric');
        concat_im_HF=concat_im-concat_im_LF;
        concat_max=min(concat_im_LF,force_max_1);
        concat_im=concat_max+concat_im_HF;
        
        
    end
    
    if k==1 && preprocessing==0 && do_preprocessing>0
        
        concat_im=concat_im./proj_ref;
        
    end
    
       
    
%        
%      if left_pad_one > 0
%             concat_im=imcrop(concat_im,[1 left_pad_one size(concat_im,2) size(concat_im,1)-left_pad_one-1]);
%      end


    
    if BF_corr >0 && preprocessing==0 % test BF_norm
        
        struct_threshold=0.005;
        
        proj_HF=concat_im-medfilt_rapid(concat_im,[ceil(size(concat_im,2)/3)   ceil(size(concat_im,2)/3)],'symmetric');
        
        proj_HF_mask=max(abs(proj_HF),struct_threshold);
        
        proj_HF_mask=max(medfilt2(min((proj_HF_mask-struct_threshold)*1e20,1),[10 10]),0);
        se = strel('disk',3);
        proj_HF_mask = -(medfilt2(imdilate(proj_HF_mask,se),[3 3]))+1;
   
        proj_HF_neg = -proj_HF_mask + 1;
        
        concat_im_filt=concat_im.*proj_HF_mask+proj_HF_neg;
        
        
     for n=1:5   
         concat_im_filt=concat_im_filt.*proj_HF_mask+proj_HF_neg.*blurring_rapid(concat_im_filt,ceil(size(concat_im,2))/10,'symmetric');
     end
        
        
     %   figure;imshow(concat_im_filt',[]);impixelinfo;return
         
        
        proj_LF=medfilt_rapid (concat_im_filt,[300 100],'symmetric');
        proj_LF=blurring_rapid (proj_LF,20,'replicate');
        
        %figure;imshow(proj_LF',[]);return
       
        concat_im_filt=concat_im./proj_LF;
        
       
        concat_final=concat_im;
   
      %  figure(2);imshow([concat_final concat_im_filt]',[]);impixelinfo;return
        
        
     % smooth transition
        BF_inflex=size(concat_im,1)*BF_corr;
        BF_stiff=size(concat_im,1)/(BF_slope/2);

        BF_plot=[];
                
        for k=1:size(concat_im,1)
            
   %         Wcom1=1-(k)/ceil(size(concat_im,1)*BF_corr);
            Wcom1=(BF_inflex^BF_stiff)/(k^BF_stiff+BF_inflex^BF_stiff);
            BF_plot=[BF_plot Wcom1];
            
            Wcom2=1-Wcom1;
            concat_final(k,:,:)=concat_im_filt(k,:,:)*Wcom1+concat_im(k,:,:)*Wcom2;
            
        end
       
       if test>0 
            figure(1); plot(BF_plot)
       end
      
        concat_im=concat_final;
        
    end
    
  
         
 end
 
 
 if preprocessing>0
     if i==1
         proj_ref=concat_im;
         total=1;
     else
         proj_ref=proj_ref+concat_im;
         total=total+1;
     end
 end
 
 


if preprocessing==0

    
     if left_pad_one > 0 && BF_corr>0
            left_pad=zeros(left_pad_one,size(concat_im,2))+1;
            concat_im=[left_pad' concat_im']';
     end
    
    
    
    %% removing the reference to go back to original scale
    
    if back_16==1
        concat_im=concat_im.*general_ref_level/acc_nb_frames+dark_level/acc_nb_frames;
    else
        concat_im=concat_im.*general_ref_level+dark_level;
    end
    
    
    
    if test>0
        
        figure(2); imshow(concat_im',[]);impixelinfo
        
    else
        
        %% writing the result
        
        
        
        new_imname=sprintf('%s/%s%4.4i.edf',resultdir,namestr,i);
        fprintf('writing the new projection file %s%4.4i.edf on a total of %4.4i \r',namestr,i,nvue);
        
        if back_16==1
            edfwrite(new_imname,uint16(concat_im),'uint16');
        else
            edfwrite(new_imname,concat_im,'float32');
        end
    end
    
end

end

    if preprocessing==1
        proj_ref=proj_ref/total;

        hot_pixels=proj_ref-strong_spikes(proj_ref,0.02,[5 5]);

        proj_ref=hot_pixels+1;

        preprocessing=0;
        firstim=first
        lastim=last
        step=1


        disp ('starting the real processing');
    end


    end

if last==nvue
    
    disp ('attempting to write the new references and new dark')
    
    if back_16==1
        new_ref=uint16(concat_im*0+general_ref_level/acc_nb_frames+dark_level/acc_nb_frames);
        new_dark=uint16(concat_im*0+dark_level/acc_nb_frames);
        edfwrite(sprintf('%s/refHST0000.edf',resultdir),new_ref,'uint16');
        edfwrite(sprintf('%s/refHST%4.4i.edf',resultdir,nvue),new_ref,'uint16');
        edfwrite(sprintf('%s/dark.edf',resultdir),new_dark,'uint16');
    else
        new_ref=concat_im*0+general_ref_level+dark_level;
        new_dark=concat_im*0+dark_level;
        edfwrite(sprintf('%s/refHST0000.edf',resultdir),new_ref,'float32');
        edfwrite(sprintf('%s/refHST%4.4i.edf',resultdir,nvue),new_ref,'float32');
        edfwrite(sprintf('%s/dark.edf',resultdir),new_dark,'float32');
        
    end
    
    disp ('writting successful')
    
    disp ('copying and renaming of the .info .xml and .cfg files to keep the motor positions and other informations of the scans. Be aware that the picture sizes are not updated')
    
    system(sprintf('cp %s/%s/%s.info %s/%s.info',parentdir,HA_scan,HA_scan,resultdir,namestr))
    system(sprintf('cp %s/%s/%s.xml %s/%s.xml',parentdir,HA_scan,HA_scan,resultdir,namestr))
    system(sprintf('cp %s/%s/%s.cfg %s/%s.cfg',parentdir,HA_scan,HA_scan,resultdir,namestr))
    
    
    
    
    
    
    %% updating info file with the new picture size in horizontal
    
    infoname=sprintf('%s/%s.info',resultdir,namestr);
    fid = fopen(infoname,'r');
    info=fscanf(fid,'%c');
    fclose(fid);
    
    stringbeg='Dim_1=                  ';
    posbeg1 = findstr(info,stringbeg)+size(stringbeg,2);
    stringend='Dim_2=                  ';
    posend1 = findstr(info,stringend);
    
    new_string1=sprintf('%1.0i\n',size(concat_im,1));
    new_info=[info(1:posbeg1-1) new_string1 info(posend1:end)];
    
    fid2=fopen(infoname,'w');
    fwrite(fid2,new_info,'uchar');
    fclose(fid2);
    
    fprintf('the new info file has been updated for the size of the projections \n');
    
    
    %% updating xml file with the new picture size in horizontal
    
    xmlname=sprintf('%s/%s.xml',resultdir,namestr);
    fid = fopen(xmlname,'r');
    xml=fscanf(fid,'%c');
    fclose(fid);
    
    stringbeg='<DIM_1>';
    posbeg = findstr(xml,stringbeg)+size(stringbeg,2)
    stringend='</DIM_1>';
    posend = findstr(xml,stringend)
    
    
    new_string1=sprintf('%1.0i',size(concat_im,1));
    new_xml=[xml(1:posbeg-1) new_string1 xml(posend:end)];
    
    fid2=fopen(xmlname,'w');
    fwrite(fid2,new_xml,'uchar');
    fclose(fid2);
    
    fprintf('the new xml file has been updated for the size of the projections \n');
    
    %% updating info .cfg file with the new picture size in horizontal and the accumulation level if going back to 16 bits
    
    cfgname=sprintf('%s/%s.cfg',resultdir,namestr);
    fid = fopen(cfgname,'r');
    cfg=fscanf(fid,'%c');
    fclose(fid);
    
    if back_16==1
        stringbeg='acc_nb_frames ';
        posbeg1 = findstr(cfg,stringbeg)+size(stringbeg,2);
        stringend='accel_disp';
        posend1 = findstr(cfg,stringend);
        
        new_string1=sprintf('%1.0i\n',1);
        new_cfg=[cfg(1:posbeg1-1) new_string1 cfg(posend1:end)];
        
        fid2=fopen(cfgname,'w');
        fwrite(fid2,new_cfg,'uchar');
        fclose(fid2);
        
        
        
        cfgname=sprintf('%s/%s.cfg',resultdir,namestr);
        fid = fopen(cfgname,'r');
        cfg=fscanf(fid,'%c');
        fclose(fid);
        
        if back_16==1
            stringbeg='ccd_acq_mode ';
            posbeg1 = findstr(cfg,stringbeg)+size(stringbeg,2);
            stringend='ccd_flip_horz';
            posend1 = findstr(cfg,stringend);
            
            new_string1=sprintf('SINGLE \n',1);
            new_cfg=[cfg(1:posbeg1-1) new_string1 cfg(posend1:end)]
            
            fid2=fopen(cfgname,'w');
            fwrite(fid2,new_cfg,'uchar');
            fclose(fid2);
            
            
        end
        
        fprintf('the new cfg file has been updated for the size of the projections and the accumulation level \n');
        
        
        
    end
    
    
    



end
