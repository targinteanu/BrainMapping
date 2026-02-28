disp('Select base path for subject.')
subjpath = uigetdir('', 'Subject save directory'); 
disp('Select folder containing MRI files.')
MRpath = uigetdir(subjpath, 'MRI image directory');
disp('Select folder containing CT files.')
CTpath = uigetdir(subjpath, 'CT image directory');

[~,subjID] = fileparts(subjpath);

disp('Please select a good quality, T1-weighted MRI series.')
disp('Export it to workspace as V and spatialDetails, then press Enter here.')
dicomBrowser(MRpath); pause;

v = squeeze(V); 
PixelSpacings = mean(spatialDetails.PixelSpacings);
niftiwrite(v, 'tempnifti');
ifo = niftiinfo('tempnifti');
delete('tempnifti.nii');
ifo.PixelDimensions = [PixelSpacings, 1];
niftiwrite(v, [subjpath,filesep,subjID,'_MRI'], ifo);

clear v V spatialDetails PixelSpacings ifo

disp('Please select a good quality CT series that shows the electrodes.')
disp('Export it to workspace as V and spatialDetails, then press Enter here.')
dicomBrowser(CTpath); pause;

v = squeeze(V); 
PixelSpacings = mean(spatialDetails.PixelSpacings);
niftiwrite(v, 'tempnifti');
ifo = niftiinfo('tempnifti');
delete('tempnifti.nii');
ifo.PixelDimensions = [PixelSpacings, 1];
niftiwrite(v, [subjpath,filesep,subjID,'_CT'], ifo);