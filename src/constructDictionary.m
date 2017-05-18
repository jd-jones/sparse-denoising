function [D_clean, D_noise] = constructDictionary(clean_fns, noise_fns, params)
% CONSTRUCTDICTIONARY  Construct a dictionary of basis functions
%
% Parameters
% ----------
% clean_fns : cell str
%   Training set of clean files. Each element in cell is the FULL PATH to
%   the file.
% noise_fns : cell str
%   Training set of noise files. Each element in cell is the FULL PATH to
%   the file.
% params : struct
%   Experiment setup parameters. See set_experiment_params.m for definition
%   of structure fields.
%
% Returns
% -------
% D_clean : double array
%   Dictionary of basis functions which span the space of clean signals
% D_noise : double array
%   Dictionary of basis functions which span the space of noise signals
%

% Read clean files
z_clean_frames = [];
for i = 1:length(clean_fns)
    y_clean_i  = preprocess(clean_fns{i}, params);
    z_frames_i = extractFrames(y_clean_i, params);
    z_clean_frames = horzcat(z_clean_frames, z_frames_i);
end

% Read noise files
z_noise_frames = [];
for i = 1:length(noise_fns)
    y_noise_i  = preprocess(noise_fns{i}, params);
    z_frames_i = extractFrames(y_noise_i, params);
    z_noise_frames = horzcat(z_noise_frames, z_frames_i);
end

[z_frame_len, num_clean_frames] = size(z_clean_frames);
[z_frame_len, num_noise_frames] = size(z_noise_frames);

num_atoms = round(z_frame_len / params.MEASUREMENT_RATIO);
sparsity_level = round(params.SPARSITY_RATIO * num_atoms);

fprintf('\n')
fprintf('CONSTRUCTING CLEAN DICTIONARY: %s\n', params.CLEAN_DICTIONARY)
switch params.CLEAN_DICTIONARY
    case 'KSVD'
        if num_clean_frames < num_atoms
            err_str = 'Only %d samples to train dictionary with %d entries';
            error(err_str, num_clean_frames, num_atoms)
        end
        ksvdparams.data = z_clean_frames;
        ksvdparams.Tdata = sparsity_level;
        ksvdparams.dictsize = num_atoms;
        [D_clean, Gamma, err, gerr] = ksvd(ksvdparams, 'rt');
    case 'KSVD_NN'
        if strcmp(params.SIGNAL_BASIS, 'TIME') || strcmp(params.SIGNAL_BASIS, 'DCT')
            error('Negative elements possible in %s basis', params.SIGNAL_BASIS)
        end
        nnksvdparams.K = num_atoms;
        nnksvdparams.L = sparsity_level;
        nnksvdparams.numIteration = params.KSVD_MAX_ITERS;
        nnksvdparams.InitializationMethod = 'DataElements';
        nnksvdparams.displayProgress = 1;
        nnksvdparams.errorFlag = 0;
        nnksvdparams.preserveDCAtom = 0;
        [D_clean, output] = KSVD_NN(z_clean_frames, nnksvdparams);
    case 'NMF'
        if params.MEASUREMENT_RATIO < 1
            error('Measurement ratio >= 1 for NMF')
        end
        if strcmp(params.SIGNAL_BASIS, 'TIME') || strcmp(params.SIGNAL_BASIS, 'DCT')
            error('Negative elements possible in %s basis', params.SIGNAL_BASIS)
        end
        options = statset('Display', 'final');
        [D_clean, ~] = nnmf(z_clean_frames, num_atoms, ...
                            'algorithm', 'mult', 'options', options, ...
                            'replicates', params.KSVD_MAX_ITERS);
        D_clean = normc(D_clean);
    case 'TIME'
        Phi_clean = eye(num_atoms);
    case 'DCT'
        Phi_clean = dct(eye(num_atoms));
    otherwise
        error('Invalid option: CLEAN_DICTIONARY = %s', params.CLEAN_DICTIONARY)
end

fprintf('\n')
fprintf('CONSTRUCTING NOISE DICTIONARY: %s\n', params.NOISE_DICTIONARY)
switch params.NOISE_DICTIONARY
    case 'KSVD'
        if num_noise_frames < num_atoms
            err_str = 'Only %d samples to train dictionary with %d entries';
            error(err_str, num_noise_frames, num_atoms)
        end
        ksvdparams.data = z_noise_frames;
        ksvdparams.Tdata = sparsity_level;
        ksvdparams.dictsize = num_atoms;
        [D_noise, Gamma, err, gerr] = ksvd(ksvdparams, 'rt');
    case 'KSVD_NN'
        if strcmp(params.SIGNAL_BASIS, 'TIME') || strcmp(params.SIGNAL_BASIS, 'DCT')
            error('Negative elements possible in %s basis', params.SIGNAL_BASIS)
        end
        nnksvdparams.K = num_atoms;
        nnksvdparams.L = sparsity_level;
        nnksvdparams.numIteration = params.KSVD_MAX_ITERS;
        nnksvdparams.InitializationMethod = 'DataElements';
        nnksvdparams.displayProgress = 1;
        nnksvdparams.errorFlag = 0;
        nnksvdparams.preserveDCAtom = 0;
        [D_noise, output] = KSVD_NN(z_noise_frames, nnksvdparams);
        %D_noise = normc(D_noise);
    case 'NMF'
        if params.MEASUREMENT_RATIO < 1
            error('Measurement ratio >= 1 for NMF')
        end
        if strcmp(params.SIGNAL_BASIS, 'TIME') || strcmp(params.SIGNAL_BASIS, 'DCT')
            error('Negative elements possible in %s basis', params.SIGNAL_BASIS)
        end
        options = statset('Display', 'final');
        [D_noise, ~] = nnmf(z_noise_frames, num_atoms, ...
                            'algorithm', 'mult', 'options', options, ...
                            'replicates', params.KSVD_MAX_ITERS);
        D_noise = normc(D_noise);
    case 'TIME'
        Phi_noise = eye(num_atoms);
    case 'DCT'
        Phi_noise = dct(eye(num_atoms));
    case 'NONE'
        D_noise = [];
    otherwise
        error('Invalid option: NOISE_DICTIONARY = %s', params.NOISE_DICTIONARY)
end

switch params.MEASUREMENT_MATRIX
    case 'IDENTITY'
        I = eye(num_atoms);
        sampled_rows = randi(num_atoms, z_frame_len, 1);
        Psi = I(sampled_rows,:);
    case 'GAUSSIAN'
        Psi = randn(z_frame_len, num_atoms);
        matrixNorm = Psi.' * Psi;
        matrixNorm = sqrt(diag(matrixNorm)).';
        Psi = Psi ./ repmat(matrixNorm, [z_frame_len,1]);
    case 'SRM'  % Structurally random matrix
        B = num_atoms / params.NUM_SRM_BLOCKS;
        I = eye(B);
        D = diag(2 * randi(2, B, 1) - 3);
        F = hadamard(B);
        sampled_rows = datasample(1:B, z_frame_len / params.NUM_SRM_BLOCKS, 'Replace', false);
        R = I(sampled_rows,:);
        Psi = kron(eye(num_blocks), R * F * D);
    otherwise
        error('Invalid option: CLEAN_MEASUREMENT = %s', params.MEASUREMENT_MATRIX)
end

% This control flow is a hack to make KSVD and NMF ignore the measurement
% matrix
if ~(strcmp(params.CLEAN_DICTIONARY, 'KSVD') ...
  || strcmp(params.CLEAN_DICTIONARY, 'KSVD_NN') ...
  || strcmp(params.CLEAN_DICTIONARY, 'NMF'))
    D_clean = Psi * Phi_clean;
    D_clean = normc(D_clean);
end
if ~(strcmp(params.NOISE_DICTIONARY, 'KSVD') ...
  || strcmp(params.NOISE_DICTIONARY, 'KSVD_NN') ...
  || strcmp(params.NOISE_DICTIONARY, 'NMF') ...
  || strcmp(params.NOISE_DICTIONARY, 'NONE'))
    D_noise = Psi * Phi_noise;
    D_noise = normc(D_noise);
end

end

