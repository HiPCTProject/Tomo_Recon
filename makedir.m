function makedir( resultdir )
    %%%%%%%%%%%%%%%%%
    % create result directory if not-existing
    % and apply chmod 777
    % Usage: 
    %       makedir( resultdir )
    %%%%%%%%%%%%%%%%%
    newdirectory=isempty(what(resultdir));
    if newdirectory
        [stat,result]=unix(sprintf('mkdir %s',resultdir));
        if stat==0
            fprintf('New directory %s created successfully\n',resultdir);
            unix(sprintf('chmod 777 %s',resultdir));
        else            
            fprintf('Problems creating new directory, permissions ???\n%s',result)
            return % EXITING PROGRAM !!!
        end
    end
end

