function [y_corrupted, y_clean, y_noise] = corrupt(y_clean, y_noise, params)
% CORRUPT  Create a corrupted signal with SNR specified in config settings
%
% Suppose we have a signal x(t) corrupted by additive noise n(t). The power
% (square l2-norm) and SNR are defined as
%   y(t) = x(t) + n(t)
%   P_x   := || x(t) ||^2                   % Power of signal
%   P_n   := || n(t) ||^2                   % Power of noise
%   SNR_y := 10 * log_10 ( P_x / P_n )      % SNR (in dB)
%
% If we scale the noise by a constant c, we have
%   y'(t)  = x(t) + c * n(t)
%   SNR_y' = SNR_n - 20 * log_10 c
%
% Thus if we want a particular SNR for the experiment, we can just scale
% the noise by constant
%   c = 10 ^ (0.05 * (SNR_n - SNR_m))
%
% Parameters
% ----------
% y_clean : double array
%   Clean signal
% y_noise : double array
%   Noise signal
% params : struct
%   Experiment setup parameters. See set_experiment_params.m for definition
%   of structure fields.
%
% Returns
% -------
% y_corrupted : double array
%   Corrupted signal
%


% Cut signals to the same length
[num_samples_clean, num_channels_clean] = size(y_clean);
[num_samples_noise, num_channels_noise] = size(y_noise);
assert(num_channels_clean == 1, 'Signal has >1 channel');
assert(num_channels_noise == 1, 'Noise has >1 channel');
if num_samples_noise < num_samples_clean
    num_samples = num_samples_noise;
    y_clean = y_clean(1:num_samples);
else
    num_samples = num_samples_clean;
    y_noise = y_noise(1:num_samples);
end

% Create corrupted signal
init_snr = 10 * log10(norm(y_clean)^2 / norm(y_noise)^2);
noise_amplitude = 10 ^ (0.05 * (init_snr - params.EXPT_SNR));
y_corrupted = y_clean + noise_amplitude * y_noise;

% Normalize so that peak amplitude = 1
y_corrupted = y_corrupted / max(abs(y_corrupted));

end

