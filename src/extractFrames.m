function [z_frames, z_phases] = extractFrames(y, params)
% EXTRACTFRAMES  Break up a signal into a sequence of time-frequency frames
%
% Parameters
% ----------
% y : double array
%   Time-domain signal
% params : struct
%   Experiment setup parameters. See set_experiment_params.m for definition
%   of structure fields.
%
% Returns
% -------
% z_frames : double array
%   Signal frame magnitudes
% z_phases : double array
%   Signal frame phases
%

num_samples = length(y);

% Convert units of frame length, frame spacing from seconds to samples
frame_len = round(params.FRAME_LENGTH * params.SAMPLE_RATE);
frame_overlap = round(frame_len * params.OVERLAP_RATIO);
frame_spacing = frame_len - frame_overlap;

switch params.SIGNAL_BASIS
    case 'TIME'
        z_frames = buffer(y, frame_len, frame_overlap, 'nodelay');
        z_phases = zeros(size(z_frames));
    case 'FOURIER'
        % Pad signal to fit an integer number of frames (spectrogram
        % truncates by default)
        num_frames = ceil((num_samples - frame_len) / frame_spacing);
        delta = (num_frames * frame_spacing + frame_len) - num_samples + 1;
        y_padded = padarray(y, [delta, 0], 'post');
        
        % Spectrogram uses a hamming window of length frame_len by default
        s = spectrogram(y_padded, frame_len, frame_spacing, frame_len);
        z_frames = abs(s);
        z_phases = angle(s);
    case 'WAVELET'
        error('WAVELET not yet implemented')
        %{
        frame_level = wmaxlev(frame_len, params.DWT_WAVELET_TYPE);
        [zfc_1, lf] = wavedec(y_corr_frames(1,:), frame_level, params.DWT_WAVELET_TYPE);
        z_frame_len = length(zcf_1);
        
        z_corr_frames = zeros(num_frames, z_frame_len);
        z_corr_frames(1,:) = zfc_1;
        for i = 2:num_frames
            [zcf_i, ~] = wavedec(y_corr_frames(i,:), frame_level, params.DWT_WAVELET_TYPE);
            z_corr_frames(i,:) = zcf_i;
        end
        %}
    case 'COSINE'
        y_frames = buffer(y, frame_len, frame_overlap, 'nodelay');
        z_frames = dct(y_frames);   % Apply DCT to each column of y_frames
        z_phases = zeros(size(z_frames));
    case 'GABOR'
        % Gabor function defined in S. Mallat's Matching Pursuits (...)
        % (IEEE Trans. Signal Processing, 1993) eq. 59
        alpha = pi; %(sqrt(pi) / 2) * (frame_len - 1);
        window = 2^0.25 * gausswin(frame_len, alpha);
        
        num_frames = ceil((num_samples - frame_len) / frame_spacing);
        delta = (num_frames * frame_spacing + frame_len) - num_samples;
        y_padded = padarray(y, [delta, 0], 'post');
        s = spectrogram(y_padded, window, frame_spacing, frame_len);
        z_frames = abs(s);
        z_phases = angle(s);
    otherwise
        error('Invalid option: SIGNAL_BASIS = %s', params.SIGNAL_BASIS)
end

end

