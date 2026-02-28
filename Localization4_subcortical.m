%% Cortical Electrode Localization - part 4 of 4
% Anatomical labeling
% see fieldtrip tutorial (fieldtriptoolbox.org/tutorial/intracranial/human_ecog/)  
% Depth electrodes TO DO; see fieldtrip tutorial sections 53 onwards

ft_defaults

if ~exist('subjID', 'var')
    [ftver, ftpath] = ft_version;
    [filename, filepath] = uigetfile('*_CT.nii');
    subjID = filename(1:(end-7));
    clear filename filepath
    load([subjID '_elec_mni_frv.mat'])
    load([subjID '_elec_fsavg_frs.mat'])
end

%% 

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

%{
tbl = reshape(an_locs,[21,3])';
an_locs_form = fliplr(tbl);
an_locs_form = tbl;
%}

%%
%save([subjID '_an_locs_form.mat'], 'an_locs_form');
save([subjID '_an_locs.mat'], 'an_locs');
%{
%% plot heatmap of locations
figure;
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
%}
%% generate XL
%generate_electable_v3('electrode_data.xlsx', 'elec_mni', elec_mni_frv)
generate_electable_v3([subjID '_electrode_data.xlsx'], ...
    'elec_mni', elec_mni_frv, 'fsdir', 'freesurfer')