% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% possible preset : core_biopsies  organ_local
% origin Paul Tafforeau ESRF 2020


function covid_master_half_acquisition_master_OAR(radix,preset,varargin)


dirlist=dir([radix '*_']);
dirnum=size(dirlist,1);
dirname={dirlist.name};

switch nargin
    case 2
        first_dir=1
    case 3
        first_dir=varargin{1}
end

fprintf ('I found %1.0f scans to be processed \n',dirnum);

for i=first_dir:dirnum
    dir_name=dirname{i};
    num_dir=str2num(dir_name(end-3:end-1));
    covid_half_acquisition_master_OAR(radix,num_dir,0,preset);
end




end
