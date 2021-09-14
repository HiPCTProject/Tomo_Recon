% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% origin Paul Tafforeau ESRF 2020


function covid_half_acquisition_slave_OAR(first,last,parentdir,resultdir,namestr,HA_scan,nvue,refon,acc_nb_frames,max_SR_current,border_Vcorr_width,back_16,force_BF_1,force_BF_mode,BF_corr,HA_opt,BF_max_trans_level,BF_max_trans_size)

if isdeployed
    first=str2num(first)
    last=str2num(last)
    nvue=str2num(nvue)
    refon=str2num(refon)
    acc_nb_frames=str2num(acc_nb_frames)
    max_SR_current=str2num(max_SR_current)
    border_Vcorr_width=str2num(border_Vcorr_width)
    back_16=str2num(back_16)
    force_BF_1=str2num(force_BF_1)
    BF_corr=str2num(BF_corr)
    HA_opt=str2num(HA_opt)
    BF_max_trans_level=str2num(BF_max_trans_level)
    BF_max_trans_size=str2num(BF_max_trans_size)
    
    
    
end

if first==last
    test=first;
    figure(1);
else
    test=0;
end

%% reading of the two max SRcurrent references for HA and TA scans

if exist('HA_REF.edf')
    HA_REF=single(edfread('HA_REF.edf'));
    use_HA_REF=1;
else
    if exist(sprintf('%s/%s/refHST0000.edf',parentdir,HA_scan));
        fprintf('you are using the classical reference system or you used a complex reference scan for of axis local tomography \n')
        HA_REF=single(edfread(sprintf('%s/%s/refHST0000.edf',parentdir,HA_scan)));
        use_HA_REF=0;
        
    else
        
        fprintf('I cannot find either normal references or the generic reference for HA scans that should be called HA_REF.edf, to be prepared with covid_total_mean macro \n')
        return
    end
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

if use_HA_REF==0
    fprintf('reading all the references and forcing them to the max SRcurrent level \n');
    
    for k=0:((round(nvue/10)*10)/refon)
        flatname=sprintf('%s/%s/refHST%4.4i.edf',parentdir,HA_scan,k*refon);
        fp2=fopen(sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,k*refon));
        if fp2~=-1
            hd2=fscanf(fp2,'%c',1024);
            fclose(fp2);
            
            REF_SR_current=findheader(hd2,'SRCUR','float');
            
        end
        f=single(edfread(flatname)-dark)/REF_SR_current*max_SR_current+dark;
        
        flat(:,:,k+1)=f;
        disp (flatname)
    end
    size(flat)
end




dark_level=mean2(dark);

general_ref_level=max2(medfilt_rapid(HA_REF-dark,[50 50],'replicate'));


%% reading of center of rotation from the par file

if HA_opt>0
    parfilename=sprintf('%s/%s/%sslice_pag.par',parentdir,HA_scan,HA_scan);
    
    fid = fopen(parfilename,'r');
    parf=fscanf(fid,'%c');
    
    if parf~=-1
    fclose(fid);
    
    stringbeg='ROTATION_AXIS_POSITION = ';
    posbeg1 = findstr(parf,stringbeg)+size(stringbeg,2);
    stringend=' # Position in pixels';
    posend1 = findstr(parf,stringend);
    
    lateral_shift=str2num(parf(posbeg1:posend1));
    
    %    lateral_shift=lateral_shift-size(HA_REF,1)/2
    
    else
        
        disp (' there is no par file to find the center of rotation, please run fasttomo at least once')
        return
    end
    
end


%% main loop for concatenation

first_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,1);
fp2=fopen(first_im_name);
    
    if fp2~=-1
        hd2=fscanf(fp2,'%c',1024);
        fclose(fp2);
        LAST_OK_SCAN_SRcurrent=findheader(hd2,'SRCUR','float')
        if LAST_OK_SCAN_SRcurrent==-1
            disp('there is a problem with the recorded SRcurrent value in the first picture, tying to find a correct value on another projection')
            SR_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,100);
            fp3=fopen(SR_im_name);
            hd3=fscanf(fp3,'%c',1024');
            fclose(fp3);
            LAST_OK_SCAN_SRcurrent=findheader(hd3,'SRCUR','float')
            if LAST_OK_SCAN_SRcurrent==-1
                disp('there is a problem with the recorded SRcurrent value in the first picture, tying to find a correct value on another projection')
                SR_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,200);
                fp4=fopen(SR_im_name);
                hd4=fscanf(fp4,'%c',1024');
                fclose(fp4);
                LAST_OK_SCAN_SRcurrent=findheader(hd4,'SRCUR','float')
            end
        end
    end
    
    
    
    if HA_opt>0
        
      first_im_name2=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,floor(nvue/2));
    fp2=fopen(first_im_name2);
    
    if fp2~=-1
        hd2=fscanf(fp2,'%c',1024);
        fclose(fp2);
        LAST_OK_SCAN_SRcurrent2=findheader(hd2,'SRCUR','float')
        if LAST_OK_SCAN_SRcurrent==-1
            disp('there is a problem with the recorded SRcurrent value in the first picture, tying to find a correct value on another projection')
            SR_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,floor(nvue/2)+100);
            fp3=fopen(SR_im_name);
            hd3=fscanf(fp3,'%c',1024');
            fclose(fp3);
            LAST_OK_SCAN_SRcurrent2=findheader(hd3,'SRCUR','float')
            if LAST_OK_SCAN_SRcurrent==-1
                disp('there is a problem with the recorded SRcurrent value in the first picture, tying to find a correct value on another projection')
                SR_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,floor(nvue/2)+200);
                fp4=fopen(SR_im_name);
                hd4=fscanf(fp4,'%c',1024');
                fclose(fp4);
                LAST_OK_SCAN_SRcurrent2=findheader(hd4,'SRCUR','float')
            end
        end
    end
      
        
    end
    

for i=first:last
    
    HA_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,i);
    
    fp2=fopen(HA_im_name);
    
    if fp2~=-1
        hd2=fscanf(fp2,'%c',1024);
        fclose(fp2);
        SCAN_SRcurrent=findheader(hd2,'SRCUR','float')
       
        if SCAN_SRcurrent<20
            SCAN_SRcurrent=LAST_OK_SCAN_SRcurrent-LAST_OK_SCAN_SRcurrent*0.0000019   % SRcurrent decrease calibrated on 100 pictures 
        end
        
        LAST_OK_SCAN_SRcurrent= SCAN_SRcurrent;
    end
    
    if use_HA_REF==1
        HA_im=((single(edfread(HA_im_name))-dark)/SCAN_SRcurrent*max_SR_current)./(HA_REF-dark);
    else
        
        refn1=refon*floor(i/refon)
        refn2=min(refn1+refon,round(nvue/10)*10)
        ref_interval=max(refn2-refn1,1);
        w1=(refn2-i)/ref_interval;
        w2=1-w1;
        ind1=refn1/refon+1;
        ind2=min(refn2/refon+1,size(flat,3));
        
        
        HA_REF = w1*flat(:,:,ind1) + w2*flat(:,:,ind2);
        
       
        HA_im=((single(edfread(HA_im_name))-dark)/SCAN_SRcurrent*max_SR_current)./(HA_REF-dark);
        
        
        
    end
    
    
   
    
    if HA_opt>0
        if i<nvue/2+1
            ibis=i+floor(nvue/2);
        else
            ibis=i-floor(nvue/2);
        end
        
        HA2_im_name=sprintf('%s/%s/%s%4.4i.edf',parentdir,HA_scan,HA_scan,ibis);
        
        fp2=fopen(HA2_im_name);
        
        if fp2~=-1
            hd2=fscanf(fp2,'%c',1024);
            fclose(fp2);
            SCAN_SRcurrent2=findheader(hd2,'SRCUR','float');
            
        if SCAN_SRcurrent2<20
            SCAN_SRcurrent2=LAST_OK_SCAN_SRcurrent2-LAST_OK_SCAN_SRcurrent2*0.0000019   % SRcurrent decrease calibrated on 100 pictures 
        end
        
        LAST_OK_SCAN_SRcurrent2= SCAN_SRcurrent2;   
            
            
            
        end
        
        if use_HA_REF==1
            HA2_im=((single(edfread(HA2_im_name))-dark)/SCAN_SRcurrent2*max_SR_current)./(HA_REF-dark);
        else
            
            refn1=refon*floor(ibis/refon);
            refn2=min(refn1+refon,round(nvue/10)*10);
            w1=(refn2-ibis)/refon;
            w2=1-w1;
            ind1=refn1/refon+1;
            ind2=min(refn2/refon+1,size(flat,3));
            
            
            HA_REF = w1*flat(:,:,ind1) + w2*flat(:,:,ind2);
            HA2_im=((single(edfread(HA2_im_name))-dark)/SCAN_SRcurrent2*max_SR_current)./(HA_REF-dark);
            
            
            
        end
        
    end
    
    
    
    
    %%
    if HA_opt>0
        
        
        % cropping in 4 parts
        
        common_size=round((size(HA_im,1)-lateral_shift)*2);
        
        common1=imcrop(HA_im,[1 size(HA_im,1)-common_size+1 size(HA_im,2) common_size-1]);
        common2=flipud(imcrop(HA2_im,[1 size(HA2_im,1)-common_size+1 size(HA2_im,2) common_size-1]));
        
        % checking grey levels in the comon parts to define the best of the two pictures to be used as a reference (or the two of them)
        common1_test=mean2(abs(medfilt_rapid(common1,[200 10],'symmetric')-mean2(common1)));
        common2_test=mean2(abs(medfilt_rapid(common2,[200 10],'symmetric')-mean2(common2)));
        
        common1_cor=median(medfilt_rapid(common1,[200 10],'symmetric'));
        common2_cor=median(medfilt_rapid(common2,[200 10],'symmetric'));
        
        div_test=abs((common1_test-common2_test)/(max(common1_test,common2_test))*100);
        
        if div_test<5
            disp('less than 5% of error, we use both image for a bilateral normalisation')
            common_level=median(medfilt_rapid((common1+common2)/2,[200 10],'symmetric'));
            
        else
            
            if common1_test<common2_test
                disp('using the first picture as reference for the vertical normalisation')
                common_level=median(medfilt_rapid(common1,[200 10],'symmetric'));
                
            else
                disp('using the second picture as reference for the vertical normalisation')
                common_level=median(medfilt_rapid(common2,[200 10],'symmetric'));
                
            end
        end
        
        common1_cor=blurring_rapid(imresize(common_level-common1_cor,[size(HA_im,1) size(HA_im,2)]),10,'replicate');
        common2_cor=blurring_rapid(imresize(common_level-common2_cor,[size(HA_im,1) size(HA_im,2)]),10,'replicate');
        
        
       
        HA_im=HA_im+common1_cor;
        HA2_im=HA2_im+common2_cor;
               
        
        
    end
    
    
    
    
    %% projections corrections
    
    if border_Vcorr_width > 0
        
        left_filter=HA_im-medfilt_rapid(HA_im,[ceil(border_Vcorr_width/1) ceil(size(HA_im,2)*1.5)],'symmetric');
        left_filter=medfilt_rapid(left_filter,[1 ceil(size(HA_im,2)/4)],'replicate');
        left_filter=medfilt_rapid(left_filter,[1 ceil(size(HA_im,2)/4)],'replicate');
        left_filter=left_filter-medfilt_rapid(left_filter,[ceil(border_Vcorr_width/1) ceil(size(HA_im,2)*1.5)],'symmetric');
        
        left_border=HA_im-left_filter;
        
        HA_im(1:ceil(border_Vcorr_width/2)-1,:,:)=left_border(1:ceil(border_Vcorr_width/2)-1,:,:);
        
        
        for l=1:border_Vcorr_width %ceil(border_Vcorr_width/2):ceil(border_Vcorr_width*1.5)
            
            Wcom1=1-(l/border_Vcorr_width);
            Wcom2=1-Wcom1;
            HA_im(l+ceil(border_Vcorr_width/2),:,:)=left_border(l+ceil(border_Vcorr_width/2),:,:)*Wcom1+HA_im(l+ceil(border_Vcorr_width/2),:,:)*Wcom2;
            
        end
        
        
        if HA_opt>0
            
            left_filter=HA2_im-medfilt_rapid(HA2_im,[ceil(border_Vcorr_width/1) ceil(size(HA2_im,2)*1.5)],'symmetric');
            left_filter=medfilt_rapid(left_filter,[1 ceil(size(HA2_im,2)/4)],'replicate');
            left_filter=medfilt_rapid(left_filter,[1 ceil(size(HA2_im,2)/4)],'replicate');
            left_filter=left_filter-medfilt_rapid(left_filter,[ceil(border_Vcorr_width/1) ceil(size(HA2_im,2)*1.5)],'symmetric');
            
            
            left_border=HA2_im-left_filter;
            
            HA2_im(1:ceil(border_Vcorr_width/2)-1,:,:)=left_border(1:ceil(border_Vcorr_width/2)-1,:,:);
            
            
            for l=1:border_Vcorr_width %ceil(border_Vcorr_width/2):ceil(border_Vcorr_width*1.5)
                
                Wcom1=1-(l/border_Vcorr_width);
                Wcom2=1-Wcom1;
                HA2_im(l+ceil(border_Vcorr_width/2),:,:)=left_border(l+ceil(border_Vcorr_width/2),:,:)*Wcom1+HA2_im(l+ceil(border_Vcorr_width/2),:,:)*Wcom2;
                
            end
        end
    end
    
    
    if BF_max_trans_level>0  %first pass to normalize on a large scale
        %HA_im_BF=medfilt_rapid(HA_im,[BF_max_trans_size BF_max_trans_size],'replicate');
        HA_im_BF=blurring_rapid(HA_im,BF_max_trans_size*5,'replicate');
        HA_im_HF=HA_im-HA_im_BF;
        
        HA_im_BF=min(HA_im_BF,BF_max_trans_level);
        
        HA_im=HA_im_HF+HA_im_BF;
        
        
        if HA_opt>0
            %HA2_im_BF=medfilt_rapid(HA2_im,[BF_max_trans_size BF_max_trans_size],'replicate');
            HA2_im_BF=blurring_rapid(HA2_im,BF_max_trans_size*5,'replicate');
            HA2_im_HF=HA2_im-HA2_im_BF;
            
            HA2_im_BF=min(HA2_im_BF,BF_max_trans_level);
            
            HA2_im=HA2_im_HF+HA2_im_BF;
            
        end
        
        
    end
    

    
    %%
    if force_BF_1>0
        
        if HA_opt>0
            concat_im=[imcrop(HA_im,[1 1 size(HA_im,2) size(HA_im,1)-common_size-1])' (flipud(HA2_im))']';
            
            if border_Vcorr_width>0
                imt_norm_REF=imcrop( concat_im,[ 1 border_Vcorr_width size(concat_im,2)  size(concat_im,1)-border_Vcorr_width+1]);
                imt_norm_REF=medfilt_rapid(imt_norm_REF,[force_BF_1 force_BF_1],'replicate');
            else
                imt_norm_REF=medfilt_rapid(concat_im,[force_BF_1 force_BF_1],'replicate');
            end
            
        else
            
            
            if border_Vcorr_width>0
                imt_norm_REF=imcrop( HA_im,[ 1 border_Vcorr_width size(HA_im,2)  size(HA_im,1)-border_Vcorr_width+1]);
                imt_norm_REF=medfilt_rapid(imt_norm_REF,[force_BF_1 force_BF_1],'replicate');
            else
                imt_norm_REF=medfilt_rapid(HA_im,[force_BF_1 force_BF_1],'replicate');
            end
            
        end
        
        
        switch force_BF_mode
            case 'min'
                imt_norm=imresize(min(imt_norm_REF),[size(HA_im,1) size(HA_im,2)])-1;
            case 'max'
                imt_norm=imresize(max(imt_norm_REF),[size(HA_im,1) size(HA_im,2)])-1;
            case 'avg'
                imt_norm=imresize(mean(imt_norm_REF),[size(HA_im,1) size(HA_im,2)])-1;
        end
        
        imt_norm=medfilt_rapid(imt_norm,[1 100],'replicate');
        
        HA_im=HA_im-imt_norm;
        
        if HA_opt>0
            
            HA2_im=HA2_im-imt_norm;
            
        end
        
        %%
        if BF_max_trans_level>0  %second pass to normalize with the final size of the filter
            %HA_im_BF=medfilt_rapid(HA_im,[BF_max_trans_size BF_max_trans_size],'replicate');
            HA_im_BF=blurring_rapid(HA_im,BF_max_trans_size,'replicate');
            HA_im_HF=HA_im-HA_im_BF;
            
            HA_im_BF=min(HA_im_BF,BF_max_trans_level);
            
            HA_im=HA_im_HF+HA_im_BF;
            
            
            if HA_opt>0
                %HA2_im_BF=medfilt_rapid(HA2_im,[BF_max_trans_size BF_max_trans_size],'replicate');
                HA2_im_BF=blurring_rapid(HA2_im,BF_max_trans_size,'replicate');
                HA2_im_HF=HA2_im-HA2_im_BF;
                
                HA2_im_BF=min(HA2_im_BF,BF_max_trans_level);
                
                HA2_im=HA2_im_HF+HA2_im_BF;
                
            end
            
            
        end
        
        
        
        
        
        
    end
    
    %%
        
    if BF_corr >0  %
        
      
        left_part1=blurring_rapid(imcrop(HA_im,[1 1 size(HA_im,1) BF_corr-1]),BF_corr,'replicate');
        left_level1=mean2(left_part1);

        
        if HA_opt>0
            left_part2=blurring_rapid(imcrop(flipud(HA2_im),[1 1 size(HA2_im,1) BF_corr-1]),BF_corr,'replicate');
            left_level2=mean2(left_part2);
        
        end
        
        norm_mask1=HA_im*0+1;
    
        for n=1:size(HA_im,1)-BF_corr
            w2=n/(size(HA_im,1)-BF_corr);
            w1=1-w2;
            level=left_level1*w1+w2;
            norm_mask1(n,:,:)=level;
        end
        
        norm_mask1=imresize(norm_mask1,[size(HA_im,1) size(HA_im,2)]);
   
        if HA_opt>0
            norm_mask2=HA_im*0+1;
 
            for n=1:size(HA2_im,1)-BF_corr
                w2=n/(size(HA2_im,1)-BF_corr);
                w1=1-w2;
                level2=left_level2*w1+w2;
                norm_mask2(n,:,:)=level2;
            end
            norm_mask2=imresize(norm_mask2,[size(HA2_im,1) size(HA2_im,2)]);

        end
  
          HA_im=HA_im./norm_mask1;
          HA2_im=HA2_im./norm_mask2;

    end
    
    
    
    if HA_opt>0 && test>0 
        
        concat_im=[imcrop(HA_im,[1 1 size(HA_im,2) size(HA_im,1)-common_size-1])' (flipud(HA2_im))'];
        figure;imshow(concat_im,[]);
        
        return
        
        
    end
    
    %% removing the reference to go back to original scale
    
    if back_16==1
        HA_im=HA_im.*general_ref_level/acc_nb_frames+dark_level/acc_nb_frames;
    else
        HA_im=HA_im.*general_ref_level+dark_level;
    end
    
    
    
    if test>0 
        
        imshow(HA_im',[]);impixelinfo
        fprintf('processing of the projection %4.4i is finished \n',i);
        
    else
        
        %% writing the result
        
        
        
        new_imname=sprintf('%s/%s%4.4i.edf',resultdir,namestr,i);
        fprintf('writing the new projection file %s%4.4i.edf on a total of %4.4i \n',namestr,i,nvue);
        
        if back_16==1
            edfwrite(new_imname,uint16(HA_im),'uint16');
        else
            edfwrite(new_imname,HA_im,'float32');
        end
    end
    
    
    
end

if last==nvue
    
    disp ('attempting to write the new references and new dark')
    
    if back_16==1
        mean2(HA_im)
        final_ref_level=general_ref_level/acc_nb_frames+dark_level/acc_nb_frames
        new_ref=uint16(zeros(size(HA_im,1),size(HA_im,2))*0+final_ref_level);
        mean2(new_ref)
        new_dark=uint16(HA_im*0+dark_level/acc_nb_frames);
        edfwrite(sprintf('%s/refHST0000.edf',resultdir),new_ref,'uint16');
        edfwrite(sprintf('%s/refHST%4.4i.edf',resultdir,nvue),new_ref,'uint16');
        edfwrite(sprintf('%s/dark.edf',resultdir),new_dark,'uint16');
    else
        new_ref=HA_im*0+general_ref_level+dark_level;
        new_dark=HA_im*0+dark_level;
        edfwrite(sprintf('%s/refHST0000.edf',resultdir),new_ref,'float32');
        edfwrite(sprintf('%s/refHST%4.4i.edf',resultdir,nvue),new_ref,'float32');
        edfwrite(sprintf('%s/dark.edf',resultdir),new_dark,'float32');
        
    end
    
    disp ('writting successful')
    
    disp ('copying and renaming of the .info .xml and .cfg files to keep the motor positions and other informations of the scans. Be aware that the picture sizes are not updated')
    
    system(sprintf('cp %s/%s/%s.info %s/%s.info',parentdir,HA_scan,HA_scan,resultdir,namestr))
    system(sprintf('cp %s/%s/%s.xml %s/%s.xml',parentdir,HA_scan,HA_scan,resultdir,namestr))
    system(sprintf('cp %s/%s/%s.cfg %s/%s.cfg',parentdir,HA_scan,HA_scan,resultdir,namestr))
    
    %% updating info file with the correct refon in case of use of multiple references
    
    infoname=sprintf('%s/%s.info',resultdir,namestr);
    fid = fopen(infoname,'r');
    info=fscanf(fid,'%c');
    fclose(fid);
    
    stringbeg='REF_ON=                ';
    posbeg1 = findstr(info,stringbeg)+size(stringbeg,2);
    stringend='REF_N=                ';
    posend1 = findstr(info,stringend);
    
    new_string1=sprintf('%1.0i\n',nvue);
    new_info=[info(1:posbeg1-1) new_string1 info(posend1:end)];
    
    fid2=fopen(infoname,'w');
    fwrite(fid2,new_info,'uchar');
    fclose(fid2);
    
    fprintf('the new info file has been updated for the refon \n');
    
    
    
    %% updating info .cfg file with the accumulation level if going back to 16 bits
    
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
            new_cfg=[cfg(1:posbeg1-1) new_string1 cfg(posend1:end)];
            
            fid2=fopen(cfgname,'w');
            fwrite(fid2,new_cfg,'uchar');
            fclose(fid2);
            
            
        end
        
        fprintf('the new cfg file has been updated for the projections and the accumulation level \n');
        
        
        
    end
    
    
    
    
    
    
end
