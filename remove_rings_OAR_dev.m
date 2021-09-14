% Remove ring artefacts from image.
%
% Input:
%   im                      - image to be corrected for rings, must be 2 dimensional with center
%                             of rotation at the center of the image
%   median_size             - maximum size of the rings that can be reomved by the
%                             filter
%   number_of_pass          - indicate the number of pas of the filter to increase
%                             the correction quality (typically two pass)
%   structure_removal_level - threshold value to select the resildual
%                             structures to be removed before the linear filtering
%   blur_angle              - minimum anbular extension of the rings to
%                             correct (typically 40 degrees)
%   fusion_angle            - angular legnth for the fusion of the two
%                             parts of the pictures in the 180 degrees version
%   visualization           - 1 to see the result, 0 to process and record
%                             the picture
%
%
% Output:
%   im_corr     - corrected picture
%   ring_im     - image containing rings of the image
%
% credits and comments at the end of the program
%
% 05/05/2012 acceleration of the double polar correction by resizing
% 13/03/2014 new version for median filter, faster and more robust, reduce many
% troubles
% 09/10/2016 better handling of resizing to accelerate in case of very
% short filter
% change in multipass logic to limit the amount of back and forth polar
% transform


function [imcorr,ring_im] = remove_rings_OAR(im,median_size,number_of_pass,structure_removal_level,blur_angle,fusion_angle,visualization,rotate_slices,amin,amax,amedian,strong_rings,double_polar_corr,high_contrast_cut,varargin);


switch nargin

    case 14
        range_auto=1;
        vmin=0;
        vmax=65535;
        cropim=0;
    case 16
        range_auto=0;
        vmin=varargin{1};
        vmax=varargin{2};
        cropim=0;
    case 17
        range_auto=0;
        vmin=varargin{1};
        vmax=varargin{2};  
        cropim=1;
        
end

save_memory=1;

vdis=0;
hdis=0;

debug= 0  ; % set to 1 to see all the steps of the processing 

vertical_LF_correction = 1 ;

center_correction=2 ; % 1 for fading of the ring mask at the center, 2 for adaptive filter length near the center (better)

%disp( ' NEW VERSION, SHOULD BE MORE EFFICIENT THAN BEFORE. PLEASE REPORT ANY PROBLEM ')
% need implementation of HF correction for residual and induced rings

% disp (' WARNING, ONGOING TEST FOR MAJOR DEVELOPMENT, THE RESULTS OF TESTS CAN BE DIFFERENT FROM THE ONES OBTAINED FOR FULL CALCULATION')
% disp (' please do not use the system for the moment, it will restart very soon with optimized system')
 
 %return

%%

tic

%% conversion into 32bits in case of 8 bits data



imorig=im;

imclass=class(im);

switch imclass
    case 'uint8' % way to know if it is 8 bits when you dont know how to do with matlab
        disp('original data are in unsigned 8 bits')
        im_conv=1;
        im=single(im);
    case 'uint16'
        disp('original data are in unsigned 16 bits')
        im_conv=1;
        im=single(im);
    case 'double'   % added single precision 32 bit case, WL
        disp('original data are in 64 bits')
        im_conv=1;
        im=single(im);
    case 'single'
        disp('original data are already in 32 bits')
        im_conv=0;
end

switch imclass
    case {'double','single'}
        if   vmax==65535;
            vmin=amin;
            vmax=amax;
        end
end
             

if abs(vdis) || abs(hdis) > 0
    im=interpolates(im,vdis,hdis);
end

if rotate_slices
    im=imrotate(im,rotate_slices);
end

%% inits

% square image if it is not, and store the size for later cropping
[size_orig_rows,size_orig_columns]=size(im);
%imorig=im;
if size_orig_rows>size_orig_columns  % more rows that columns
 %   topleftx=(size_orig_rows-size_orig_columns)/2;toplefty=1;
 %   im=gtPlaceSubImage(im,zeros(size_orig_rows),topleftx,toplefty);

 disp ('WARNING, this correction can be applied only on square pictures with center of rotation at the middle of the picture')
 return
elseif size_orig_rows<size_orig_columns
 %   topleftx=1;toplefty=(size_orig_columns-size_orig_rows)/2;
 %   im=gtPlaceSubImage(im,zeros(size_orig_columns),topleftx,toplefty);
 disp ('WARNING, this correction can be applied only on square pictures with center of rotation at the middle of the picture')
 return

else
    topleftx=1;toplefty=1;
end


%% angular resolution and filter length determination


%theta = ceil(40000/blur_angle)
theta = ceil(min(ceil(40000/blur_angle),720)/2)*2;

blur_len = round(blur_angle/360*theta);
fusion_len = round(fusion_angle/360*theta);
median_len = round(median_size/size(im,2)*theta);

h_blur = fspecial('average',[1 blur_len]);
h_fusion = fspecial('average',[1 fusion_len]);

%%

%% slice presegmentation in case of high contrast cut
    
    if high_contrast_cut>0
        
         if debug==1
        tic
         end
        
        im=im-amedian;
        
        disp ('WARNING, you activated the high contrast cut system, are you sure that you need it ?')
       
        se=strel('disk',ceil(median_size/10));
        neutral=abs(im);
        
        contrast_mask=max(neutral,high_contrast_cut)-high_contrast_cut;
        contrast_mask=single(im2bw(contrast_mask,0.0001));
        contrast_mask=imdilate(contrast_mask,se);
        
        high_contrast_parts=medfilt_rapid(im.*contrast_mask,[10 10]);
        im2=im-high_contrast_parts;
        
        %local_corr_mask=imresize_GPU(imdilate(medfilt_rapid(imresize_GPU(im2,0.2,'bilinear'),[5 5]),se),[size(im2,1) size(im2,2)],'bilinear').*contrast_mask;
        local_corr_mask=imresize(imdilate(medfilt_rapid(imresize(im2,0.2,'bilinear'),[5 5]),se),[size(im2,1) size(im2,2)],'bilinear').*contrast_mask;
        
        im=im2+local_corr_mask;
              
        if debug==1
        disp('result of the high contrast cut');
        toc
        imshow(im,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
        end
    
        
        if save_memory
            clear light_parts
            clear dense_parts
        end
        
    end
    

%%  STARTING OF THE RING CORRECTION

%for k=1:number_of_pass

    %%

    if debug==1
        close all
        figure
        disp('initial preparation of the picture')
        toc
    end


    im=im';



    
%% correction of absorption by a simple median filter

    if debug==1
        tic
    end


    im2=im-medfilt_rapid(im,[median_size median_size],'replicate');
    im2=im2-medfilt_rapid(im2,[median_size median_size],'replicate');


    if debug==1
        disp('result of the median fitering to remove absorption');
        toc
        imshow([im, im2],[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end



%% convert from Cartesian to polar coordinates

    if debug==1
        tic
    end


    polar = polartrans(im2, size(im2,1), theta);
    polar(find(isnan(polar)))=0;


    if debug==1
        disp('polar_transformation');
        toc
        imshow(polar',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end

    if save_memory==1
        clear im2
    end

%% removal of low frequencies in polar coordinates

polar=polar-medfilt_rapid(polar,[median_size ceil(median_len/2)],'replicate');
polar=polar-medfilt_rapid(polar,[median_size ceil(median_len/2)],'replicate');



%% double polar correction

    if double_polar_corr==1

        if debug==1
            tic
        end

          
            %im3=imresize_GPU(polar,0.2,'bilinear');
            im3=imresize(polar,0.2,'bilinear');

            im3=circshift(im3,[size(im3,1)-round(size(im3,1)/sqrt(2))-2 0]);

            im3=flipud(im3);
            im3=invpolar2(im3,size(im3,1));
            im3=medfilt_rapid(im3,[ceil(median_size/7) ceil(median_size/7)],'replicate'); % median size is original median size / sqrt of 2 / resizing factor (5 for the moment)
            im3=medfilt_rapid(im3,[ceil(median_size/7) ceil(median_size/7)],'replicate');
            im3=polartrans(im3,size(im3,1),theta);
            im3(find(isnan(im3)))=0;
            im3=flipud(im3);

            im3=circshift(im3,[-(size(im3,1)-round(size(im3,1)/sqrt(2))-2) 0]);

            %im3=imresize_GPU(im3,[size(polar,1) size(polar,2)],'bicubic');
            im3=imresize(im3,[size(polar,1) size(polar,2)],'bicubic');
            
            im3=medfilt_rapid(im3,[5 5],'replicate');

            polar=polar-im3;


        if debug==1||debug==2
            disp('double_polar_correction');
            toc
            imshow(polar',[]);drawnow
            
            next_step=inputwdefault('do you want to continue ?   ','y');
            if next_step=='n' | next_step=='no'
                return
            end
        end

            
    end

%% new position for the multipass system

init_polar=polar;

pre_processing_time=toc
pre_pass_time=0;


for k=1:number_of_pass
    
    
%% correction of low frequencies in polar coordinates

if vertical_LF_correction==1

    
    polar_VLF=medfilt_rapid(polar,[median_size 1],'replicate');
    polar_VLF=medfilt_rapid(polar_VLF,[median_size 1],'replicate');
    polar_VLF=medfilt_rapid(polar_VLF,[median_size 1],'replicate');
    polar=polar-polar_VLF;
    polar_VLF=medfilt_rapid(polar,[median_size 1],'replicate');
    polar_VLF=medfilt_rapid(polar_VLF,[median_size 1],'replicate');
    polar_VLF=medfilt_rapid(polar_VLF,[median_size 1],'replicate');
    polar=polar-polar_VLF;



    if debug==1||debug==2
        disp('correction of low frequencies in polar coordinates');
        toc
        imshow(polar',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end
    
end


%% split into upper/lower part: 0-180 deg. / 180-360 deg.

    if debug==1
        tic
    end

    upper_pol = polar(:,1:end/2);
    lower_pol = polar(:,end/2+1:end);


    upper_pol_pad = padarray(upper_pol,[0 blur_len*4],'symmetric','both');
    lower_pol_pad = padarray(lower_pol,[0 blur_len*4],'symmetric','both');


%% vertical concatenation to avoid bad effect at the center of the picture

    tot_pol_pad=[(flipud(upper_pol_pad))' lower_pol_pad']';


    neutral_mask=medfilt_rapid(tot_pol_pad,[median_size ceil(median_size/(size(im,1)/theta))],'replicate');
    tot_pol_pad=tot_pol_pad-neutral_mask;

    
    
  %% correction of low frequencies in polar coordinates

if vertical_LF_correction==1

    
    tot_pol_pad_VLF=medfilt_rapid(tot_pol_pad,[median_size 1],'replicate');
    tot_pol_pad_VLF=medfilt_rapid(tot_pol_pad_VLF,[median_size 1],'replicate');
    tot_pol_pad=tot_pol_pad-tot_pol_pad_VLF;
    tot_pol_pad_VLF=medfilt_rapid(tot_pol_pad,[median_size 1],'replicate');
    tot_pol_pad_VLF=medfilt_rapid(tot_pol_pad_VLF,[median_size 1],'replicate');
    tot_pol_pad=tot_pol_pad-tot_pol_pad_VLF;



    if debug==1||debug==2
        disp('correction of low frequencies in polar coordinates');
        toc
        imshow(tot_pol_pad',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end
    
end  
    

    if center_correction==1   ||  center_correction==2

        h=fspecial('average',[ceil(median_size/2)  1]);

        neutral_center=imcrop(tot_pol_pad,[0 round(size(tot_pol_pad,1)/2-median_size*2) size(tot_pol_pad,2) median_size*4-1]);
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/2) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/2) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_pond_center=neutral_center.*0+1;
        padsize=round((size(tot_pol_pad,1)-size(neutral_center,1))/2);
        neutral_center=padarray(neutral_center,[padsize 0],'both');
        neutral_pond_center=padarray(neutral_pond_center,[padsize 0],'both');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,0.1,'nearest');
        neutral_pond_center=imresize(neutral_pond_center,0.1,'nearest');
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');
        neutral_pond_center=imresize(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');
        
        neutral_center=neutral_center.*neutral_pond_center;
        tot_pol_pad=tot_pol_pad-neutral_center;

        h=fspecial('average',[ceil(median_size*1)  1]);

        neutral_center=imcrop(tot_pol_pad,[0 round(size(tot_pol_pad,1)/2-median_size) size(tot_pol_pad,2) median_size*2-1]);
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/4) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/4) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_pond_center=neutral_center.*0+1;
        padsize=round((size(tot_pol_pad,1)-size(neutral_center,1))/2);
        neutral_center=padarray(neutral_center,[padsize 0],'both');
        neutral_pond_center=padarray(neutral_pond_center,[padsize 0],'both');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,0.1,'nearest');
        neutral_pond_center=imresize(neutral_pond_center,0.1,'nearest');
        
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');
        neutral_pond_center=imresize(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');

        neutral_center=neutral_center.*neutral_pond_center;
        tot_pol_pad=tot_pol_pad-neutral_center;

        h=fspecial('average',[ceil(median_size/2)  1]);

        neutral_center=imcrop(tot_pol_pad,[0 round(size(tot_pol_pad,1)/2-median_size*2) size(tot_pol_pad,2) median_size*4-1]);
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/2) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/2) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_pond_center=neutral_center.*0+1;
        padsize=round((size(tot_pol_pad,1)-size(neutral_center,1))/2);
        neutral_center=padarray(neutral_center,[padsize 0],'both');
        neutral_pond_center=padarray(neutral_pond_center,[padsize 0],'both');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,0.1,'nearest');
        neutral_pond_center=imresize(neutral_pond_center,0.1,'nearest');
        
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');
        neutral_pond_center=imresize(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');

        neutral_center=neutral_center.*neutral_pond_center;
        tot_pol_pad=tot_pol_pad-neutral_center;

        h=fspecial('average',[ceil(median_size*1)  1]);

        neutral_center=imcrop(tot_pol_pad,[0 round(size(tot_pol_pad,1)/2-median_size) size(tot_pol_pad,2) median_size*2-1]);
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/4) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_center=medfilt_rapid(neutral_center,[ceil(median_size/4) ceil(median_size/(size(im,1)/theta))],'replicate');
        neutral_pond_center=neutral_center.*0+1;
        padsize=round((size(tot_pol_pad,1)-size(neutral_center,1))/2);
        neutral_center=padarray(neutral_center,[padsize 0],'both');
        neutral_pond_center=padarray(neutral_pond_center,[padsize 0],'both');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,0.1,'nearest');
        neutral_pond_center=imresize(neutral_pond_center,0.1,'nearest'); 
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        neutral_pond_center=imfilter(neutral_pond_center,h,'replicate');
        %neutral_pond_center=imresize_GPU(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');
        neutral_pond_center=imresize(neutral_pond_center,[size(neutral_center,1) size(neutral_center,2)],'bilinear');

        neutral_center=neutral_center.*neutral_pond_center;
        tot_pol_pad=tot_pol_pad-neutral_center;
    end

    pyra_tot=tot_pol_pad;


    if debug==1

        disp('removal of vertical low frequencies');
        toc
        imshow(pyra_tot',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end




    if save_memory==1
        clear upper_pol_pad
        clear lower_pol_pad
        clear polar
        clear tot_pol_pad

    end


%%   strong rings and floating selection

    if debug==1
        tic
    end

    if strong_rings>0
        im_hor_med=pyra_tot-medfilt_rapid(pyra_tot,[strong_rings 1]);
        %im_hor_med=imresize_GPU(median(im_hor_med,2),[size(pyra_tot,1) size(pyra_tot,2)]);
        im_hor_med=imresize(median(im_hor_med,2),[size(pyra_tot,1) size(pyra_tot,2)]);
        pyra_tot=pyra_tot-im_hor_med;
    end




    pyra_tot=medfilt_rapid(pyra_tot,[3 3],'symmetric');
    struct_tot=abs(pyra_tot);


    imin=0;
    imax=(amax-amin)/2;

    %   figure;imshow(pyra_tot',[]);

    se=strel('disk',1);
  
  if structure_removal_level>0

    for shift_value=[-round(blur_len*1.5) blur_len round(blur_len/2) round(-blur_len/4)  -round(blur_len/2) round(blur_len/4) -round(blur_len/2.5) round(blur_len/4.5)  round(blur_len*1.5) -blur_len round(blur_len/2.5) -round(blur_len/4.5)]   %round(median_size/8)

        selection_tot=((struct_tot-imin)/(imax-imin));
        selection_tot=selection_tot-(structure_removal_level);
        selection_tot=min(max(selection_tot,0)*1e20,1);
        selection_tot=imdilate(selection_tot,se);
        shifted_mask_tot=circshift(selection_tot,[0 shift_value]);
        rustine_tot=shifted_mask_tot.*pyra_tot;
        rustine_tot=circshift(rustine_tot,[0 -shift_value]);
        pyra_tot=pyra_tot.*(1-selection_tot)+rustine_tot;
        struct_tot=abs(pyra_tot);

        %   figure;imshow(pyra_tot',[])


        selection_tot=((struct_tot-imin)/(imax-imin));
        selection_tot=selection_tot-(structure_removal_level);
        selection_tot=min(max(selection_tot,0)*1e20,1);
        selection_tot=imdilate(selection_tot,se);
        shifted_mask_tot=circshift(selection_tot,[0 -shift_value]);
        rustine_tot=shifted_mask_tot.*pyra_tot;
        rustine_tot=circshift(rustine_tot,[0 shift_value]);
        pyra_tot=pyra_tot.*(1-selection_tot)+rustine_tot;
        struct_tot=abs(pyra_tot);

        %  figure;imshow(pyra_tot',[])

    end

  else
      disp(' be careful, you disabled the floating selection security')
  end

    if strong_rings>0
        pyra_tot=pyra_tot+im_hor_med;
    end


    if debug==1
        disp('structure residual removed');
        toc
        imshow(pyra_tot',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end


    if save_memory==1
        clear struct_tot
        clear selection_tot
        clear shifted_mask_tot
        clear rustine_tot
    end



%% final median and motion blurring
    if debug==1
        tic
    end


    pyra_tot=medfilt_rapid(pyra_tot,[1 blur_len]);
    pyra_tot=medfilt_rapid(pyra_tot,[1 blur_len]);

    pyra_tot=imfilter_GPU(pyra_tot,h_blur);
    pyra_tot=imfilter_GPU(pyra_tot,h_blur);

    if debug==1
        disp('median and motion filtering');
        toc
        imshow(pyra_tot',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end



%% vertical low frequencies correction

   
if vertical_LF_correction==1

if debug==1
        tic
end

    pyra_tot_VLF=medfilt_rapid(pyra_tot,[median_size 1],'replicate');
    pyra_tot_VLF=medfilt_rapid(pyra_tot_VLF,[median_size 1],'replicate');
    pyra_tot_VLF=medfilt_rapid(pyra_tot_VLF,[median_size 1],'replicate');
    pyra_tot=pyra_tot-pyra_tot_VLF;
    pyra_tot_VLF=medfilt_rapid(pyra_tot,[median_size 1],'replicate');
    pyra_tot_VLF=medfilt_rapid(pyra_tot_VLF,[median_size 1],'replicate');
    pyra_tot_VLF=medfilt_rapid(pyra_tot_VLF,[median_size 1],'replicate');
    pyra_tot=pyra_tot-pyra_tot_VLF;
    
  
    
    if debug==1
        disp('induced vertical low frequencies correction');
        toc
        imshow(pyra_tot,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end

end

%% separation of the two parts of the picture

    inv_pyra_up = flipud(pyra_tot(1:end/2,:));
    inv_pyra_lo = pyra_tot(end/2+1:end,:);


%% return to original size

    inv_pyra_up=imcrop(inv_pyra_up,[blur_len*4 0 size(upper_pol,2)-1 size(upper_pol,1)]);
    inv_pyra_lo=imcrop(inv_pyra_lo,[blur_len*4 0 size(lower_pol,2)-1 size(lower_pol,1)]);


%% assemble upper/lower part again
    if debug==1
        tic
    end

    inv_pyra = [inv_pyra_up, inv_pyra_lo];

    if save_memory==1
        clear upper_pol
        clear lower_pol
        clear inv_pyra_up
        clear inv_pyra_lo
    end


    if debug==1
        disp('merging of the two images parts');
        toc
        imshow(inv_pyra,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end


%% circular padding of the picture
    if debug==1
        tic
    end

    inv_pyra_pad=padarray(inv_pyra,[0 blur_len*5],'circular','both');

    if debug==1
        disp('circular padding of the merged parts');
        toc
        imshow(inv_pyra_pad,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end


%% central correction with variable lenght median filter near the filter



    if center_correction==2

        center_factor=40/blur_angle;
        center_corr_proportion=center_factor/40;

        if center_factor>1
            %disp ('you used an angular value smaller than 60 degrees, I apply a specific correction to the center of the picture')

            if debug==1
                tic
            end

            number_of_blocks       = 50  ; % total number of blocks

            block_size = ceil(size(inv_pyra_pad,1)*center_corr_proportion/number_of_blocks);
            max_blur_len  = blur_len*center_factor; % maximum angular blur lengh for the center compared to the general value

            top_part=zeros(block_size*number_of_blocks,size(inv_pyra_pad,2));


            for i=0:number_of_blocks-1
                first_line=i*block_size+1;
                last_line=i*block_size+block_size;
                %    disp(sprintf('processing the lines %1.0i to %1.0i', first_line,last_line));
                block=imcrop(inv_pyra_pad,[1  first_line    size(inv_pyra_pad,2)    block_size-1  ]  );
                filter_size=ceil(max_blur_len*(1-i/number_of_blocks));
                block=medfilt_rapid(block,[ 1 filter_size]);
                top_part(first_line:last_line,1:size(top_part,2))=block;  %=[top_part' block']';


            end

            inv_pyra_pad(1:size(top_part,1),1:size(top_part,2))=top_part;

            if debug==1
                disp('adaptive filter length for correction of the center of the image');
                imshow(inv_pyra_pad,[]);drawnow
                next_step=inputwdefault('do you want to continue ?   ','y');
                if next_step=='n' | next_step=='no'
                    return
                end
                toc

            end

            if save_memory==1
                clear top_part
                clear block
            end

        end

    end


%% fusion of the two images parts
    if debug==1
        tic
    end

    inv_pyra_pad=imfilter_GPU(inv_pyra_pad,h_fusion,'circular');
    inv_pyra_pad=imfilter_GPU(inv_pyra_pad,h_fusion,'circular');

    if debug==1
        disp('fusion of the two parts by motion blur');
        toc
        imshow(inv_pyra_pad,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end


%% filtering of induced low frequencies

    if debug==1
        tic
    end

    inv_pyra_pad=inv_pyra_pad-medfilt_rapid(inv_pyra_pad,[median_size blur_len]);
    inv_pyra_pad=inv_pyra_pad-medfilt_rapid(inv_pyra_pad,[median_size blur_len]);

    if debug==1
        disp('removal of induced low frequencies');
        toc
        imshow(inv_pyra_pad,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end



    
%% going back to original size
    if debug==1
        tic
    end

    inv_pyra=imcrop(inv_pyra_pad,[blur_len*5-1 0 size(inv_pyra,2)-1 size(inv_pyra,1)]);

    if save_memory==1
        clear inv_pyra_pad
    end


    if debug==1
        disp('going back to original size');
        toc
        imshow(inv_pyra,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end
    
    pass_time=toc-pre_processing_time-pre_pass_time;
    disp(sprintf('pass %1.0f on %1.0f took %1.2f seconds',k,number_of_pass,pass_time));
    pre_pass_time=toc-pre_processing_time;
    
%% new position for multipass process

if k==1;
    ring_mask_polar=inv_pyra;
else
    ring_mask_polar=ring_mask_polar+inv_pyra;   
end

if k<number_of_pass
    polar=init_polar-ring_mask_polar;
end

end
    
   
    


%% polar into cartesian coordinates (this will give us the ring artifacts)

    if debug==1
        tic
    end


    ring_im = invpolar2(ring_mask_polar,size(im,1));


    %%

    if debug==1
        disp('resulting ring mask');
        toc
        imshow(ring_im,[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end

%% application of the ring mask

    if debug==1
        tic
    end

    imcorr=im-ring_im;

    im=imcorr';

    if debug==1
        disp('corrected_picture');
        toc
        imshow(im',[]);drawnow
        next_step=inputwdefault('do you want to continue ?   ','y');
        if next_step=='n' | next_step=='no'
            return
        end
    end



% end





%% taking into account transposition

ring_im=ring_im';
imcorr=im;

if high_contrast_cut>0
    imcorr=imcorr+high_contrast_parts+amedian-local_corr_mask;
end


%% go back into 8 or 16 bits if necessary

if im_conv>0

    switch imclass
        case 'uint8'
            disp('going back to the original 8 bits range')
            imcorr=uint8(round(imcorr));

        case 'uint16'
            disp('going back to the original 16 bits range')
            imcorr=uint16(round(imcorr));

        case 'double'
            disp('going back to the original double range')
            %imcorr=double(round(imcorr));
            imcorr=double(imcorr);
            
        case 'single'
            disp('going back to the original single range')
            %imcorr=double(round(imcorr));
            imcorr=single(imcorr);
    end

end


%% cropping and rotation of the picture

ring_im=ring_im(toplefty:toplefty+size_orig_rows-1,topleftx:topleftx+size_orig_columns-1);
imcorr=imcorr(toplefty:toplefty+size_orig_rows-1,topleftx:topleftx+size_orig_columns-1);

if rotate_slices
    imcorr=imrotate(imcorr,-rotate_slices);
end

%% visualization of the result

post_processing_time=toc-pre_pass_time-pre_processing_time


if visualization>0 && cropim==0

    LH=stretchlim(imcorr,0.001);
    
    switch imclass
        case 'uint16'
            LH=LH*65635;
        case 'uint8'
            LF=LH*255;
    end
    
    figure(1)
    clf
    ax(1)=subplot(1,3,1);
    imshow(single(imorig),LH);%[vmin vmax])
    axis off
    ax(2)=subplot(1,3,2);
    imshow(single(imcorr),LH);%[vmin vmax]);
    axis off
    ax(3)=subplot(1,3,3);
    imshow(single(imorig)-single(imcorr),[]);
    axis off
    linkaxes(ax,'xy')
    impixelinfo

    drawnow
elseif visualization>0 && cropim==1
    aa=1500;
    bb=2500;
    cc=2000;
    dd=3000;
    figure(1)
    clf
    ax(1)=subplot(1,3,1);
    imshow(single(imorig(aa:bb,cc:dd)),[vmin vmax])
    axis off
    ax(2)=subplot(1,3,2);
    imshow(single(imcorr(aa:bb,cc:dd)),[vmin vmax]);
    axis off
    ax(3)=subplot(1,3,3);
    imshow(single(imorig(aa:bb,cc:dd))-single(imcorr(aa:bb,cc:dd)),[]);
    axis off
    linkaxes(ax,'xy')
    impixelinfo

    drawnow    
    
    
    
end




%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM)
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
% based on the original photoshop script developped by Paul Tafforeau
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr
%
% Modified 5/1/2007 Greg Johnson
% returns the corrected image, not just the rings
% handles non-square images
%
%
% Modified 1/2/2007 Paul Tafforeau
% correction of absorption using a median mask to take into account complex
% samples. The maximum size of the rings have to be given as single
% argument
%
% 1/2008 Paul Tafforeau
% compiled version for parallelization using rings_master to set all the
% parameters
% resize factor to accelerate the median fixed to 2 to avoid misalignment
% of the mask. It has nearly no effect on the calculation speed and bring
% better results.
% implementation fo specific paddings to remove fusion and border effects
% optimized residual structures removal and low frequencies correction for
% the 180 degrees version
% 04/2008 Paul Tafforeau implementation of floating selection to correct
% residual structures after polar transformation
% debug option allowing to visualize all the steps of the processing for
% the 180 degrees version
% 10/2008 Paul Tafforeau option for memory saving by clearing the not longer useful data
% along processing
% 02/2010 PT implementation of GPU median filtering
% 05/2010 PT implementation of GPU imfilter
% 05/2010 PT implementation of GPU imresize
% 06/2010 PT new floating selection system equivalent to photoshop one
%            optimized calculation time
% 11/2011 Alessandro Mirone / PT, full adaptation for OAR and GPU calculation
% 12/2011 PT implementation of adaptive filter length near the center in case of short angular length (center_correction=2)

