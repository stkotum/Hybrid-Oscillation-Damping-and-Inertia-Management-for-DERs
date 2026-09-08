function stem = fig5a_linear_perdev(cfg)
% FIG5A_LINEAR_PERDEV  Paper Fig. 5(a): per-node frequency deviation of the LINEARISED
% twelve-bus model, K = 0 on the left and K = N*I on the right.
% Arguments:
%   cfg  (struct, optional, default paper_config())  paths and gain
% Returns the output path stem (paper_export appends .pdf/.png/.tikz).
%
%   fig5a_linear_perdev
%
% The layout, the envelopes and the legend are perdev_figure; this file only says
% which data goes in and how far the axes run. The linear record starts from rest, so
% the nadir is simply the minimum of the whole COI trace.
if nargin < 1 || isempty(cfg), cfg = paper_config(); end
L = linear_data(cfg);

te = L.off.t_event; f0 = L.off.f0;
P = struct( ...
    'off',     side(L.off, te, f0), ...
    'on',      side(L.on,  te, f0), ...
    'inertia', L.off.m, ...        % nodal inertia, ranks the f_i colours
    'gain',    cfg.gain, ...
    'xlim',    [-0.125 2], ...
    'ylim',    [-0.2 0.1], ...
    'env_x',   [-0.5 2], ...
    'nadir_x', [-Inf Inf]);

stem = fullfile(cfg.outdir, 'fig5a_linear_perdev_off_vs_on');
paper_export(perdev_figure(P), stem);
end


function d = side(R, te, f0)
% SIDE  One simulate_linear result reduced to step-relative time and deviations from
% the nominal frequency f_0.
d = struct('t', R.tt - te, 'F', R.fabs - f0, 'coi', R.fcoi - f0);
end
