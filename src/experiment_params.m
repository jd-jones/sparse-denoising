%
% experiment_settings.m
% This configuration file defines the parameters of an experiment setup.
%
% CHANGES
% =======
% 2017-04-18 : Created by Jonathan D. Jones
% 2017-04-25 : STFT added by Valerie Rennoll
%

params = struct;

params.EXPT_ID = 'sweep-snr_white-noise_best-params';

% Perform one experiment for each value of the parameter specified below
% 
params.SWEEP_VAR = 'EXPT_SNR';
params.SWEEP_VALS = -10:10;

% Seed random number generator for consistent behavior.
% (If RAND_SEED < 0, the RNG is not explicitly seeded.)
params.RAND_SEED = 1;

%% DATA & PREPROCESSING PARAMETERS

% Type of noise file to use when creating corrupted signal. One of:
%   * 'africa-kenya'            ( 12 files)
%   * 'africa-zaire'            (  6 files)
%   * 'ambulances'              ( 14 files)
%   * 'babble'                  (  6 files)
%   * 'babies-boys'             ( 36 files)
%   * 'babies-girls'            ( 16 files)
%   * 'blue'                    ( 20 files)
%   * 'bolivia'                 (  6 files)
%   * 'brown'                   ( 20 files)
%   * 'childrens-ward'          (  6 files)
%   * 'city-skyline'            (  6 files)
%   * 'factory'                 (  6 files)
%   * 'foyers'                  ( 12 files)
%   * 'hfchannel'               (  6 files)
%   * 'hospital-corridors'      ( 13 files)
%   * 'hospital-icu'            ( 16 files)
%   * 'hospital-mens-ward'      (  7 files)
%   * 'hospital-operating'      ( 12 files)
%   * 'hospital-outpatient'     (  6 files)
%   * 'hopsital-pharmacy'       ( 11 files)
%   * 'hospital-womens'         (  6 files)
%   * 'laboratories'            (  6 files)
%   * 'maternity-ward'          (  6 files)
%   * 'pathological-lab'        (  5 files)
%   * 'pink'                    (  6 files)
%   * 'pulse-monitors'          ( 12 files)
%   * 'streets'                 (  6 files)
%   * 'violet'                  ( 20 files)
%   * 'volvo'                   (  6 files)
%   * 'white'                   (  6 files)
%   * 'random'                  (Randomly select a noise class)
params.NOISE_CLASS = 'white';

% Size of training and test sets
% NOTE: (NUM_TRAIN_NOISE + 1) <= (number of files in noise class)
% NOTE: There are 16 training files
params.NUM_TEST = 8;
params.NUM_TRAIN_CLEAN = 5;
params.NUM_TRAIN_NOISE = 5;

% Downsample all signals to this rate (in Hz)
params.SAMPLE_RATE = 8e3;

% Signal-to-noise ratio of corrupted signal (in dB)
params.EXPT_SNR = 0;


%% SIGNAL BASIS & WINDOWING PARAMETERS

% Signal windowing parameters
% (Audio signals are believed to be stationary over 20~40ms)
params.FRAME_LENGTH  = 20e-3;    % (seconds)
params.OVERLAP_RATIO = 0.9;

% 'Sparsifying' signal transformation. One of:
%   * 'TIME'    (Leave signals in time domain)
%   * 'FOURIER' (short-time Fourier transform)
%   * 'WAVELET' (discrete wavelet transform)
%   * 'COSINE'  (discrete cosine transform)
%   * 'GABOR'   (Gabor transform)
params.SIGNAL_BASIS = 'TIME';
% (DWT parameters)
params.DWT_WAVELET_TYPE = 'db1';
params.DWT_LEVEL = -1;      % if < 0, use max level (determined by wmaxlev)


%% DICTIONARY PARAMETERS

% Dictionary of basis functions. One of:
%  * 'KSVD'     (Learned via K-singular value decomposition)
%  * 'KSVD_NN'  (Learned via nonnegative KSVD)
%  * 'NMF'      (Learned via nonnegative matrix factorization)
%  * 'TIME'     (Orthonormal basis in the time domain)
%  * 'DCT'      (Orthonormal basis in the [real] frequency domain)
%  * 'NONE'     (No dictionary, available for noise only)
params.CLEAN_DICTIONARY = 'KSVD';
params.NOISE_DICTIONARY = 'KSVD';

% Observed signal size over [clean] dictionary size
% NOTE: The total dictionary size is 2x the size of the clean dictionary
%   signal when noise is accounted for. Thus the effective measurement
%   ratio is MEASUREMENT_RATIO / 2
params.MEASUREMENT_RATIO = 1;

% Measurement matrix. One of:
%   * 'IDENTITY'    (Random subset of rows from the identity matrix)
%   * 'GAUSSIAN'    (Entries randomly samples ~ N(0,1), columns normalized)
%   * 'SRM'         (Structurally random matrix)
params.MEASUREMENT_MATRIX = 'IDENTITY';

% (KSVD parameters)
params.KSVD_MAX_ITERS = 10;


%% SPARSE RECOVERY PARAMETERS

% Sparse recovery algorithm. One of:
%   * 'FISTA'        (Fast Iterative-Shrinkage Thresholding)
%   * 'SP'           (Subspace Pursuit)
%   * 'omp'          (Orthogonal Matching Pursuit)
%   * 'OMP'          (Orthogonal Matching Pursuit)
%   * 'ALM'          (Augmented Lagrangian Method)
%   * 'SUBTRACTION'  (Spectral subtraction)
params.RECOVERY_METHOD = 'omp';
params.SPARSITY_RATIO = 0.01;  % Proportion of nonzero components in sparse signal


%% OUTPUT PARAMETERS

% Print an update to the console after this many test signals have been
% denoised
params.CONSOLE_UPDATE_INTERVAL = 1;
params.SAVE_FIGURES = true;