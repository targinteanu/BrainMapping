%% Cortical Electrode Localization - part 3 of 4
% Place electrodes on cortical mesh obtained from freesurfer.
% see fieldtrip tutorial (fieldtriptoolbox.org/tutorial/intracranial/human_ecog/)  

ft_defaults

if ~exist('subjID', 'var')
    [filename, filepath] = uigetfile('*_CT.nii');
    subjID = filename(1:(end-7));
    clear filename filepath
end

%%
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

%%

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

%%
ft_hastoolbox('spm12', 1);
ct_acpc = ft_convert_coordsys(ct_ctf, 'acpc',0);

%%
cfg             = [];
cfg.method      = 'spm';
cfg.spmversion  = 'spm12';
cfg.coordsys    = 'acpc';
cfg.viewresult  = 'yes';
ct_acpc_f = ft_volumerealign(cfg, ct_acpc, fsmri_acpc);

%%

cfg           = [];
cfg.filename  = [subjID '_CT_acpc_f'];
cfg.filetype  = 'nifti';
cfg.parameter = 'anatomy';
ft_volumewrite(cfg, ct_acpc_f);

%%

% ct_acpc_f = ft_read_mri([subjID '_CT_acpc_f.nii']);

cfg = [];
elec_acpc_f = ft_electrodeplacement(cfg, ct_acpc_f, fsmri_acpc);

%%
save([subjID '_elec_acpc_f.mat'], 'elec_acpc_f');

%%

figure;

ft_plot_ortho(fsmri_acpc.anatomy, 'transform', fsmri_acpc.transform, 'style', 'intersect');
ft_plot_sens(elec_acpc_f, 'label', 'on', 'fontcolor', 'w');

%%

cfg           = [];
cfg.method    = 'cortexhull';
cfg.headshape = 'freesurfer/surf/lh.pial';
cfg.fshome    = '/Applications/freesurfer/7.4.1';
hull_lh = ft_prepare_mesh(cfg);

cfg           = [];
cfg.method    = 'cortexhull';
cfg.headshape = 'freesurfer/surf/rh.pial';
cfg.fshome    = '/Applications/freesurfer/7.4.1';
hull_rh = ft_prepare_mesh(cfg);

%%
save([subjID, '_hull_lh.mat'], 'hull_lh');
save([subjID, '_hull_rh.mat'], 'hull_rh');

%%

hullside = questdlg('On which side (hemisphere) are the cortical electrodes?', ...
    'Cortex Electrode Laterality', 'Left', 'Right', 'Left');
if strcmp(hullside, 'Left')
    hullside = hull_lh;
elseif strcmp(hullside, 'Right')
    hullside = hull_rh;
else
    error('Selection must be made.')
end

elec_acpc_fr = elec_acpc_f;

cfg             = [];
cfg.keepchannel = 'yes';
cfg.elec        = elec_acpc_fr;
cfg.method      = 'headshape';
cfg.headshape   = hullside;
cfg.warp        = 'dykstra2012';
cfg.feedback    = 'yes';
elec_acpc_fr = ft_electroderealign(cfg);

%%
save([subjID '_elec_acpc_fr.mat'], 'elec_acpc_fr');

%%
figure;
% figure(2)
ft_plot_mesh(pial_lh);
ft_plot_mesh(pial_rh);
el=ft_plot_sens(elec_acpc_fr);
%el.CData = colordata;
el.SizeData = 100;
el.Marker = "o";
el.MarkerFaceColor = 'flat';
el.MarkerEdgeColor = 'k';
% view([66.1890, 39.71]);
material dull;
lighting gouraud;
camlight;

%%

cfg            = [];
cfg.elec       = elec_acpc_fr;
cfg.method     = 'mni';
cfg.mri        = fsmri_acpc;
cfg.spmversion = 'spm12';
cfg.spmmethod  = 'new';
cfg.nonlinear  = 'yes';
elec_mni_frv = ft_electroderealign(cfg);

%%

cfg           = [];
cfg.elec      = elec_acpc_fr;
cfg.method    = 'headshape';
cfg.headshape = 'freesurfer/surf/rh.pial';
cfg.warp      = 'fsaverage';
cfg.fshome    = '/Applications/freesurfer/7.4.1';
elec_fsavg_frs = ft_electroderealign(cfg);

%%
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

%%

save([subjID '_elec_mni_frv.mat'], 'elec_mni_frv');
save([subjID '_elec_fsavg_frs.mat'], 'elec_fsavg_frs');