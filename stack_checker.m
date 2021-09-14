% origin Vincent Fernandez ESRF

function [ProcessDone,FileError,nof,mindif,maxdif]=stack_checker(resultdir,file_type,final_nb,varargin)

% This part of the codes creates variable input parameters using the input
% parser object
p = inputParser;
%   Make input string case independant
p.CaseSensitive = false;

%   Specifies the required inputs
addRequired(p,'resultdir');
addRequired(p,'file_type');
addRequired(p,'final_nb',@isnumeric);

%   Sets the default values for the optional parameters
defaultReadIM           = 0;
defaultEraseCorrupted   = 0;
defaultVerbose          = 1;
defaultThreshold        = 1.000;
defaultOutput_data_type = 'uint16';

%   Create optional inputs
addParamValue(p,'ReadIM',defaultReadIM,@isnumeric);
addParamValue(p,'EraseCorrupted',defaultEraseCorrupted,@isnumeric);
addParamValue(p,'Verbose',defaultVerbose,@isnumeric);
addParamValue(p,'Threshold',defaultThreshold,@isnumeric);
addParamValue(p,'Output_data_type',defaultOutput_data_type);

%   Pass all parameters and input to the parse method
parse(p,resultdir,file_type,final_nb,varargin{:});

%%
switch file_type
    case {'raw','vol','raw*','vol*'}; output_is_stack=0; fprintf('output is volume\n')
    otherwise;                        output_is_stack=1; fprintf('output is a stack\n')
        
end

switch p.Results.Output_data_type
    case 'uint16';        Output_data_type = 2;
    case 'uint8';         Output_data_type = 1;
    case 'float32';       Output_data_type = 4;
    otherwise             Output_data_type = 2;
end
Output_data_type

nof         = 0;         
FileError   = 0;
maxdif      = 0;
mindif      = 100000000000;
fprintf('Checking if result directory exist:\n%s\n',resultdir);

if exist(resultdir,'dir')==7
    if p.Results.Verbose==1
        fprintf('Result directory exists\n');
        fprintf('Checking file number and integrity\n');
    end
    
    check_file=sprintf('%s/*%s',resultdir,file_type);
    fprintf('looking for %1.0f files with the extention %s\n',final_nb,file_type);
    d       = dir(check_file);
    dname   = {d.name};
    nof     = size(d,1);
    
    if nof==final_nb
        if p.Results.Verbose==1
            fprintf('All %1.0f files seems to be there, Checking files integrity...\n',nof);
        end
        
        % defining a minimum acceptable size
        FileBytes =0;
        k         = 1;
        while FileBytes==0
            imname  = sprintf('%s/%s',resultdir,dname{k});
            f       = dir(imname);
            if f.bytes~=0
                switch file_type
                    case 'jp2'
                        FileBytes = round(f.bytes*10/p.Results.Threshold);
                    otherwise                        
                        FileBytes = round(f.bytes/p.Results.Threshold);
                end
                if p.Results.Verbose==1
                    fprintf('ref FileBytes: %1.3f MB\n',FileBytes/1048576);
                end
            else
                k=k+1;
            end
        end
        
        if p.Results.ReadIM==1 && output_is_stack==1
            im0     = imread(imname);
            [X0,Y0] = size(im0);
        end
        
        % refining name list for raw and vol files
        switch file_type
            case {'raw*','vol*'}  
                check_file2=sprintf('%s/*%s',resultdir,file_type(1:end-1));
                d       = dir(check_file2);
                dname   = {d.name};
                nof     = size(d,1);
        end
        
        %checking file size
        for i=1:nof            
            try
                imname=sprintf('%s/%s',resultdir,dname{i});
                f=dir(imname);
                
                switch file_type
                    case 'jp2';     FileBytes2=f.bytes*10;
                    otherwise;      FileBytes2=f.bytes;
                end
                
                switch output_is_stack
                    case 1
                        percent_threshold=abs((FileBytes2-FileBytes)/FileBytes)*100;
                        maxdif=max(maxdif,percent_threshold);
                        mindif=min(mindif,percent_threshold);
                        
                        if percent_threshold>5
                            if p.Results.Verbose==1
                                fprintf('File differs from expected (%1.5f vs %1.5f expected MB)\n%s\n',FileBytes2/1048576,FileBytes/1048576,imname);
                            end
                            
                            FileError=FileError+1;
                            if p.Results.EraseCorrupted==1
                                cmd=sprintf('rm -v %s',imname);
                                unix(cmd)
                            end
                            
                        end
                        
                    otherwise % case of raw or vol files
                        xmlname=[resultdir '/' dname{i} '.xml'];
                        [ SX ] = read_xml_file(xmlname,'subVolume','SIZEX','numeric');
                        [ SY ] = read_xml_file(xmlname,'subVolume','SIZEY','numeric');
                        [ SZ ] = read_xml_file(xmlname,'subVolume','SIZEZ','numeric');
                        expectedSize = SX*SY*SZ*Output_data_type;
                        if FileBytes2~=expectedSize
                            fprintf('File differs from expected (%1.5f vs %1.5f expected MB)\n%s\n',FileBytes2/1048576,expectedSize/1048576,imname);   
                        else
                            %fprintf('%s: File size if ok: %1.3f MB\n',dname{i},expectedSize/1048576)
                        end
                end
            catch
                if p.Results.Verbose==1
                    fprintf('error with file %s\n',imname);
                end
                FileError=FileError+1;
                if p.Results.EraseCorrupted==1 && output_is_stack==1
                    cmd=sprintf('rm -v %s',imname);
                    unix(cmd)
                end
            end
            
            if p.Results.ReadIM==1 && output_is_stack==1
                fprintf('Reading im: %1.0f/%1.0f\r',i,nof);
                im=imread(imname);
                [X1,Y1]=size(im);
                if X1~=X0 || Y1~=Y0
                    fprintf('error with file %s: Wrong dim: %ix%i vs %ix%i (first im)\n',imname,X1,Y1,X0,Y0);
                end
                
                if max2(im)==0
                    fprintf('error with file %s: All pixels at 0\n',imname);
                end
            end
            
        end
        if FileError==0; ProcessDone = 1;
        else             ProcessDone = 0;
        end
        
    elseif nof>final_nb
        fprintf('Too many files in result directory: %1.0f vs %1.0f expected\n',nof,final_nb)
        fprintf('If you have asked for overwrite of previous process, it will be done, otherwise, process will be skipped\n');
        ProcessDone = 1;
        FileError   = nof-final_nb;
    else % result directory created but not all result images are there
        fprintf('Some file missing: %1.0f vs %1.0f\n',nof,final_nb)
        ProcessDone = 0;
    end
else % no result directory
    fprintf('Result directory does not exist\n');
    ProcessDone = 0;
end
fprintf('Verification finished,')

if FileError>0;     fprintf(' %d corrupted files\n',FileError);
else                fprintf('no error\n');
end
if mindif~=100000000000
    fprintf('Size variation range observed (in bytes): Min %1.4f%% - Max %1.4f%%\n',mindif,maxdif);
end
end
