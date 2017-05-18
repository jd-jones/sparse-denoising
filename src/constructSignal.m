function y = constructSignal(z_frames, z_phases, params)
% CONSTRUCTSIGNAL  Construct a signal from a sequence of time-frequency frames
%
% Parameters
% ----------
% z_frames : double array
%   Signal frame magnitudes
% z_phases : double array
%   Signal frame phases
% params : struct
%   Experiment setup parameters. See set_experiment_params.m for definition
%   of structure fields.
%
% Returns
% -------
% y : double array
%   Time-domain signal synthesized from frames
%

[~, num_frames] = size(z_frames);

% Re-incorporate phase into signal frames
z_frames = z_frames .* exp(1i * z_phases);

% Convert units of frame length, frame spacing from seconds to samples
frame_len = round(params.FRAME_LENGTH * params.SAMPLE_RATE);
frame_overlap = round(frame_len * params.OVERLAP_RATIO);
frame_spacing = frame_len - frame_overlap;

% Convert frames back to time domain
switch params.SIGNAL_BASIS
    case 'TIME'
        y_frames = z_frames;
        y_window = ones(frame_len, 1);
    case 'FOURIER'
        if rem(frame_len, 2)    % num fft samples was odd
            z_conj_frames = conj(z_frames(end:-1:2,:));
        else    % num fft samples was even
            z_conj_frames = conj(z_frames(end-1:-1:2,:));
        end
        z_frames = vertcat(z_frames, z_conj_frames);
        
        % Apply iFFT to each column of z_frames, treating the signal as
        % symmetric
        y_frames = ifft(z_frames, 'symmetric');
        y_window = hamming(frame_len);  % MATLAB's default spectrogram window
    case 'WAVELET'
        error('WAVELET not yet implemented')
        %{
        y_rcvr_frames = zeros(num_frames, y_frame_len);
        for i = 1:num_frames
            yrf_i = waverec(z_rcvr_frames(i,:), lf, params.WAVELET_TYPE);
            y_rcvr_frames(i,:) = yrf_i;
        end
        %}
    case 'COSINE'
        y_frames = idct(z_frames);      % Apply iDCT to each column of z_frames
        y_window = ones(frame_len, 1);
    case 'GABOR'
        if rem(frame_len, 2)    % num fft samples was odd
            z_conj_frames = conj(z_frames(end:-1:2,:));
        else    % num fft samples was even
            z_conj_frames = conj(z_frames(end-1:-1:2,:));
        end
        z_frames = vertcat(z_frames, z_conj_frames);
        
        % Apply iFFT to each column of z_frames, treating the signal as
        % symmetric
        y_frames = ifft(z_frames, 'symmetric');
        % Gabor function defined in S. Mallat's "Matching Pursuits..."
        % (IEEE Trans. Signal Processing, 1993) [eq. 59]
        alpha = pi; %(sqrt(pi) / 2) * (frame_len - 1);
        y_window = 2^0.25 * gausswin(frame_len, alpha);
    otherwise
        error('Invalid option: SIGNAL_BASIS = %s', params.SIGNAL_BASIS)
end

% Initialize signal as all zeros
y_len = num_frames * frame_spacing + frame_len;
y = zeros(y_len, 1);

% Overlap-and-add resynthesis
frame_start = 1;
frame_end   = frame_start + frame_len - 1;
for i = 1:num_frames
    y_segment = y_frames(:,i) ./ y_window;
    
    y(frame_start:frame_end) = y(frame_start:frame_end) + y_segment;
    
    frame_start = frame_start + frame_spacing;
    frame_end   = frame_start + frame_len - 1;
end

% NOTE: y is only reconstructed up to a constant scaling factor
win_power = y_window' * y_window;
y = y * frame_spacing / win_power;

end

