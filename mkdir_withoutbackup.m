% mkdir_withoutbackup
% function [status, message] = mkdir_withoutbackup(dir)
%      create directory on ESRF filesystem that will not be backuped
%      
%      arguments:
%      argument 1: dir to create

%% Author: Peter Cloetens <cloetens@esrf.fr>
%% 
%% 2011-07-06 Peter Cloetens <cloetens@esrf.fr>
%% * Initial revision

function [status, message] = mkdir_withoutbackup(dir)
    if ~exist(dir, 'dir')
        [dirroot, dirpart, dirsuffix] = fileparts(dir);
        dirpart = [dirpart dirsuffix];
        dirparthidden = ['.' dirpart '_nobackup'];
        dirhidden = fullfile(dirroot, dirparthidden);
        [status, message] = mkdir(dirhidden);
        cmd = sprintf('ln -s %s %s', dirparthidden, dir);
        system(cmd);
    else
        disp(sprintf('Directory %s exists, we do nothing\n', dir))
    end
end
