function imwrite_secure(im,imname,CompressionString,CompressionFactor)

ImageWrittenOK=0;
[X0,Y0]=size(im);
ExpectedSize=round(((X0*Y0*2)/CompressionFactor)*0.8);
trials=1;

while ImageWrittenOK==0
    
    imwrite(im,imname,CompressionString,CompressionFactor);
    try
        f=dir(imname);       
        if f.bytes>ExpectedSize
            ImageWrittenOK=1;
        else
            trials=trials+1;
        end
    catch
        fprintf('no files\n'); trials=trials+1;
    end
    if trials>10
        fprintf('The file could not be written\n');
        return
    end
        
end


end

