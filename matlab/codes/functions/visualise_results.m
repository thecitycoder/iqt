function visualise_results(data_folders, settings)

%% Configurations:
% Paths:
input_dir = settings.input_dir;
output_dir = settings.output_dir;
trees_dir = settings.trees_dir;
trees_list = settings.trees_list;
patchlibs_dir = settings.patchlibs_dir;
dt_name = settings.dt_name;
rescale_factor = 1.0;
scale_const = 1E-3;

% Data:
subsample_rate=settings.subsample_rate;
fv=settings.feature_version;

% Problem:
ds=settings.upsample_rate;
n=settings.input_radius;
m=ds;
edge_recon = settings.edge; % true if you want to reconstruct on the edge
tail_name = sprintf('DS%02i_%ix%ix%i_%ix%ix%i_Sub%03i', ds, 2*n+1,2*n+1,2*n+1, m, m, m, subsample_rate)
tree_name = ['RegTreeValV' int2str(fv) '_' tail_name '_'];

trees={}; 
for k= 1:length(trees_list)
    tmp=load(sprintf([trees_dir '/' tree_name '%04i.mat'], trees_list(k)));
    trees{k} = tmp.tree;
end

if edge_recon % Reconstruct on the boundary.
   % reconstruct and save the estimated DTI and precision map:
   output_subdir  = sprintf(['RF_Edge_V' int2str(fv) '_NoTree%02i_' tail_name], length(trees_list));
else
   % reconstruct and save the estimated DTI and precision map:
   output_subdir  = sprintf(['RF_V' int2str(fv) '_NoTree%02i_' tail_name], length(trees_list));
end



%% Load low-res, high-res, estimate
for dataid = 1:length(data_folders)
    display(sprintf(['\nReconstructing: ' data_folders{dataid} '\n']))
    output_folder = [output_dir '/' data_folders{dataid}];
    if(~exist(output_folder))
        mkdir(output_folder);
    end
    
    % Load the data:
    file_orig = [input_dir '/' data_folders{dataid} '/' dt_name];
    dt_hr = ReadDT_Volume(file_orig);
    
    file_est = [output_folder '/' output_subdir '/dt_recon_']
    dt_est = ReadDT_Volume(file_est);
    
    file_low = [ input_dir '/' data_folders{dataid} '/' dt_name sprintf('lowres_%i_', ds)];
    dt_lr = ReadDT_Volume(file_low);
    dt_lr = dt_lr(1:ds:end,1:ds:end,1:ds:end,:);
    
    % Take a slice, and compute MD, FA, CFA.
    slice_region = '(:,:,70,:)';
    slice_region_lr = '(:,:,round(70/ds),:)';
    
    slice_lr=eval(['dt_lr' slice_region_lr]); dt_lr=[];
    slice_est=eval(['dt_est' slice_region]); dt_est=[]; 
    slice_hr=eval(['dt_hr' slice_region]); dt_hr=[];
    
    [md_lr, fa_lr, cfa_lr] = compute_MD_FA_CFA(slice_lr);
    [md_est, fa_est, cfa_est] = compute_MD_FA_CFA(slice_est);
    [md_hr, fa_hr, cfa_hr] = compute_MD_FA_CFA(slice_hr);
    
    % Flip:
    md_lr = flipud(md_lr');
    md_est = flipud(md_est');
    md_hr = flipud(md_hr');
    
    fa_lr = flipud(fa_lr');
    fa_est = flipud(fa_est');
    fa_hr = flipud(fa_hr');
    
    cfa_lr2(:,:,1) = flipud(cfa_lr(:,:,1)');
    cfa_lr2(:,:,2) = flipud(cfa_lr(:,:,2)');
    cfa_lr2(:,:,3) = flipud(cfa_lr(:,:,3)');
    cfa_est2(:,:,1) = flipud(cfa_est(:,:,1)');
    cfa_est2(:,:,2) = flipud(cfa_est(:,:,2)');
    cfa_est2(:,:,3) = flipud(cfa_est(:,:,3)');
    cfa_hr2(:,:,1) = flipud(cfa_hr(:,:,1)');
    cfa_hr2(:,:,2) = flipud(cfa_hr(:,:,2)');
    cfa_hr2(:,:,3) = flipud(cfa_hr(:,:,3)');
    
    % Plot:
    margin = [0.02,0.02];
    fig=figure; 
    subplot_tight(3,3,1,margin)
    imshow(md_lr,[]);
    title('Low-res input')
    ylabel('MD')
    subplot_tight(3,3,2,margin)
    imshow(md_est,[]);
    title('IQT-RF outut')
    subplot_tight(3,3,3,margin)
    imshow(md_hr,[]);
    title('Ground truth high-res')
    
    subplot_tight(3,3,4,margin)
    imshow(cfa_lr2,[]);
    ylabel('CFA')
    subplot_tight(3,3,5,margin)
    imshow(cfa_est2,[]);
    subplot_tight(3,3,6,margin)
    imshow(cfa_hr2,[]);
    
    subplot_tight(3,3,7,margin)
    imshow(fa_lr,[]);
    ylabel('FA')
    subplot_tight(3,3,8,margin)
    imshow(fa_est,[]);
    subplot_tight(3,3,9,margin)
    imshow(fa_hr,[]);
    
    %Save as a .fig file.
    disp('Save tbe figure as a PNG file:')
    filename = [output_folder '/' output_subdir '/image.fig'];
    disp(['see ' filename])
    saveas(fig,filename)
end