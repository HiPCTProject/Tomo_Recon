% ## Copyright (C) 2008 P. Cloetens
% ## 
% ## This program is free software; you can redistribute it and/or modify
% ## it under the terms of the GNU General Public License as published by
% ## the Free Software Foundation; either version 2 of the License, or
% ## (at your option) any later version.
% ## 
% ## This program is distributed in the hope that it will be useful,
% ## but WITHOUT ANY WARRANTY; without even the implied warranty of
% ## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% ## GNU General Public License for more details.
% ## 
% ## You should have received a copy of the GNU General Public License
% ## along with this program; if not, write to the Free Software
% ## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
% 
% ## cleandirectoryname
% ## n1 = cleandirectoryname(varargin)
% ##      cleans up the directory name for NFS mounts
% ##          that appear as /mntdirect/_users, /mntdirect/_data_visitor etc
% ##      
% ##      arguments:
% ##      argument 1: name of directory to be cleaned ( default: result of pwd )
% 
% ## Author: P. Cloetens <cloetens@esrf>
% ## 
% ## 2008-12-17 P. Cloetens <cloetens@esrf>
% ## * Initial revision
% 
function n1 = cleandirectoryname(varargin)
    switch nargin
        case 0
            n1 = directorynamecleanup(pwd);  % present working directory
            n1 = inputwdefault('name of directory', n1);
        case 1
            n1 = directorynamecleanup(varargin{1});
	end
end

% ###########################
% ###     subfunctions    ###
% ###########################

function n1 = directorynamecleanup(n1)
    rootmntdirect = '/mntdirect/';
    ndx = strfind(n1, rootmntdirect);

    if ndx 
        if length(n1) > length(rootmntdirect)
            [dirfirst, dirlast] = strtok(n1(length(rootmntdirect)+1:end), '/');
            dirfirst = mntnamecleanup(dirfirst);
            if isempty(dirlast)
                n1 = dirfirst;
            else
                n1 = fullfile(dirfirst, dirlast);
			end
		end
	end
end

function mntname = mntnamecleanup(mntname)
    if ( mntname(1) == '_' )
        mntname(1) = '/';
        if ~strcmp(mntname, '/tmp_14_days')
%             # this is the only mountname containing real underscores
            mntname = strrep(mntname, '_', '/');
		end
	end
end


