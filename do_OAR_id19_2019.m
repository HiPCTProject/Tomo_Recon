function do_OAR_id19(executable,first,last,njobs,workingdirectory,submitnowflag,gpu_cpu,walltime,otherparameters)
global GPU2USE

%% oar_make_id19  Submit jobs to OAR. 
%  oar_make_id19(executable,first,last,njobs,workingdirectory,submitnowflag,otherparameters)
%
%     This function would replace condor_make, using the new cluster
%     OAR, resource manager and batch scheduler for NICE
%
%     Returns an array with the submitted jobids using OAR.
%     Usage: executable = '/full/path/to/executable.ext' (if not .m)
%                         if executable is not in the pwd;
%                         'executable.ext' if executable is in the pwd;
%                 first = the first image to process
%                  last = the last image to process
%                 njobs = number of total jobs to submitt
%       otherparameters = all the other parameters to be passed to the
%                         executable in a whole string
%                         (ex. 'par1 par2 par3')
%            submitflag = logical to sumbit or not the jobs
%              varargin = the values of the OAR directives 
%                         i.e. 'walltime' '3:00:00' 'mem' 4000
% Inspired from /users/lnervo/zUtil_OAR and /data/id19/archive/matlab/compiled/condor_make_id19

% clean the screen each time
clc


app.name=executable;
app.singleton='/data/id19/inhouse/OAR_UTILITIES/matlab_OAR_launcher_2019b.sh';

app.project='OAR_matlab'

%% check function arguments

if nargin < 2 || nargin < 3
    error('MATLAB:do_OAR_id19:notEnoughArgument','You must give at least three arguments:\n   do_OAR_id19(executable,first,last)')
end

if ~exist('workingdirectory')
    workingdirectory=cleandirectoryname(pwd);
end

if ~exist('njobs','var') || nargin < 5
    njobs=1;
end

if ~exist('gpu_cpu','var') || nargin < 5
    gpu_cpu='cpu';
end

if ~exist('walltime','var') || nargin < 5
    walltime='02:00:00';
end

if ~exist('otherparameters','var') || nargin < 6
    otherparameters='';
end


% create temporary directory for temporary files (/tmp_14_days usually)

logdir='/tmp_14_days/oar/log'
subdir='/tmp_14_days/oar/submit'
%logdir='/data/id19/paleo/OAR/log'
%subdir='/data/id19/paleo/OAR/submit'


% check directories
if ~exist(logdir,'dir')
    [s,msg]=mkdir(logdir); disp(msg)
end

if ~exist(subdir,'dir')
    [s,msg]=mkdir(subdir); disp(msg)
end


%%%%%%%%%%%%%%%%%%%%%
% Create .oar file
%%%%%%%%%%%%%%%%%%%%%
%split executable path
[fdir,fname,fext]=fileparts(app.name);
fndate=datestr(now,'yyyy-mm-dd-HH:MM:SS');

random_num=sprintf('_%4.4i',round(rand*1000));  % to avoid similar names

fulloarname=[subdir '/' fname '.' fndate random_num];
fprintf('oar filename is %s\n\b',fulloarname);
f_oar_id=fopen([fulloarname '.oar'],'w');
fprintf(f_oar_id,'#!/bin/bash\n');
fprintf(f_oar_id,'##for long calculation estimate walltime in hours\n');

switch gpu_cpu
    case 'gpu'
        app.queue='gpu';
        fprintf(f_oar_id,'#OAR -l {gpu=''YES''}/cpu=1,walltime=%s\n',walltime);
     %   fprintf(f_oar_id,'#OAR -t besteffort\n');
    case 'cpu'
        app.queue='nice';
	    fprintf(f_oar_id,'#OAR -l {gpu=''NO''}/core=1,walltime=%s\n',walltime);
    %    fprintf(f_oar_id,'#OAR -t besteffort\n');
    case 'both'
        app.queue='nice';
        fprintf(f_oar_id,'#OAR -l {gpu=''YES''}/core=1,walltime=%s\n',walltime);
		fprintf(f_oar_id,'#OAR -l {gpu=''NO''}/core=1,walltime=%s\n',walltime);
    %    fprintf(f_oar_id,'#OAR -t besteffort\n');
    case 'gpu_node';
        app.queue='gpu';
        fprintf(f_oar_id,'#OAR -l {gpu=''YES''}/nodes=1,walltime=%s\n',walltime);
    %    fprintf(f_oar_id,'#OAR -t besteffort\n');
    case 'cpu_node';
        app.queue='nice';
        fprintf(f_oar_id,'#OAR -l {gpu=''NO''}/nodes=1,walltime=%s\n',walltime);
    %    fprintf(f_oar_id,'#OAR -t besteffort\n');
    case 'debian'
        app.queue='nice';
        fprintf(f_oar_id,'#OAR -l {opsys like ''debian%''}/core=1,walltime=%s \n',walltime);
    case 'debian8'
        app.queue='nice';
        fprintf(f_oar_id,'#OAR -l {opsys=''debian8''}/core=1,walltime=%s \n',walltime);
    case 'debian8_BE'
        app.queue='nice';
        fprintf(f_oar_id,'#OAR -l {opsys=''debian8''}/core=1,walltime=%s \n',walltime);
        fprintf(f_oar_id,'#OAR -t besteffort\n');
        fprintf(f_oar_id,'#OAR -t idempotent\n');    
    case 'all_core_BE'
        app.queue='nice';
        fprintf(f_oar_id,'#OAR -l {gpu=''YES''}/core=1,walltime=%s\n',walltime);
		fprintf(f_oar_id,'#OAR -l {gpu=''NO''}/core=1,walltime=%s\n',walltime);
      %  fprintf(f_oar_id,'#OAR -l {opsys=''debian8''}/core=1,walltime=%s \n',walltime);
        fprintf(f_oar_id,'#OAR -t besteffort\n');
        fprintf(f_oar_id,'#OAR -t idempotent\n');    
        
        

end


fprintf(f_oar_id,'#OAR -O %s.%%jobid%%.out\n',[logdir '/' fname]);
fprintf(f_oar_id,'#OAR -E %s.%%jobid%%.err\n',[logdir '/' fname]);
fprintf(f_oar_id,'#OAR --array-param-file %s\n',[fulloarname '.params']);
fprintf(f_oar_id,'#OAR --project paleo\n');
fprintf(f_oar_id,'#OAR --name %s\n',fname);
fprintf(f_oar_id,'%s $@\n',app.singleton);
fclose(f_oar_id);



fileattrib(  [fulloarname '.oar']  ,'+x')

%%%%%%%%%%%%%%%%%%%%%
% Create .params file
%%%%%%%%%%%%%%%%%%%%%
f_params_id=fopen([fulloarname '.params'],'w');
jobsize=ceil((last-first+1)/njobs);
range_firsts=first:jobsize:last;
range_lasts=range_firsts(2:end)-1;
range_lasts(end+1)=last;
% disp(range_firsts)
for n=1:length(range_firsts)
  fprintf(f_params_id,'%s %d %d %s %s\n', app.name,range_firsts(n),range_lasts(n),workingdirectory,otherparameters);
end
fclose(f_params_id);

if exist('submitnowflag','var') && submitnowflag
  fprintf('Submitting %s to OAR\n',fname);
  system(sprintf('cd %s;oarsub -q %s -S %s',workingdirectory,app.queue,[fulloarname '.oar']));
else
  fprintf('\n\n%s is ready for submission:\n',[fulloarname '.oar']);
  fprintf('...please execute when you are ready:\n\t cd %s;oarsub -q %s -S %s\n\n',workingdirectory,app.queue,[fulloarname '.oar']);
end
end
