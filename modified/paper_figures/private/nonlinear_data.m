function N = nonlinear_data(cfg)
% NONLINEAR_DATA  The nonlinear (Simscape) twelve-bus pair behind Fig. 5(b).
% Arguments:
%   cfg  (struct)  paper_config settings
%
% Reads the two saved scope runs (D^com = 0 and D^com = C K C', several-hundred-MB
% .mat files written by the nonlinear drivers, which are not part of the repository;
% the committed Fig. 5(b) is their rendered output) and reduces
% each to what the figure needs:
%   N.t              (n_t x 1)        time since the step [s]
%   N.off, N.on      structs with
%       .F           (n_t x n_ch)     per-channel frequency deviation f - f_0 [Hz]
%       .coi         (n_t x 1)        COI frequency deviation [Hz]
%   N.inertia        (n_ch x 1)       per-channel (virtual) inertia, used to rank the
%                                     f_i colours
%   N.description    (char)           which COI definition was applied
%
% f_0 is each channel's own pre-step mean, i.e. the simulation's equilibrium rather
% than literally 60 Hz. The panel is still labelled f_0 to match the linear one, since
% the model starts the step from nominal.
%
% Memoized per gain: reading the two .mat files is the slow part of Fig. 5(b).
persistent CACHE
key = sprintf('K%g', cfg.gain);
if ~isempty(CACHE) && strcmp(CACHE.key, key)
    N = CACHE.data; return
end

opts = coi_weights(cfg);
fprintf('  nonlinear pair: reading the two scope runs (%s)\n', opts.description);
[F_off, t] = read_scope_freq(cfg.nonlinear_off, cfg.nonlinear_dt, cfg.nonlinear_step);
 F_on      = read_scope_freq(cfg.nonlinear_on,  cfg.nonlinear_dt, cfg.nonlinear_step);

N = struct('t', t, 'inertia', opts.inertia, 'description', opts.description, ...
           'off', reduce(F_off, t, opts), ...
           'on',  reduce(F_on,  t, opts));

CACHE = struct('key', key, 'data', N);
end


% =========================================================================
function side = reduce(F, t, opts)
% REDUCE  Subtract each channel's pre-step mean and form the COI of the result.
base = mean(F(t >= -0.5 & t < 0, :), 1);
side = struct('F', F - base, 'coi', weighted_coi(F, opts) - weighted_coi(base, opts));
end


function [F, t] = read_scope_freq(matfile, dt, t_step)
% READ_SCOPE_FREQ  Per-channel frequency and step-relative time from a scope .mat.
% Arguments:
%   matfile  (char)    path to a nonlinear result .mat with ScopeData.signals
%   dt       (double)  sample period [s]
%   t_step   (double)  breaker/step instant, subtracted so t = 0 is the step [s]
if ~exist(matfile,'file')
    error('nonlinear_data:missing', ['%s not found. Fig. 5(b) needs both saved ' ...
        'Simscape runs, written by the nonlinear drivers that are not part of this ' ...
        'repository; the committed figures/fig5b_* files are its output.'], matfile);
end
S = load(matfile); F = S.ScopeData.signals(1).values;
if size(F,1) < size(F,2), F = F.'; end
t = (0:size(F,1)-1)'*dt - t_step;
end


function opts = coi_weights(cfg)
% COI_WEIGHTS  COI weights and per-channel (virtual) inertia for the nonlinear
% channels [w_c1..w_c9, w_sm1, w_sm2], read from the built linear case file.
% .inertia is always populated (it ranks the f_i colours); .weights only in
% 'weighted' mode.
if ~exist(cfg.case_off,'file'), build_linear_cases(cfg.gain); end
S = load(cfg.case_off);
inertia = [S.m_der(:); S.meta.m_sg; S.meta.m_sg];   % 9 DER + the 2 synchronous machines
opts = struct('mode',cfg.coi_mode, 'weights',[], 'inertia',inertia, 'description','');
switch cfg.coi_mode
    case 'weighted'
        opts.weights = inertia / sum(inertia);
        opts.description = 'inertia-weighted COI over [w_c1..w_c9,w_sm1,w_sm2]';
    otherwise
        opts.description = 'arithmetic mean COI over the nonlinear frequency channels';
end
end


function coi = weighted_coi(F, opts)
% WEIGHTED_COI  The selected nonlinear COI frequency [Hz] of a channel matrix.
if strcmp(opts.mode,'weighted')
    if size(F,2) ~= numel(opts.weights)
        error('nonlinear_data:channels', ...
              'Weighted nonlinear COI expected %d channels, got %d.', ...
              numel(opts.weights), size(F,2));
    end
    coi = F * opts.weights(:);
else
    coi = mean(F,2);
end
end
