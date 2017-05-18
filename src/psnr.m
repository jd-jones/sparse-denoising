function x_psnr = psnr(x, x_est)
% PSNR  Compute peak signal-to-noise ratio
%
% ARGUMENTS
% ---------
% x : double array
%   Ground-truth signal
% x_est : double array
%   Estimated signal
%
% RETURNS
% -------
% x_psnr : double
%   Peak signal-to-noise ratio (in decibels)
%

x_max = max(x);

x_residue = x - x_est;
x_mse = mean(x_residue.^2);
x_psnr = 10 * log10(x_max^2 / x_mse);

end

