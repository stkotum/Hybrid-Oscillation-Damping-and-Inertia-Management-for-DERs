function cfg = paper_config(varargin)
% PAPER_CONFIG  One settings struct for every paper figure: paths, the gains and the
% sweep cases. Every builder in this folder starts from it, so a path or a gain is
% written down exactly once.
% Arguments (name-value):
%   'gain'    (double, default 20)  communicated-damping gain K = gain*I of the
%                                   twelve-bus example (Fig. 4, 5a, 5b) [MW.s/rad]
%   'outdir'  (char, default <this folder>/figures)  where the figures are written
%
%   cfg = paper_config()
%   cfg = paper_config('gain', 20)
%
% SIDE EFFECT: puts modified/linear/ and upstream/ on the MATLAB path, since the
% figures are drawn from the simulation code that lives there (build_linear_cases,
% simulate_linear, and the upstream case data they load by name).
p = inputParser;
p.addParameter('gain', 20, @(x) isnumeric(x) && isscalar(x));
p.addParameter('outdir', '', @(x) ischar(x) || isstring(x));
p.parse(varargin{:}); o = p.Results;

here    = fileparts(mfilename('fullpath'));   % modified/paper_figures/private
figroot = fileparts(here);                    % modified/paper_figures
mroot   = fileparts(figroot);                 % modified
root    = fileparts(mroot);                   % repo root

addpath(fullfile(mroot,'linear'), fullfile(root,'upstream'));

cfg = struct();
cfg.gain    = round(o.gain);
cfg.figroot = figroot;
cfg.mroot   = mroot;
cfg.root    = root;

% ================================================================= where things go
cfg.outdir   = char(o.outdir);
if isempty(cfg.outdir), cfg.outdir = fullfile(figroot,'figures'); end
cfg.cachedir = fullfile(figroot,'_cache');    % per-share sweep results (gitignored)

% ===================================================== twelve-bus example (Fig. 4/5)
% build_linear_cases writes the OFF/ON pair here; the nonlinear .mat files are the
% saved Simscape runs of the local nonlinear drivers (gitignored, several hundred MB).
cfg.cases_dir     = fullfile(mroot,'linear','cases');
cfg.case_off      = fullfile(cfg.cases_dir,'case_nocomm.mat');   % D^com = 0
cfg.case_on       = fullfile(cfg.cases_dir,'case_comm.mat');     % D^com = C K C'
cfg.nonlinear_off = fullfile(mroot,'case1_nonlinear.mat');
cfg.nonlinear_on  = fullfile(mroot, sprintf('case1_nonlinear_damping_comm_K%d.mat', cfg.gain));
% Nonlinear COI definition: 'weighted' = Feng-style inertia-weighted COI over the
% eleven frequency channels [w_c1..w_c9, w_sm1, w_sm2]; 'mean' = plain average.
cfg.coi_mode = 'weighted';
% Upstream long schedule: 1e-4 s samples, breaker (the load step) at t = 40 s.
cfg.nonlinear_dt   = 1e-4;
cfg.nonlinear_step = 40;

% ============================================== large-system sweep (Fig. 6 and 7)
% Paper-canonical per-case K: picked to harden the closed-loop envelope while keeping
% every non-rigid eigenvalue inside the sector Re <= -3 of sector_spec. WECC and SC500
% sit deep inside it; Texas2000 is sector-tight at Re = -3.006.
cfg.shares = 0:10:100;                        % activation shares [percent]
cfg.sweep  = struct( ...
    'name',     {'WECC',           'SC500',              'Texas2000'}, ...
    'id',       {'WECC_allocated', 'SC500_allocated',    'Texas2000_allocated'}, ...
    'scenario', {fullfile(root,'export','WECC','allocated','matlab','scenario.mat'), ...
                 fullfile(root,'export','SouthCarolina500','allocated','matlab','scenario.mat'), ...
                 fullfile(root,'export','Texas2000','allocated','matlab','scenario.mat')}, ...
    'gain',     {15,               9,                    4});
end
