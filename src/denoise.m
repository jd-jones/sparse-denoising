function y_recovered = denoise(y_corrupted, y_noise, D_clean, D_noise, params)
% RUN_EXPERIMENT  Run an experiment with setup defined by params
%
% PARAMETERS
% ----------
% y_corrupted : double array
%   Corrupted signal
% y_noise : double array
%   Noise signal (only used for spectral subtraction)
% D_clean : double array
%   Dictionary of basis functions which span the space of clean signals
% D_noise : double array
%   Dictionary of basis functions which span the space of noise signals
% params : struct
%   Experiment setup parameters. See set_experiment_params.m for definition
%   of structure fields.
%
% RETURNS
% -------
% y_recovered : double array
%   Recovered clean signal estimate
%
% HISTORY
% =======
% 2017-04-17 : Created by Jonathan D. Jones
% 2017-04-25 : STFT added by Valerie Rennoll
% 2017-05-02 : Refactored into function (JDJ)
%


%% Extract zero-mean time-frequency frames from corrupted signal

[z_corr_frames, z_corr_phase] = extractFrames(y_corrupted, params);
[z_frame_len, num_frames] = size(z_corr_frames);

% Subtract mean
z_frame_means = mean(z_corr_frames, 1);
z_corr_frames = z_corr_frames - z_frame_means;
    

%% Recover sparse dictionary basis coefficients

% Form full dictionary by concatenating clean & noise dictionaries
[~, num_clean_atoms] = size(D_clean);
[~, num_noise_atoms] = size(D_noise);
D = horzcat(D_clean, D_noise);
[~, num_atoms] = size(D);

sparsity_level = round(params.SPARSITY_RATIO * num_atoms);

frame_coeffs = zeros(num_atoms, num_frames);
switch params.RECOVERY_METHOD
    case 'FISTA'
        for i = 1:num_frames
            [fc_i, num_iters] = FISTA(D, z_corr_frames(:,i));
            frame_coeffs(:,i) = fc_i;
        end
    case 'SP'
        for i = 1:num_frames
            fc_i = SP(z_measured, D, z_corr_frames(:,i));
            frame_coeffs(:,i) = fc_i;
        end
    case 'OMP'
        for i = 1:num_frames
            fc_i = OMP(z_corr_frames(:,i), D, sparsity_level);
            frame_coeffs(:,i) = fc_i;
        end
    case 'omp'
        frame_coeffs = omp(D' * z_corr_frames, D'*D, sparsity_level);
    case 'ALM'
        for i = 1:num_frames
            [fc_i, num_iters] = ALM(D, z_corr_frames(:,i));
            frame_coeffs(:,i) = fc_i;
        end
    case 'SUBTRACTION'
        [z_noise_frames, ~] = extractFrames(y_noise, params);
        z_rcvr_frames = z_corr_frames - z_noise_frames;
        z_rcvr_frames = max(z_rcvr_frames, 0);
    otherwise
        error('Invalid option: RECOVERY_METHOD = %s', params.RECOVERY_METHOD)
end


%% Reconstruct denoised signal

if ~strcmp(params.RECOVERY_METHOD, 'SUBTRACTION')
    z_rcvr_frames = zeros(z_frame_len, num_frames);
    for i = 1:num_frames
        clean_coeffs = frame_coeffs(1:num_clean_atoms,i);
        z_rcvr_frames(:,i) = D_clean * clean_coeffs;
    end
end

z_rcvr_frames = z_rcvr_frames + z_frame_means;
y_recovered = constructSignal(z_rcvr_frames, z_corr_phase, params);
y_recovered = y_recovered(1:length(y_corrupted));

% Filter and normalize so that peak amplitude = 1
y_recovered = y_recovered / max(abs(y_recovered));

end

