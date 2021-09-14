% function to make fast 2D median combining image rescaling with medfilt2
% using the same input parameters than medfilt2, but allowing replicate
% padding


% origin Paul Tafforeau ESRF 05/2010

function im2=medfilt_rapid(im,varargin)

repetition=2; % number of pass to avoid aliasing
speed_factor=3; % general acceleration factor (important for large filter sizes)

switch (nargin)
    case 1
        HS=3;
        VS=3;
        padding_rapid='symmetric';
        
   
    case 2
        filter_size=varargin{1};

        HS=filter_size(1);
        VS=filter_size(2);
        
        padding_rapid='symmetric';

    case 3
        filter_size=varargin{1};

        HS=filter_size(1);
        VS=filter_size(2);

        padding_rapid=varargin{2};
        

end


X=size(im,1);
Y=size(im,2);

if strcmp(padding_rapid,'replicate')==1
   im2=padarray(im,[HS-1 VS-1],'replicate','both');
   padding='symmetric';
       
else
    im2=im;
    padding=padding_rapid; 
end

X2=size(im2,1);
Y2=size(im2,2);


Hacceleration=max(log(HS)*speed_factor,1);
Vacceleration=max(log(VS)*speed_factor,1);

if HS>3
    HS_size=floor(HS/Hacceleration/2)*2+1;
    
else
    HS_size=HS;
end

if VS>3
    VS_size=floor(VS/Vacceleration/2)*2+1;
else
    VS_size=VS;
end


  
        Vrescale=min(1/(VS/VS_size),1);
        Hrescale=min(1/(HS/HS_size),1);
        
   
        for i=1:repetition
        im2=imresize(im2,[X2*Hrescale Y2*Vrescale],'bicubic');
        im2=medfilt2(im2,[HS_size VS_size],padding);
        im2=imresize(im2,[X2 Y2],'bicubic');
        end

        
if strcmp(padding_rapid,'replicate')==1
   im2=imcrop(im2,[VS HS Y-1 X-1]);
  
end


end
