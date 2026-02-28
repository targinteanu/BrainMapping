%% Cortical Electrode Localization - part 1 of 4
% Manually prepare MRI file for freesurfer. 
% see fieldtrip tutorial (fieldtriptoolbox.org/tutorial/intracranial/human_ecog/)  

clear
clc

ft_defaults

% find MRI and CT files and transfer to current folder
[filename, filepath] = uigetfile('*_MRI.nii');
subjID = filename(1:(end-8));
copyfile(fullfile(filepath,filename), cd);
copyfile(fullfile(filepath,[subjID '_CT.nii']), cd);

%% MRI preprocessing

mri = ft_read_mri([subjID '_MRI.nii']);
% mri = ft_read_mri('cropped_resampled_mri.nii');
ft_determine_coordsys(mri);
%%
cfg           = [];
cfg.method    = 'interactive';
cfg.coordsys  = 'acpc';
mri_acpc = ft_volumerealign(cfg, mri);

%%
cfg           = [];
cfg.filename  = [subjID '_MR_acpc'];
cfg.filetype  = 'nifti';
cfg.parameter = 'anatomy';
ft_volumewrite(cfg, mri_acpc);