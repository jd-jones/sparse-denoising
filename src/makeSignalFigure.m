function makeSignalFigure(Y, fig_fn, params)
% MAKESIGNALFIGURE  Plot & save a figure summarizing recovery results 
%

[y_len, num_signals] = size(Y);
if num_signals ~= 4
    error('Error: Y must have exactly four columns')
end

t = (1:y_len) / params.SAMPLE_RATE;

y_clean = Y(:,1);
y_noise = Y(:,2);
y_corrupted = Y(:,3);
y_recovered = Y(:,4);

Y_clean = abs(fft(y_clean));
Y_noise = abs(fft(y_noise));
Y_corrupted = abs(fft(y_corrupted));
Y_recovered = abs(fft(y_recovered));

fft_len = round(y_len / 2);
f = params.SAMPLE_RATE * (0:fft_len-1) / y_len;

Y_clean = Y_clean(1:fft_len);
Y_noise = Y_noise(1:fft_len);
Y_corrupted = Y_corrupted(1:fft_len);
Y_recovered = Y_recovered(1:fft_len);

% Plot transformed signal
figure('Visible', 'off');
subplot(4,1,1);
plot(t, y_clean);
title 'Clean Signal'
ylabel 'y(t)'
subplot(4,1,2);
plot(t, y_noise);
title 'Noise Signal'
ylabel 'y(t)'
subplot(4,1,3);
plot(t, y_corrupted);
title 'Corrupted Signal'
ylabel 'y(t)'
subplot(4,1,4);
plot(t, y_recovered);
title 'Recovered Signal'
ylabel 'y(t)'
xlabel 'time (seconds)'

print([fig_fn '_time.png'], '-dpng')

% Plot transformed signal
figure('Visible', 'off');
subplot(4,1,1);
plot(f, mag2db(Y_clean));
title 'Clean Signal'
ylabel '|Y(f)| (dB)'
subplot(4,1,2);
plot(f, mag2db(Y_noise));
title 'Noise Signal'
ylabel '|Y(f)| (dB)'
subplot(4,1,3);
plot(f, mag2db(Y_corrupted));
title 'Corrupted Signal'
ylabel '|Y(f)| (dB)'
subplot(4,1,4);
plot(f, mag2db(Y_recovered));
title 'Recovered Signal'
ylabel '|Y(f)| (dB)'
xlabel 'frequency (Hz)'

print([fig_fn '_freq.png'], '-dpng')
end

