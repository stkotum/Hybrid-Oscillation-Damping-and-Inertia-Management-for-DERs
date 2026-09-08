function run_all(gain, force_resim)
% RUN_ALL  Top-level driver: run every simulation the paper needs, then render its
% five figures.
% Arguments:
%   gain         (double, optional, default 20)     controller gain K for the linear feng16 small example, rounded to an integer and used to tag the ON nonlinear cache file case1_nonlinear_damping_comm_K<gain>.mat [MW.s/rad]
%   force_resim  (logical, optional, default false) if true, wipe the cached .mat data (and the sweep _cache) before running so everything is recomputed from scratch; if false reuse any cached data on disk
%
%   run_all                  % default K=20 for linear example, REUSE cached .mat data
%   run_all(20)              % explicit K for linear example, reuse cached data
%   run_all(20, true)        % FORCE full re-simulation - delete every
%                            % cached .mat first
%
% force_resim = false (default):
%   If a .mat is on disk, the nonlinear sim / per-share linear sim is skipped and
%   only the figures are regenerated from the cached data. If a .mat is
%   missing the runfiles will still generate it (several hours per feng9 nonlinear
%   side - long upstream schedule to t=60 s in accelerator mode -
%   seconds-to-minutes per large-system share).
%
% force_resim = true:
%   Deletes the cached .mat files before running, so everything is computed
%   from scratch. SLOW - the two feng9 nonlinear runs (OFF = upstream sim_m_case1,
%   ON = comm model) are several hours wall each, and the per-share linear sims
%   for Texas2000 take a couple of minutes each.
%   Files wiped:
%       modified/case1_nonlinear.mat
%       modified/case1_nonlinear_damping_comm_K<K>.mat
%       modified/paper_figures/_cache/          (entire dir)
%
% Three steps:
%   1) run_smallexample_feng_paper(K)  feng16 small example - builds the linear model
%                                      and runs the two nonlinear sims (idempotent).
%   2) run_large_systems               sweep over WECC, SC500, Texas2000 at the
%                                      paper-canonical K = [15, 9, 4], and Fig. 6 / 7.
%   3) make_paper_figures              the remaining figures, 4, 5(a) and 5(b).

if nargin<1 || isempty(gain),        gain = 20;          end
if nargin<2 || isempty(force_resim), force_resim = false; end
gain = round(gain);

here  = fileparts(mfilename('fullpath'));     % modified/runnable
mroot = fileparts(here);                      % modified
addpath(here, fullfile(mroot,'paper_figures'));   % the two runfiles + the figure builders

% ====================================================== optional cache wipe
if force_resim
    fprintf('=== force_resim = true: wiping cached .mat data ===\n');
    wipe_file(fullfile(mroot, 'case1_nonlinear.mat'));
    wipe_file(fullfile(mroot, sprintf('case1_nonlinear_damping_comm_K%d.mat', gain)));
    sweep_cache = fullfile(mroot, 'paper_figures', '_cache');
    if exist(sweep_cache, 'dir')
        fprintf('  rmdir %s\n', sweep_cache);
        rmdir(sweep_cache, 's');
    end
end

% ============================================== call the runfiles in order
fprintf('============================================================\n');
fprintf(' run_all: every simulation + the paper figures (feng9 K=%d)\n', gain);
if force_resim, fprintf(' [force_resim = true -- re-simulating from scratch]\n'); end
fprintf('============================================================\n');

fprintf('\n>>> 1/3  run_smallexample_feng_paper(%d)\n', gain);
run_smallexample_feng_paper(gain);

fprintf('\n>>> 2/3  run_large_systems\n');
run_large_systems;

fprintf('\n>>> 3/3  make_paper_figures (Fig. 4, 5a, 5b)\n');
make_paper_figures('gain', gain, 'only', {'fig4','fig5a','fig5b'});

fprintf('\n============================================================\n');
fprintf(' run_all: DONE.\n');
fprintf('============================================================\n');
end

% =========================================================================
function wipe_file(p)
% WIPE_FILE  Delete one cached file if it exists (no-op otherwise).
% Arguments:
%   p  (char)  file path to delete
if exist(p, 'file')
    fprintf('  delete %s\n', p);
    delete(p);
end
end
