function run_smallexample_feng_paper(gain)
% RUN_SMALLEXAMPLE_FENG_PAPER  End-to-end simulation driver for the feng16 9-DER small
% example: build the paper-true linear model, integrate it OFF and ON, print the paper
% invariants, and run the nonlinear validation.
% Arguments:
%   gain  (double, optional, default 20)  communicated-damping gain K = gain*I in
%         D^com = C K C'; rounded to an integer and used to name the ON nonlinear .mat
%         [MW.s/rad]
%
%   run_smallexample_feng_paper          % default gain K = 20
%   run_smallexample_feng_paper(20)      % explicit K
%
% Pipeline (paths relative to modified/; calls these in order):
%   build_linear_cases(K)       -> linear/cases/case_{nocomm,comm}.mat : M, D, L,
%                                  governor (S^g,T^g,R^-1), step, D^com (see build_linear_cases)
%   simulate_linear(case)       -> Roff/Ron : integrate the closed-loop A (Eq. cl_A);
%                                  COI/RoCoF/nadir + small-signal A^ss spectrum (Eq. Ass)
%   sim_m_case1_long            -> case1_nonlinear.mat                    : nonlinear OFF baseline
%   sim_m_case1_damping_comm(K) -> case1_nonlinear_damping_comm_K<K>.mat  : nonlinear ON controller
%
% nonlinear runs use the upstream long schedule (GFM 30 s, GFL 35 s, breaker 40 s, to
% 60 s) in accelerator mode and are idempotent: a side is skipped if its .mat is on
% disk, a missing .mat triggers a multi-hour Simscape run. The two nonlinear drivers
% are kept local (modified/runnable_notpublic, not part of the repository); when they
% are absent the nonlinear stage is reported and skipped, and the linear stage still
% runs in full.
%
% FIGURES ARE NOT DRAWN HERE. This driver produces the data; the paper's figures are
% rendered from it by modified/paper_figures:
%   make_paper_figures                   % all five paper figures
% Figures 4 and 5(a) need only the linear cases written here; 5(b) needs both
% nonlinear .mat files.
if nargin<1 || isempty(gain), gain = 20; end
gain = round(gain);

here  = fileparts(mfilename('fullpath'));   % modified/runnable
mroot = fileparts(here);                    % modified
root  = fileparts(mroot);                   % repo root
addpath(fullfile(mroot,'linear'), fullfile(mroot,'functions'), ...
        fullfile(mroot,'build_slx'), fullfile(mroot,'models'), fullfile(root,'upstream'));
nonpublic = fullfile(mroot,'runnable_notpublic');     % the two nonlinear drivers, local only
if isfolder(nonpublic), addpath(nonpublic); end

% Windows security policy ("NoDefaultCurrentDirectoryInExePath=1") stops cmd.exe
% from finding the .bat that Simulink Coder generates next to the Accelerator MEX
% during the OFF-baseline build of simulation_model.slx. Unset it for this process.
if ispc, setenv('NoDefaultCurrentDirectoryInExePath',''); end

% build_linear_cases / simulate_linear use paths relative to modified/, so run from there.
old = cd(mroot); restore = onCleanup(@() cd(old));

% ===================== 1) build the case files and integrate the linear model (OFF + ON)
fprintf('\n=== run_smallexample_feng_paper(K=%d): build_linear_cases + linear OFF/ON ===\n', gain);
build_linear_cases(gain);
cases_dir = fullfile(mroot,'linear','cases');
Roff = simulate_linear(fullfile(cases_dir,'case_nocomm.mat'));   % D^com = 0      (controller OFF)
Ron  = simulate_linear(fullfile(cases_dir,'case_comm.mat'));     % D^com = C K C' (controller ON)

% ===================== 2) console summary (paper invariants)
fprintf('\n================= linear case summary (K = %d) =================\n', gain);
fprintf('small-signal A^ss (DER allocation, inverter buses): baseline maxRe=%+.3f zeta_min=%.3f | comm maxRe=%+.3f zeta_min=%.3f\n', ...
        Roff.maxRe, Roff.minZeta, Ron.maxRe, Ron.minZeta);
fprintf('COI RoCoF  (Thm 1, invariant): %+.4f Hz/s analytic, %.4f numeric\n', ...
        Roff.rocof_analytic, Roff.rocof_max);
fprintf('COI endpoint (Thm 2, invariant): %+.4f Hz analytic, %+.4f baseline, %+.4f comm\n', ...
        Roff.endpoint_analytic, Roff.steady, Ron.steady);
fprintf('COI nadir: %+.5f Hz at %.3f s baseline, %+.5f Hz at %.3f s comm (zero-sum D^com leaves COI ~unchanged)\n', ...
        Roff.nadir, Roff.t_nadir, Ron.nadir, Ron.t_nadir);

% ===================== 3) nonlinear sims (idempotent: each side skipped if its .mat exists)
% The two drivers are local only. Without them the stage is skipped; Fig. 5(b) is then
% drawn from the two saved .mat files if they are on disk, and skipped otherwise.
have_drivers = exist('sim_m_case1_long','file') == 2 && exist('sim_m_case1_damping_comm','file') == 2;
if have_drivers
    fprintf('\n=== nonlinear OFF baseline ===\n');
    sim_m_case1_long();                  % upstream Scenario 1 (long) -> case1_nonlinear.mat
    fprintf('\n=== nonlinear ON controller (K=%d) ===\n', gain);
    sim_m_case1_damping_comm(gain);
else
    nl_off = fullfile(mroot, 'case1_nonlinear.mat');
    nl_on  = fullfile(mroot, sprintf('case1_nonlinear_damping_comm_K%d.mat', gain));
    fprintf('\n=== nonlinear stage skipped ===\n');
    fprintf('The nonlinear drivers sim_m_case1_long / sim_m_case1_damping_comm are not part of this repository.\n');
    if exist(nl_off,'file') && exist(nl_on,'file')
        fprintf('Saved runs found (%s, %s): Fig. 5(b) can be drawn.\n', nl_off, nl_on);
    else
        fprintf('Fig. 5(b) needs their saved runs (%s, %s); the committed figures/fig5b_* files are its output.\n', nl_off, nl_on);
    end
end

fprintf('\nDONE.  Data ready; render the paper figures with make_paper_figures.\n');
end
