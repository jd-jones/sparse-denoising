function x = istft(stft, params)

% function: [x, t] = istft(stft, wlen, hop, nfft, fs)
% stft - STFT matrix (only unique points, time across columns, freq across rows)
% wlen - length of the sinthesis Hamming window
% hop - hop size
% nfft - number of FFT points
% fs - sampling frequency, Hz
% x - signal in the time domain
% t - time vector, s

wlen = params.FRAME_LENGTH;
hop = wlen * (1 - params.OVERLAP_RATIO);
%nfft = params.STFT_N_FFT;
%fs = params.SAMPLE_RATE;

% signal length estimation and preallocation
coln = size(stft, 2);
xlen = wlen + (coln-1)*hop;
x = zeros(1, xlen);

% form a periodic hamming window
win = hamming(wlen, 'periodic');

% initialize the signal time segment index
indx = 0;

% perform ISTFT (via IFFT and Weighted-OLA)
if ~rem(wlen, 2)                     % even nfft includes Nyquist point
    for col = 1:coln
        % extract FFT points
        X = stft(:, col);
        X = [X; conj(X(end-1:-1:2))];
        
        % IFFT
        xprim = real(ifft(X));
        xprim = xprim(1:wlen);
        
        % weighted-OLA
        x((indx+1):(indx+wlen)) = x((indx+1):(indx+wlen)) + (xprim.*win)';
        
        % update the index
        indx = indx + hop;
    end
else
    for col = 1:coln
        % extract FFT points
        X = stft(:, col);
        X = [X; conj(X(end:-1:2))];
        
        % IFFT
        xprim = real(ifft(X));
        xprim = xprim(1:wlen);
        
        % weighted-OLA
        x((indx+1):(indx+wlen)) = x((indx+1):(indx+wlen)) + (xprim.*win)';
        
        % update the index
        indx = indx + hop;
    end

% scale the signal
W0 = sum(win.^2);                  
x = x.*hop/(W0);   

% generate time vector
%t = (0:xlen-1)/fs;  