%
% experiment_framework.m
%   Unified experimental framework for 520.648 final project
%
% HISTORY
% =======
% 2017-05-02 : Created by Jonathan D. Jones
%

clear variables;

% Load experiment parameters as a struct named `params`
experiment_params;

% Seed random number generator for consistent behavior
if params.RAND_SEED > -1
    rng(params.RAND_SEED)
end

%% Define OS-independent path structure
%
% DIRECTORY STRUCTURE
% ===================
% (project root)
%   |---> src
%   | *---> recon
%   |---> data
%   | |---> clean
%   | *---> noise
%   |   *---> [noise class subdirectories]
%   |---> working
%   *---> output
%     |---> figures
%     *---> audio
%
src_path = pwd;
src_path_parts = strsplit(src_path, filesep);
root_path_parts = src_path_parts(1:end-1);
fmt_str = ['%s', filesep];
root_path = sprintf(fmt_str, root_path_parts{:});
data_path = fullfile(root_path, 'data');
clean_path = fullfile(data_path, 'clean');
noise_path = fullfile(data_path, 'noise');
working_path = fullfile(root_path, 'working', params.EXPT_ID);
output_path = fullfile(root_path, 'output', params.EXPT_ID);
fig_path = fullfile(output_path, 'figures');
audio_path = fullfile(output_path, 'audio');

% Delete working/fig directories if the exist and create new ones
if ~exist(working_path, 'dir')
    mkdir(working_path);
end
if exist(output_path, 'dir')
    rmdir(output_path, 's');
end
mkdir(fig_path);
mkdir(audio_path);

% Record experiment output and parameters in fig folder
log_fn = 'experiment.log';
diary(fullfile(output_path, log_fn))
copyfile('experiment_params.m', output_path);

% Define path to the desired noise class
if strcmp(params.NOISE_CLASS, 'random')
    % List all (and only) subdirectories of noise_path
    dir_data = dir(noise_path);
    is_dir = [dir_data(:).isdir];
    subdir_names = {d(is_dir).name}';
    subdir_names(ismember(subdir_names, {'.','..'})) = [];
    
    % Choose a subdirectory at random
    noise_class = datasample(subdir_names, 1);
    noise_class = noise_class{1};
    noise_class_path = fullfile(noise_path, noise_class);
else
    noise_class_path = fullfile(noise_path, params.NOISE_CLASS);
end

% Add external libraries
addpath(fullfile(src_path, 'recon'))
addpath(fullfile(src_path, 'ksvdbox13'))
addpath(fullfile(src_path, 'ompbox10'))

fprintf('EXPERIMENT: %s\n', params.EXPT_ID)
fprintf('\n-=:(*)::===----\n')


%% Define train/test splits

total_num_files_clean = params.NUM_TEST + params.NUM_TRAIN_CLEAN;
total_num_files_noise = 1 + params.NUM_TRAIN_NOISE;
clean_fns = chooseRandom(total_num_files_clean, clean_path, 'wav');
noise_fns = chooseRandom(total_num_files_noise, noise_class_path, 'wav');

clean_test_fns  = clean_fns(1:params.NUM_TEST);
clean_train_fns = clean_fns(params.NUM_TEST+1:end);
noise_train_fns = noise_fns(2:end);

fprintf('\nCLEAN FILES:\n')
for i = 1:length(clean_test_fns)
    fprintf('  TEST  | %s\n', clean_test_fns{i})
end
for i = 1:length(clean_train_fns)
    fprintf('  TRAIN | %s\n', clean_train_fns{i})
end
fprintf('\nNOISE FILES:\n')
fprintf('  TEST  | %s\n', noise_fns{1})
for i = 1:length(noise_train_fns)
    fprintf('  TRAIN | %s\n', noise_train_fns{i})
end

fprintf('\n-=:(*)::===----\n')


%% Run experiments

num_runs = length(params.SWEEP_VALS);
avg_snrs = zeros(num_runs, 1);
avg_psnrs_recovered = zeros(num_runs, 1);
avg_psnrs_corrupted = zeros(num_runs, 1);
for j = 1:num_runs
    
    % Set sweep value using dynamic field name
    sweep_val = params.SWEEP_VALS(j);
    params.(params.SWEEP_VAR) = sweep_val;
    setting_str = sprintf('%s=%.2f', params.SWEEP_VAR, sweep_val);
    
    fmt_str = '\nITERATION %d of %d: %s = %.2f\n';
    fprintf(fmt_str, j, num_runs, params.SWEEP_VAR, sweep_val)
    
    audio_subdir = fullfile(audio_path, setting_str);
    fig_subdir = fullfile(fig_path, setting_str);
    mkdir(audio_subdir);
    mkdir(fig_subdir);
    
    %% Construct clean and noise dictionaries
    clean_train_fullfile = fullfile(clean_path, clean_train_fns);
    noise_train_fullfile = fullfile(noise_class_path, noise_train_fns);
    [D_clean, D_noise] = constructDictionary(clean_train_fullfile, ...
                                             noise_train_fullfile, params);

    if params.SAVE_FIGURES
        figure('Visible', 'off');
        subplot(2,1,1)
        plot(D_clean(:))
        title 'Clean dictionary'
        ylabel 'a^c_i[n]'
        subplot(2,1,2)
        plot(D_noise(:))
        title 'Noise dictionary'
        ylabel 'a^n_i[n]'
        xlabel 'Sample index (n)'

        fmt_str = 'dict-plots.png';
        fig_fn = sprintf(fmt_str, params.SWEEP_VAR, sweep_val);
        print(fullfile(fig_subdir, fig_fn), '-dpng')
    end

    save(fullfile(working_path, sprintf('dicts_%s', setting_str)), 'D_clean', 'D_noise')
    audiowrite(fullfile(audio_subdir, 'dict-clean.wav'), D_clean(:), params.SAMPLE_RATE)
    if any(D_noise)
        audiowrite(fullfile(audio_subdir, 'dict-noise.wav'), D_noise(:), params.SAMPLE_RATE)
    end
    
    fprintf('\n-=:(*)::===----\n')

    %% Denoise test files
    msg_str = '\nDENOISING %d FILES\n';
    fprintf(msg_str, params.NUM_TEST);
    
    snrs = zeros(params.NUM_TEST, 1);
    corrupted_psnrs = zeros(params.NUM_TEST, 1);
    recovered_psnrs = zeros(params.NUM_TEST, 1);
    for i = 1:params.NUM_TEST
        clean_fn = clean_test_fns{i};
        clean_file_path = fullfile(clean_path, clean_test_fns{i});
        y_clean = preprocess(clean_file_path, params);
        
        noise_fn = noise_fns{1};
        noise_file_path = fullfile(noise_class_path, noise_fns{1});
        y_noise = preprocess(noise_file_path, params);
        
        [y_corrupted, y_clean, y_noise] = corrupt(y_clean, y_noise, params);
        
        y_recovered = denoise(y_corrupted, y_noise, D_clean, D_noise, params);
        
        y_psnr = psnr(y_clean, y_recovered);
        
        snrs(i) = snr(y_clean, y_corrupted - y_clean);
        corrupted_psnrs(i) = psnr(y_clean, y_corrupted);
        recovered_psnrs(i) = psnr(y_clean, y_recovered);
        
        % Write corrupted & recovered files to .wav format
        [~, name, ext] = fileparts(clean_file_path);
        corrupted_fn = sprintf('%s_CORRUPTED%s', name, ext);
        recovered_fn = sprintf('%s_RECOVERED%s', name, ext);
        corrupted_file_path = fullfile(audio_subdir, corrupted_fn);
        recovered_file_path = fullfile(audio_subdir, recovered_fn);
        audiowrite(corrupted_file_path, y_corrupted, params.SAMPLE_RATE);
        audiowrite(recovered_file_path, y_recovered, params.SAMPLE_RATE);
        
        if mod(i, params.CONSOLE_UPDATE_INTERVAL) == 0
            delta_psnr = recovered_psnrs(i) - corrupted_psnrs(i);
            msg_str = 'Denoised %s | PSNR: %.2f dB | DELTA PSNR: %.2f dB\n';
            fprintf(msg_str, clean_fn, recovered_psnrs(i), delta_psnr)
        end
        
        % Write figures to .png format
        if params.SAVE_FIGURES
            Y = horzcat(y_clean, y_noise, y_corrupted, y_recovered);
            fig_fn = fullfile(fig_subdir, name);
            makeSignalFigure(Y, fig_fn, params);
        end
    end
    
    snr_mean = mean(snrs);
    psnr_mean_recovered = mean(recovered_psnrs);
    psnr_mean_corrupted = mean(corrupted_psnrs);
    psnr_mean_delta = psnr_mean_recovered - psnr_mean_corrupted;
    
    fprintf('\nMean SNR : %.2f dB\n', snr_mean)
    fprintf('\nMean PSNR: %.2f dB\n', psnr_mean_recovered)
    fprintf('\nMean PSNR improvement: %.2f dB\n', psnr_mean_delta)
    avg_snrs(j) = snr_mean;
    avg_psnrs_recovered(j) = psnr_mean_recovered;
    avg_psnrs_corrupted(j) = psnr_mean_corrupted;
    
    fprintf('\n-=:(*)::===----\n')
end

save(fullfile(output_path, 'results'), 'avg_psnrs_recovered', ...
     'avg_psnrs_corrupted', 'clean_test_fns', 'clean_train_fns', 'noise_fns')

if params.SAVE_FIGURES && num_runs > 1
    % Plot SNR
    figure('Visible', 'off');
    plot(params.SWEEP_VALS, avg_snrs)
    axis([min(params.SWEEP_VALS), max(params.SWEEP_VALS), ...
          min(avg_snrs), max(avg_snrs)])
    title('Reconstruction quality')
    xlabel(params.SWEEP_VAR, 'Interpreter', 'none')
    ylabel('SNR (recovered)')
    fig_fn = fullfile(fig_path, sprintf('%s-vs-snr.png', params.SWEEP_VAR));
    print(fig_fn, '-dpng')
    close
    
    % Plot recovered PSNR
    figure('Visible', 'off');
    plot(params.SWEEP_VALS, avg_psnrs_recovered)
    axis([min(params.SWEEP_VALS), max(params.SWEEP_VALS), ...
          min(avg_psnrs_recovered), max(avg_psnrs_recovered)])
    title('Reconstruction quality')
    xlabel(params.SWEEP_VAR, 'Interpreter', 'none')
    ylabel('PSNR (recovered)')
    fig_fn = fullfile(fig_path, sprintf('%s-vs-psnr.png', params.SWEEP_VAR));
    print(fig_fn, '-dpng')
    close
    
    % Plot PSNR improvement
    deltas = avg_psnrs_recovered - avg_psnrs_corrupted;
    figure('Visible', 'off');
    plot(params.SWEEP_VALS, deltas)
    axis([min(params.SWEEP_VALS), max(params.SWEEP_VALS), ...
          min(deltas), max(deltas)])
    title('Improvement in reconstruction quality')
    xlabel(params.SWEEP_VAR, 'Interpreter', 'none')
    ylabel('\DeltaPSNR')
    fig_fn = fullfile(fig_path, sprintf('%s-vs-psnr-diff.png', params.SWEEP_VAR));
    print(fig_fn, '-dpng')
    close
end

fprintf('\n')

diary off

