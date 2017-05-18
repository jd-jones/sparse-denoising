function y = preprocess(audio_fn, params)
% PREPROCESS  Open an audio file & downsample to a pre-specified rate
%
% Parameters
% ----------
% audio_fn : str
%   FULL PATH to audio file
% params : struct
%   Experiment setup parameters. See set_experiment_params.m for definition
%   of structure fields.
%
% Returns
% -------
% y : double array
%   Audio signal resampled to sample rate specified in params
%

[y, Fs] = audioread(audio_fn);
% If there are multiple channels, collapse them into one by averaging
[~, num_channels] = size(y);
if num_channels > 1
    y = mean(y, 2);
end

y = resample(y, params.SAMPLE_RATE, Fs);

% Normalize to that peak amplitude = 1
y = y / max(abs(y));

end

