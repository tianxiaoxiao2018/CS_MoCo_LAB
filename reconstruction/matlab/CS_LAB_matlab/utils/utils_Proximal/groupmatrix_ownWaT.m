function [ G_mat, Gt_mat, waveS_l1, waveS_l12, waveS_WaT ] = groupmatrix_ownWaT(n1,n2,wavelevel,waveletname_l1,waveletname_l12)
% creates the matrices needed to perform an tree group thresholding of waveletcoeffs.
% based on the implementation of WaTMRI by Huang et al.
% G_mat: matrix with indices according to second element of the wavelettree groups
% Gt_mat: inverse mapping of the wavelet coeffs
%
% (c) Marc Fischer, Thomas Kuestner
% ---------------------------------------------------------------------

image = zeros(n1,n2);
[~, waveS_l1] = wavedec2(image,wavelevel,waveletname_l1);
[~, waveS_l12] = wavedec2(image,wavelevel,waveletname_l12);
% make image bigger to cope uneven filter response
if ~strcmp(waveletname_l12,'db1')
    n1 = n1 + ceil(n1/3);
    n2 = n2 + ceil(n2/3);
end;
image = zeros(n1,n2);
[C, waveS_WaT] = wavedec2(image,wavelevel,waveletname_l12);



length_coeff = size(C,2);

% can also be used to visualize wavecoeffs;
coeff.cA{1,wavelevel} = reshape(C(1,1:waveS_WaT(1,1)*waveS_WaT(1,2)),waveS_WaT(1,1),waveS_WaT(1,2));
index_last = waveS_WaT(1,1)*waveS_WaT(1,2);

for i=2:wavelevel+1
   coeff.cH{1,wavelevel+2-i} = reshape(C(1,1+index_last:waveS_WaT(i,1)*waveS_WaT(i,2)+index_last),waveS_WaT(i,1),waveS_WaT(i,2));
   coeff.cV{1,wavelevel+2-i} = reshape(C(1,waveS_WaT(i,1)*waveS_WaT(i,2)+1+index_last:2*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last),waveS_WaT(i,1),waveS_WaT(i,2));
   coeff.cD{1,wavelevel+2-i} = reshape(C(1,2*waveS_WaT(i,1)*waveS_WaT(i,2)+1+index_last:3*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last),waveS_WaT(i,1),waveS_WaT(i,2));
   index_last = 3*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last;
end;

% %% plot wavelet-domain
% figure;
% subplot(2,2,1), imshow(coeff.cA{1,wavelevel},[]);
% subplot(2,2,2), imshow(coeff.cH{1,wavelevel},[]);
% subplot(2,2,3), imshow(coeff.cV{1,wavelevel},[]);
% subplot(2,2,4), imshow(coeff.cD{1,wavelevel},[]);
% 
% for i=wavelevel-1:-1:1
%     figure;
%     subplot(2,2,1), imshow([],[]);
%     subplot(2,2,2), imshow(coeff.cH{1,i},[]);
%     subplot(2,2,3), imshow(coeff.cV{1,i},[]);
%     subplot(2,2,4), imshow(coeff.cD{1,i},[]);
% end;

%% construct group vector
% index: corresponding waveletcoeff
% entry: index of parentcoeff
% if entry == 0 : root node
% coeff.cA isn't considered

% coeff.cA{2,wavelevel} = zeros(size(coeff.cA{1,wavelevel})); % not needed
% coeff.cH{2,wavelevel} = zeros(size(coeff.cH{1,wavelevel}));
% coeff.cV{2,wavelevel} = zeros(size(coeff.cH{1,wavelevel}));
% coeff.cD{2,wavelevel} = zeros(size(coeff.cH{1,wavelevel}));

% value could be calculated by kron(coeff.cX{1,i},B)+coeff,cX{1,i-1} with B = [1 1; 1 1]
% get matrix indices of parent level
for i=wavelevel-1:-1:1
    vec_index{i}(:,1) = [1:waveS_WaT(wavelevel-i+1,1)]';
    for j=2:waveS_WaT(wavelevel-i+1,2)
        vec_index{i}(:,j) = vec_index{i}(:,1)+(j-1)*waveS_WaT(wavelevel-i+1,1);
    end;
    coeff.cH{2,i} = kron(vec_index{i},[1 1; 1 1]);
    coeff.cV{2,i} = kron(vec_index{i},[1 1; 1 1]);
    coeff.cD{2,i} = kron(vec_index{i},[1 1; 1 1]);
end;

%% reshape to vector:
% % coeffs:
% D(1:S(1,1)*S(1,2)) = reshape(coeff.cA{1,wavelevel},1,S(1,1)*S(1,2));
% % coeff.cA{1,wavelevel} = reshape(C(1,1:S(1,1)*S(1,2)),S(1,1),S(1,2));
% index_last = S(1,1)*S(1,2);
% 
% for i=2:wavelevel+1
%    D(1+index_last:S(i,1)*S(i,2)+index_last) = reshape(coeff.cH{1,wavelevel+2-i},1,S(i,1)*S(i,2));
%    D(S(i,1)*S(i,2)+1+index_last:2*S(i,1)*S(i,2)+index_last) = reshape(coeff.cV{1,wavelevel+2-i},1,S(i,1)*S(i,2));
%    D(2*S(i,1)*S(i,2)+1+index_last:3*S(i,1)*S(i,2)+index_last) = reshape(coeff.cD{1,wavelevel+2-i},1,S(i,1)*S(i,2));
%    index_last = 3*S(i,1)*S(i,2)+index_last;
% end;

%index:
index_last = 4*waveS_WaT(1,1)*waveS_WaT(1,2);
flag_double_nongroup_entries = true;
if flag_double_nongroup_entries
    D(1:index_last) = 1:index_last;
else
    D(1:index_last) = zeros(1,index_last); % zeros for cA/cH/cV/cD{wavelevel}
end;
index_parent = 1*waveS_WaT(1,1)*waveS_WaT(1,2); % index of last non-parent node (cA)

% for i=3:wavelevel+1
%    D(1+index_last:waveS_WaT(i,1)*waveS_WaT(i,2)+index_last) = reshape(coeff.cH{2,wavelevel+2-i}+index_parent,1,waveS_WaT(i,1)*waveS_WaT(i,2));
%    D(waveS_WaT(i,1)*waveS_WaT(i,2)+1+index_last:2*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last) = reshape(coeff.cH{2,wavelevel+2-i}+index_parent+waveS_WaT(i-1,1)*waveS_WaT(i-1,2),1,waveS_WaT(i,1)*waveS_WaT(i,2));
%    D(2*waveS_WaT(i,1)*waveS_WaT(i,2)+1+index_last:3*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last) = reshape(coeff.cH{2,wavelevel+2-i}+index_parent+2*waveS_WaT(i-1,1)*waveS_WaT(i-1,2),1,waveS_WaT(i,1)*waveS_WaT(i,2));
%    index_last = 3*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last;
%    index_parent = 3*waveS_WaT(i-1,1)*waveS_WaT(i-1,2)+index_parent;
% end;

%% readjust the following to replace the one above:
for i=3:wavelevel+1 % coeff.cH{2,wavelevel+2-i}(1:S(i,1),1:S(i,2)) indices to make sure that uneven coeffs have the right #
   D(1+index_last:waveS_WaT(i,1)*waveS_WaT(i,2)+index_last) = reshape(coeff.cH{2,wavelevel+2-i}(1:waveS_WaT(i,1),1:waveS_WaT(i,2))+index_parent,1,waveS_WaT(i,1)*waveS_WaT(i,2));
   D(waveS_WaT(i,1)*waveS_WaT(i,2)+1+index_last:2*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last) = reshape(coeff.cH{2,wavelevel+2-i}(1:waveS_WaT(i,1),1:waveS_WaT(i,2))+index_parent+waveS_WaT(i-1,1)*waveS_WaT(i-1,2),1,waveS_WaT(i,1)*waveS_WaT(i,2));
   D(2*waveS_WaT(i,1)*waveS_WaT(i,2)+1+index_last:3*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last) = reshape(coeff.cH{2,wavelevel+2-i}(1:waveS_WaT(i,1),1:waveS_WaT(i,2))+index_parent+2*waveS_WaT(i-1,1)*waveS_WaT(i-1,2),1,waveS_WaT(i,1)*waveS_WaT(i,2));
   index_last = 3*waveS_WaT(i,1)*waveS_WaT(i,2)+index_last;
   index_parent = 3*waveS_WaT(i-1,1)*waveS_WaT(i-1,2)+index_parent;
end;
% G*x = z;
if flag_double_nongroup_entries
    idx_group_start = 1;
else
    idx_group_start = 4*waveS_WaT(1,1)*waveS_WaT(1,2)+1;
end;
% groups = zeros(1,2*length_coeff);
% groups(1,1:length_coeff) = C;
% groups(1,length_coeff+idx_group_start:end) = C(D(idx_group_start:end)); % z = groups; corresponding entries i & i+size(x,2)/2
G_mat = sparse(idx_group_start:length_coeff,D(idx_group_start:end),1,length_coeff,length_coeff);
Gt_mat = G_mat';


% %% test:
% E = (G_mat*C')';
% length_coeff = size(E,2);
% 
% 
% coeff.cA{3,wavelevel} = reshape(E(1,1:S(1,1)*S(1,2)),S(1,1),S(1,2));
% index_last = S(1,1)*S(1,2);
% 
% for i=2:wavelevel+1
%    coeff.cH{3,wavelevel+2-i} = reshape(E(1,1+index_last:S(i,1)*S(i,2)+index_last),S(i,1),S(i,2));
%    coeff.cV{3,wavelevel+2-i} = reshape(E(1,S(i,1)*S(i,2)+1+index_last:2*S(i,1)*S(i,2)+index_last),S(i,1),S(i,2));
%    coeff.cD{3,wavelevel+2-i} = reshape(E(1,2*S(i,1)*S(i,2)+1+index_last:3*S(i,1)*S(i,2)+index_last),S(i,1),S(i,2));
%    index_last = 3*S(i,1)*S(i,2)+index_last;
% end;
% 
% 
% figure;
% subplot(2,2,1), imshow(coeff.cA{3,wavelevel},[]);
% subplot(2,2,2), imshow(coeff.cH{3,wavelevel},[]);
% subplot(2,2,3), imshow(coeff.cV{3,wavelevel},[]);
% subplot(2,2,4), imshow(coeff.cD{3,wavelevel},[]);
% 
% for i=wavelevel-1:-1:1
%     figure;
%     subplot(2,2,1), imshow([],[]);
%     subplot(2,2,2), imshow(coeff.cH{3,i},[]);
%     subplot(2,2,3), imshow(coeff.cV{3,i},[]);
%     subplot(2,2,4), imshow(coeff.cD{3,i},[]);
% end;


%%
% % % an example:
% % % groups_test2 = zeros(1,2*length_coeff);
% % % groups_test2(1,1:length_coeff) = C;
% % % groups_test2(1,length_coeff+1:end) = (D_mat*C(1:size(D_mat,2))')';
% % % -> groups = [I*C; D_mat*C] -> G = [I; D_mat]; G' = [I D_mat']; <-
% % % 
% % % G_1 = I*C = C;
% % % G_2 = D_mat*C;
% % % Gt_1 = I'*G_thresh = G_thresh;
% % % Gt_2 = D_mat'*G_thresh;
% % % Gt = Gt_1+Gt_2;
% % 
% % % C_groups_reversed = [groups(1:idx_group_start-1) groups(idx_group_start:end)-C(D(idx_group_start:end))];
% % % 
% % % im_re = waverec2(C,S,'db1');
% % % im_re_group = waverec2(C_groups_reversed,S,'db1');

end