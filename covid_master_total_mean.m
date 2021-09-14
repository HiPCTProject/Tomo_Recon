% function to prepare tetra-acquisition scans by concatenation and complete
% normalisation of the HA and TA scans. Concatenation on one side only in
% order to keep the fine tuning of center of rotation and to generate
% classical HA scans with large field of view
% origin Paul Tafforeau ESRF 2020


function covid_master_total_mean(radix)


dirlist=dir(radix);
dirnum=size(dirlist,1);
dirname={dirlist.name};

fprintf ('I found %1.0f scans to be processed \n',dirnum);

for i=1:dirnum
    dir_name=dirname{i};
    cd (dir_name)
    covid_total_mean;
    cd ..
end




end
