function fns = chooseRandom(num_random_files, path, format)
% CHOOSERANDOM  Choose random files from a directory (without replacement).
%
% ARGUMENTS
% ---------
% num_random_files : int
%   Number of random files to choose
% path : str
%   Full path to a directory containing at least num_files files
% format : str
%   File format, e.g. 'wav' or 'aiff'
%
% RETURNS
% -------
% fns : cell string
%   Name of the file that was chosen
%

% List all files of the specified format
dir_data = dir(fullfile(path, ['*.', format]));
dir_filenames = {dir_data.name};
num_dir_files = length(dir_filenames);

% Throw an error if we asked for more files than exist
if num_dir_files < num_random_files
    err_str = 'Error: Requested %d files, but only %d in %s';
    error(err_str, num_random_files, num_dir_files, path)
end

% Return the number of random files requested, sampled without replacement
file_idxs = randperm(length(dir_filenames), num_random_files);
fns = dir_filenames(file_idxs);

end
