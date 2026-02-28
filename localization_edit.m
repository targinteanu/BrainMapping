clear
clc
subjID = 'PD24N007';

ft_defaults

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

%%

fshome     = '/Applications/freesurfer/7.4.1';
subdir     = '/Users/torenarginteanu/Documents/MATLAB/BrainMapping';
mrfile     = [subdir,filesep,subjID,'_MR_acpc.nii'];
system(['export FREESURFER_HOME=' fshome '; ' ...
'source $FREESURFER_HOME/SetUpFreeSurfer.sh; ' ...
'mri_convert -c -oc 0 0 0 ' mrfile ' ' [subdir '/tmp.nii'] '; ' ...
'recon-all -cw256 -i ' [subdir '/tmp.nii'] ' -s ' 'freesurfer' ' -sd ' subdir ' -all'])

% 'recon-all -i '

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

%%
save([subjID, '_hull_lh.mat'], 'hull_lh');

%%

elec_acpc_fr = elec_acpc_f;

cfg             = [];
cfg.keepchannel = 'yes';
cfg.elec        = elec_acpc_fr;
cfg.method      = 'headshape';
cfg.headshape   = hull_rh;
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

%% Anatomical labeling

atlas = ft_read_atlas([ftpath filesep 'template/atlas/brainnetome/BNA_MPM_thr25_1.25mm.nii']);
% template/atlas/aal/ROI_MNI_V4.nii
% template/atlas/brainnetome/BNA_MPM_thr25_1.25mm.nii

% elec_mni_frv

for i = 1:length(elec_fsavg_frs.label)
cfg            = [];
cfg.roi        = elec_fsavg_frs.chanpos(match_str(elec_fsavg_frs.label, string(elec_fsavg_frs.label(i))),:);
cfg.atlas      = atlas;
% cfg.inputcoord = 'mni';
cfg.output     = 'single';
labels = ft_volumelookup(cfg, atlas);

[~, indx] = max(labels.count);
loc_name_full = labels.name{indx};
an_locs(i) = {loc_name_full(1:3)};

end

tbl = reshape(an_locs,[21,3])';
an_locs_form = fliplr(tbl);
an_locs_form = tbl;

%%
save([subjID '_an_locs_form.mat'], 'an_locs_form');
save([subjID '_an_locs.mat'], 'an_locs');

%% plot heatmap of locations

c = categorical(an_locs_form);
[GN, ~, G] = unique(c);
an_locs_num = fliplr(double(reshape(G,[3,21])));
h = heatmap(an_locs_num, 'Colormap', gray,'CellLabelColor','none');
% colorbar off


%% alternative heatmap

elec_num_grid = reshape(1:63,[21,3])';
% elec_num_grid = fliplr(elec_num_grid); % left grids only

tbl = fliplr(an_locs_num);
% tbl = flipud(an_locs_num);
tbl = flipud(tbl);

n=max(G);
cmap = [linspace(.9,0,n)', linspace(.9447,.447,n)', linspace(.9741,.741,n)'];
imagesc(tbl)
colormap(cmap);
axis xy
c = colorbar('Ticks',[1.35,2.1,2.9,3.6],...
    'TickLabels',["Superior\newlineParietal Lobule",...
    "Postcentral\newlineGyrus","Precentral\newlineGyrus",...
    "Precuneus"]);


% "Superior\newlineFrontal Gyrus",
% Middle\newlineFrontal Gyrus",...

c.Ruler.TickLabelRotation=0;
c.TickLabelInterpreter = 'tex';
[xTxt, yTxt] = ndgrid(1:21, 3:-1:1); 
labels = elec_num_grid';
th = text(xTxt(:), yTxt(:), num2str(labels(:)), ...
    'VerticalAlignment', 'middle','HorizontalAlignment','Center');
axis off;

hold on

nx = size(tbl,2);
ny = size(tbl,1);
edge_x = repmat((0:nx)+0.5, ny+1,1);
edge_y = repmat((0:ny)+0.5, nx+1,1).';
plot(edge_x ,edge_y, ' k') % vertical lines
plot(edge_x.', edge_y.', 'k') % horizontal lines

%%
save([subjID '_an_locs_num.mat'], 'an_locs_num');



%% change electrode colors based on anatomy

colordata = zeros(63,3);
ct = categorical(an_locs);
[GN, ~, G] = unique(ct);
n=max(G); 
cmap = [linspace(.9,0,n)', linspace(.9447,.447,n)', linspace(.9741,.741,n)'];
for i = 1:length(G)
    colordata(i,:) = cmap(G(i),:);
end

%% generate XL
%generate_electable_v3('electrode_data.xlsx', 'elec_mni', elec_mni_frv)
generate_electable_v3('electrode_data.xlsx', ...
    'elec_mni', elec_mni_frv, 'fsdir', 'freesurfer')