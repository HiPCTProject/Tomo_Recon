% function to make an image convolution using GPU if available
% function of matlab by using the same input parameters



function im2=imfilter_GPU(im,conv,varargin)


switch nargin
    case 2
       padding_mode='replicate';
    case 3
        padding_mode=varargin{1};
end


%% test for GPU machine

GPU=0;
% 
% [toto,GPU_test]=unix('hostname') ;
% 
% GPU_test=GPU_test(1:5);
% 
% if sprintf(GPU_test)=='x4170'
%     GPU=1;
%  
% else
%     GPU=0;
%    
% end

%% conversion of pictures in double into single precision

    orig_class=class(im);
   
if GPU==1    
    
       im=single(im);
       conv=single(conv);
   
end


%% median filtering using the GPU median system

if GPU==1
    im2=cudaimconvolution(im,conv,padding_mode);

else
    im2=imfilter(im,conv,padding_mode);
end


%% going back to double with the original grey level scale

if GPU==1

     
    switch orig_class
        case 'uint16'
            im2=uint16(im2);
        case 'double'
            im2=double(im2);
        case 'uint8'
            im2=uint8(im2);
        case 'int8'
            im2=int8(im2);
        case 'int16'
            im2=int16(im2);
    end
     
end

%%

end
