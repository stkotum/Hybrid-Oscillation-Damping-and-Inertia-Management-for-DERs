function stem = fig5b_nonlinear_perdev(cfg)
% FIG5B_NONLINEAR_PERDEV  Paper Fig. 5(b): per-node frequency deviation of the
% NONLINEAR (Simscape) twelve-bus simulation, K = 0 on the left and K = N*I on the right.
% Arguments:
%   cfg  (struct, optional, default paper_config())  paths and gain
% Returns the output path stem (paper_export appends .pdf/.png/.tikz).
%
%   fig5b_nonlinear_perdev
%
% Same layout as Fig. 5(a) (perdev_figure); this file only says which data goes in and
% how far the axes run. The nonlinear transient is slower, so the panels run to 5 s
% instead of 2 s and the nadir is taken over the post-step viewport rather than over
% the whole record, which still carries the 40 s pre-step run-up.
%
% Needs both saved Simscape runs on disk (case1_nonlinear.mat and
% case1_nonlinear_damping_comm_K<gain>.mat, several hundred MB, gitignored). They are
% written by the nonlinear drivers, which are not part of the repository; without
% them make_paper_figures skips this figure and the committed output is the reference.
if nargin < 1 || isempty(cfg), cfg = paper_config(); end
N = nonlinear_data(cfg);

P = struct( ...
    'off',     with_time(N.off, N.t), ...
    'on',      with_time(N.on,  N.t), ...
    'inertia', N.inertia, ...      % per-channel virtual inertia, ranks the f_i colours
    'gain',    cfg.gain, ...
    'xlim',    [-0.125 5], ...
    'ylim',    [-0.2 0.1], ...
    'env_x',   [-0.5 5], ...
    'nadir_x', [0 5]);

stem = fullfile(cfg.outdir, 'fig5b_nonlinear_perdev_off_vs_on');
paper_export(perdev_figure(P), stem);
end


function d = with_time(side, t)
% WITH_TIME  Attach the shared time vector to one side of the nonlinear pair.
d = struct('t', t, 'F', side.F, 'coi', side.coi);
end
