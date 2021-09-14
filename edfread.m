% function im=edfread(filename)
% reads an image in edf format into the matrix im
% returns -1 if reading was not successful
% uses the information in the header (Dim_1,Dim_2,DataType)
% please don't specify dimensions when calling edfread
% datatype can be UnsignedByte, UnsignedShort, UnsignedInteger=UnsignedLong, Float=Real, DoubleValue
% 
% origin: Peter Cloetens ESRF 
%
% see also: EDFWRITE

function im=edfread(filename,varargin)

headerlength=1024;

switch nargin
    case 3
	  rows = varargin{1};
	  columns = varargin{2};
    case 4
      rows = varargin{1};
	  columns = varargin{2};
      layers =varargin{3}  ;
end

fid=fopen(filename,'r');

if fid==-1
	im=fid;
	disp(sprintf('!!! Error opening file %s !!!',filename))
else
	hd=readedfheader(fid);
    
    byteorder=findheader(hd,'ByteOrder','string');
    fidpos=ftell(fid); % store present position in file
    fclose(fid); 
    if strcmp(byteorder,'HighByteFirst')
        byteorder='b';
    else
        byteorder='l';
    end
    fid=fopen(filename,'r',byteorder); % re-open with good format
    fseek(fid,fidpos,0); % re-position at end of header
    
    xsize=findheader(hd,'Dim_1','integer');
	ysize=findheader(hd,'Dim_2','integer');
    zsize=findheader(hd,'Dim_3','integer');
    if isempty(zsize)
        zsize=1;
    end

    datatype=findheader(hd,'DataType','string');
	switch datatype
		case 'UnsignedByte',
			datatype='uint8';
			nbytes=1;
		case 'UnsignedShort',
			datatype='uint16';
			nbytes=2;
		case {'UnsignedInteger','UnsignedLong'}
			datatype='uint32';
			nbytes=4;
        case {'SignedInteger','SignedLong'}
			datatype='int32';
			nbytes=4;    
 		case {'Float','FloatValue','FLOATVALUE','Real'}
			datatype='float32';
			nbytes=4;
        case {'SignedLong'}
			datatype='int32';
			nbytes=4;  
        case 'DoubleValue'
			datatype='float64';
			nbytes=8;
%etcetera
	end
    
    if isempty(who('rows'))
        rows=1:xsize;
    end
    if isempty(who('columns'))
        columns=1:ysize;
    end
    if isempty(who('layers'))
        layers=1:zsize;
    end

    if zsize==1
     	fseek(fid,nbytes*(rows(1)-1+(columns(1)-1)*xsize),0);
	    im=fread(fid,[length(rows),length(columns)],sprintf('%d*%s',length(rows),datatype),nbytes*(xsize-length(rows)));
    else
        j=1;
        for i=layers
            fseek(fid,1024+nbytes*(rows(1)-1+(columns(1)-1)*xsize+xsize*ysize*(i-1)),-1);
            im(:,:,j)=fread(fid,[length(rows),length(columns)],sprintf('%d*%s',length(rows),datatype),nbytes*(xsize-length(rows)));        
            j=j+1;
        end
    end    
    st=fclose(fid);
    
end
