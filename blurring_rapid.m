% function to make fast blurring combining image rescaling with infilter
% disk
% using the same input parameters than medfilt2, but allowing replicate
% padding

% origin Paul Tafforeau ESRF

function im2=blurring_rapid(im,varargin)



repetition=2;

switch (nargin)
    case 1
        HS=3;
        padding_rapid='symmetric';
        
   
    case 2
        filter_size=varargin{1};
        HS=filter_size;
        padding_rapid='symmetric';

    case 3
        filter_size=varargin{1};
        HS=filter_size;
        padding_rapid=varargin{2};
        

end


X=size(im,1);
Y=size(im,2);

if strcmp(padding_rapid,'replicate')==1
   im2=padarray(im,[HS-1 HS-1],'replicate','both');
   padding='symmetric';
       
else
    im2=im;
    padding=padding_rapid; 
end

X2=size(im2,1);
Y2=size(im2,2);


acceleration=max(log(HS)*2,1);

if HS>3
    HS_size=floor(HS/acceleration/2)*2+1;
    
else
    HS_size=HS;
end

        disk_filter = fspecial('disk',HS_size);
 
        Hrescale=min(1/(HS/HS_size),1);
        
   
        for i=1:repetition
        im2=imresize(im2,[X2*Hrescale Y2*Hrescale],'bicubic');
        im2=imfilter(im2,disk_filter,padding);   
        im2=imfilter(im2,disk_filter,padding);  
        im2=imfilter(im2,disk_filter,padding);  
        im2=imresize(im2,[X2 Y2],'bicubic');
        end

        
if strcmp(padding_rapid,'replicate')==1
   im2=imcrop(im2,[HS HS Y-1 X-1]);
  
end


end
