%% Cortical Electrode Localization - part 2 of 4
% MRI processing in freesurfer. This takes several hours and only works on
% mac or linux. 

%fshome     = '/Applications/freesurfer/7.4.1';
fshome     = '/Applications/freesurfer/8.1.0'; 
subdir     = cd;
mrfile     = [subdir,filesep,subjID,'_MR_acpc.nii'];
syscmd = ['export FREESURFER_HOME=' fshome '; ' ...
'source $FREESURFER_HOME/SetUpFreeSurfer.sh; ' ...
'export FS_V8_XOPTS=0 && recon-all -all -i; ' ... for freesurfer version 8
'mri_convert -c -oc 0 0 0 ' mrfile ' ' [subdir '/tmp.nii'] '; ' ...
'recon-all -cw256 -i ' [subdir '/tmp.nii'] ' -s ' 'freesurfer' ' -sd ' subdir ' -all'];
disp(' ')
disp(syscmd)
disp(' ')
runsyscmd = input('Copy the above into a unix terminal, or press Y to run it in MATLAB now [Y/n]: ', 's');
if strcmpi(runsyscmd, 'Y')
    system(syscmd)
end

% 'recon-all -i '