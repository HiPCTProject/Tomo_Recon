% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% origin Paul Tafforeau ESRF 2020


function covid_master_tetra_acquisition_master_OAR(radix)


dirlist=dir([radix '*HA_*_']);
dirnum=size(dirlist,1);
dirname={dirlist.name};

fprintf ('I found %1.0f scans to be processed \n',dirnum);

for i=1:dirnum
    dir_name=dirname{i};
    num_dir=str2num(dir_name(end-3:end-1));
    covid_tetra_acquisition_master_OAR(radix,num_dir,0);
end




end
