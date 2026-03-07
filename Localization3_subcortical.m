%% Cortical Electrode Localization - part 3 of 4
% Place electrodes on cortical mesh obtained from freesurfer.
% see fieldtrip tutorial (fieldtriptoolbox.org/tutorial/intracranial/human_ecog/)  

ft_defaults

%fshome     = '/Applications/freesurfer/7.4.1';
fshome     = '/Applications/freesurfer/8.1.0'; 

if ~exist('subjID', 'var')
    [filename, filepath] = uigetfile('*_CT.nii');
    subjID = filename(1:(end-7));
    clear filename filepath
end

%% show brain 3D obj without electrodes
% output from freesurfer processing MRI

figure; 

pial_lh = ft_read_headshape('freesurfer/surf/lh.pial.T1');
pial_lh.coordsys = 'acpc';
ft_plot_mesh(pial_lh);
lighting gouraud;
camlight;

pial_rh = ft_read_headshape('freesurfer/surf/rh.pial.T1');
pial_rh.coordsys = 'acpc';
ft_plot_mesh(pial_rh);
lighting gouraud;
camlight;

%% load MRI files

mri_acpc = ft_read_mri([subjID '_MR_acpc.nii']);
fsmri_acpc = ft_read_mri('freesurfer/mri/T1.mgz');
fsmri_acpc.coordsys = 'acpc';

%% CT preprocessing

ct = ft_read_mri([subjID '_CT.nii']);

ft_determine_coordsys(ct);

cfg           = [];
cfg.method    = 'interactive';
cfg.coordsys  = 'ctf';
ct_ctf = ft_volumerealign(cfg, ct);

%% convert CT to MRI space
ft_hastoolbox('spm12', 1);
ct_acpc = ft_convert_coordsys(ct_ctf, 'acpc',0);

%% align CT with MRI
cfg             = [];
cfg.method      = 'spm';
cfg.spmversion  = 'spm12';
cfg.coordsys    = 'acpc';
cfg.viewresult  = 'yes';
ct_acpc_f = ft_volumerealign(cfg, ct_acpc, fsmri_acpc);

%% save

cfg           = [];
cfg.filename  = [subjID '_CT_acpc_f'];
cfg.filetype  = 'nifti';
cfg.parameter = 'anatomy';
ft_volumewrite(cfg, ct_acpc_f);

%% identify electrodes from CT (manually)

% ct_acpc_f = ft_read_mri([subjID '_CT_acpc_f.nii']);

cfg = [];
elec_acpc_f = ft_electrodeplacement(cfg, ct_acpc_f, fsmri_acpc);

%% save
save([subjID '_elec_acpc_f.mat'], 'elec_acpc_f');

%% view result of electrode placement
% against orthogonal 2D slices of MRI

figure;

ft_plot_ortho(fsmri_acpc.anatomy, 'transform', fsmri_acpc.transform, 'style', 'intersect');
ft_plot_sens(elec_acpc_f, 'label', 'on', 'fontcolor', 'w');

%% load cortex hulls 
% for each hemisphere

cfg           = [];
cfg.method    = 'cortexhull';
cfg.headshape = 'freesurfer/surf/lh.pial';
cfg.fshome    = fshome;
hull_lh = ft_prepare_mesh(cfg);

cfg           = [];
cfg.method    = 'cortexhull';
cfg.headshape = 'freesurfer/surf/rh.pial';
cfg.fshome    = fshome;
hull_rh = ft_prepare_mesh(cfg);

%% save
save([subjID, '_hull_lh.mat'], 'hull_lh');
save([subjID, '_hull_rh.mat'], 'hull_rh');

%% show electrodes on 3D brain obj
figure;
% figure(2)
ft_plot_mesh(pial_lh);
ft_plot_mesh(pial_rh);
el=ft_plot_sens(elec_acpc_f);
%el.CData = colordata;
el.SizeData = 100;
el.Marker = "o";
el.MarkerFaceColor = 'flat';
el.MarkerEdgeColor = 'k';
% view([66.1890, 39.71]);
material dull;
lighting gouraud;
camlight;

%% convert to MNI space 

cfg            = [];
cfg.elec       = elec_acpc_f;
cfg.method     = 'mni';
cfg.mri        = fsmri_acpc;
cfg.spmversion = 'spm12';
cfg.spmmethod  = 'new';
cfg.nonlinear  = 'yes';
elec_mni_frv = ft_electroderealign(cfg);

%% choose laterality
% TO DO: adjust this and the following section to handle when there are
% electrodes on both sides!

lat = input('On which side (hemisphere) are the electrodes (L/R)? ', "s");
lat = lower(lat);
if contains(lat, 'left') | strcmp(lat, 'l') | strcmp(lat, 'lh')
    hullside = hull_lh;
    lat = 'l';
elseif contains(lat, 'right') | strcmp(lat, 'r') | strcmp(lat, 'rh')
    hullside = hull_rh;
    lat = 'r';
else
    error('Selection (L/R) must be made.')
end

%% warp to fsavg brain
% If this section fails to run, examine the warning that shows up before
% the error for missing files. FreeSurfer creates shortcuts/aliases that
% may be lost when transferring files. This error can sometimes be fixed
% as follows. In the subject's folder freesurfer/surf, duplicate the file
% "*h.sphere.reg" as "*h.pial.sphere.reg" [substituting "*" for "l" and/or 
% "r"]. If it still doesn't work, in the folder at fshome (i.e. in
% /Applications/freesurfer/[version]), in the folder
% subjects/fsaverage/surf, do the same, and also duplicate "*h.pial" as
% "*h.pial.pial". 

cfg           = [];
cfg.elec      = elec_acpc_f;
cfg.method    = 'headshape';
cfg.headshape = ['freesurfer/surf/',lat,'h.pial.T1'];
cfg.warp      = 'fsaverage';
cfg.fshome    = fshome;
elec_fsavg_frs = ft_electroderealign(cfg);

%% show warped electrodes on 3D fsavg brain
figure; 
pial_lh_avg = ft_read_headshape(fullfile(fshome,'subjects','fsaverage','surf','lh.pial'));
pial_rh_avg = ft_read_headshape(fullfile(fshome,'subjects','fsaverage','surf','rh.pial'));
ft_plot_mesh(pial_lh_avg);
ft_plot_mesh(pial_rh_avg);
el=ft_plot_sens(elec_fsavg_frs);
%el.CData = colordata;
el.SizeData = 100;
el.Marker = "o";
el.MarkerFaceColor = 'flat';
el.MarkerEdgeColor = 'k';
% view([66.1890, 39.71]);
material dull;
lighting gouraud;
camlight;

%% show the electrodes in MNI space on a 3D template brain
figure;
[ftver, ftpath] = ft_version;
load([ftpath filesep 'template/anatomy/surface_pial_left.mat']);

% rename the variable that we read from the file, as not to confuse it with the MATLAB mesh plotting function   
template_lh = mesh; clear mesh;

%right hemisphere
load([ftpath filesep 'template/anatomy/surface_pial_right.mat']);
template_rh = mesh; clear mesh;

ft_plot_mesh(template_rh);
hold on
ft_plot_mesh(template_lh);
ft_plot_sens(elec_mni_frv);
view([-90 20]);
material dull;
lighting gouraud;
camlight;

%% save space-transformed electrode coordinates

save([subjID '_elec_mni_frv.mat'], 'elec_mni_frv');
save([subjID '_elec_fsavg_frs.mat'], 'elec_fsavg_frs');