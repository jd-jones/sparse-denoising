520.628: Final Project
----------------------
Jonathan D. Jones
Valerie Rennoll

Introduction
------------
This project uses compressed sensing methods for audio denoising. We're
specifically interested in recovering lung sounds from the kind of
nonstationary ambient noise one might encounter in clinics such as those in
the CHIRP project [2]. This software constitutes a unified
experimental framework for evaluating different denoising methods in this
context.

Getting Started
---------------
Make sure you set up the project directory to look like the structure below:

PROJECT ROOT
  |---> src
  |---> data
  | |---> clean
  | |---> noise
  | | |---> [noise class subdirectories]

src should contain all source code.
data/clean should contain all recordings of clean lung sounds (.wav format).
data/noise should contain subdirectories with recordings of noise sounds,
  (.wav format) organized by class.

Running an Experiment
---------------------
Open `src/experiment_params.m` and modify it to match your desired
experiment setup. Then run `run_experiment.m` from MATLAB.
(Optionally, you can modify the script to sweep over different
hyperparameters.) The script will print a summary of the experiment to the
console and draw some figures. Figures, text output, and corrupted/recovered
audio files summarizing experiment results are all saved to a directory in
output.

STFT
----
To be consistent with [1], two window lengths were used to obtain the STFT.
1. 50-ms window (N = 400) and 90 percent overlap and Hamming windowing
2. 80-ms window (N = 640) with 80 percent overlap and Hamming windowing

References
----------
[1] D. Emmanouilidou, E. D. McCollum, D. E. Park and M. Elhilali,
    "Adaptive Noise Suppression of Pediatric Lung Auscultations With Real
    Applications to Noisy Clinical Settings in Developing Countries,"
    in IEEE Transactions on Biomedical Engineering, vol. 62, no. 9,
    pp. 2279-2288, Sept. 2015. doi: 10.1109/TBME.2015.2422698
[2] <TODO: CHIRP project reference>
