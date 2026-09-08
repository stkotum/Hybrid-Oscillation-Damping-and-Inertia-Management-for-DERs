# Structured Modal-Energy Dissipation for Inter-Area Oscillations in Reduced Low-Inertia Power Systems

This repository is the code of the paper

> S. Kohlhaas and P. Kotyczka, "Structured Modal-Energy Dissipation for Inter-Area
> Oscillations in Reduced Low-Inertia Power Systems," 25th Wind & Solar Integration
> Workshop, Porto, Portugal, 29 September - 2 October 2026.

It produces the paper's Figures 4, 5(a), 5(b), 6 and 7: the zero-sum damping
controller on the augmented Kundur twelve-bus benchmark, linearised and nonlinear,
and the participation sweep on the WECC, SC500 and Texas2000 systems.

It reproduces and extends the code accompanying:

> C. Feng, L. Huang, X. He, Y. Wang, F. Dörfler, C. Kang,
> "Hybrid Oscillation Damping and Inertia Management for Distributed Energy
> Resources," IEEE Transactions on Power Systems, vol. 40, no. 6,
> pp. 5041-5056, 2025. doi:10.1109/TPWRS.2025.3562811

The original authors' code is included as a git submodule under `upstream/`,
taken from:
https://github.com/VictorCFeng/Hybrid-Oscillation-Damping-and-Inertia-Management-for-DERs

It is kept read-only. The linear model here loads the inertia and damping allocation
and the network data of the twelve-bus benchmark from it; the zero-sum damping
controller, the closed-loop linear model, the communicated-damping Simulink model and
the large-system sweep are added in `modified/`.

## Citation

If you use this code, cite the paper it belongs to:

- S. Kohlhaas and P. Kotyczka, "Structured Modal-Energy Dissipation for Inter-Area
  Oscillations in Reduced Low-Inertia Power Systems," in Proc. 25th Wind & Solar
  Integration Workshop, Porto, Portugal, 2026.

```bibtex
@inproceedings{kohlhaas2026structured,
  author    = {Kohlhaas, Stephan and Kotyczka, Paul},
  title     = {Structured Modal-Energy Dissipation for Inter-Area Oscillations in
               Reduced Low-Inertia Power Systems},
  booktitle = {25th Wind \& Solar Integration Workshop},
  address   = {Porto, Portugal},
  year      = {2026},
}
```

and, as the upstream repository requests, Feng et al.:

- C. Feng, L. Huang, X. He, Y. Wang, F. Dörfler, C. Kang, "Hybrid Oscillation
  Damping and Inertia Management for Distributed Energy Resources," IEEE
  Transactions on Power Systems, vol. 40, no. 6, pp. 5041-5056, Nov. 2025,
  doi:10.1109/TPWRS.2025.3562811.
- C. Feng, S. Wang, H. O. Gao, F. You, "Optimal Participation Design of DERs in
  General Frequency Shaping Services," IEEE Transactions on Power Systems,
  doi:10.1109/TPWRS.2025.3586137.

## Getting started

Clone with the submodule; without it the linear model cannot load the upstream
allocation data and stops with a message saying so:

```
git clone --recurse-submodules https://github.com/stkotum/Hybrid-Oscillation-Damping-and-Inertia-Management-for-DERs.git
```

If you already cloned without it, run `git submodule update --init`. On Windows,
`git config --global core.longpaths true` avoids a checkout error on the long file
name of the paper PDF when the clone sits in a deep directory.

Requirements:

- MATLAB R2025b (the release the figures were made with). The linear pipeline and
  the figures need no toolbox; the Control System Toolbox, if present, additionally
  fills in the COI transfer function returned by `simulate_linear`. The nonlinear
  model needs Simulink and Simscape Electrical and a C compiler for the accelerator
  build.
- Optional: [matlab2tikz](https://github.com/matlab2tikz/matlab2tikz) placed at
  `modified/external/matlab2tikz/` for the PGF/TikZ export. Without it the PDF and
  PNG are still written and the `.tikz` is skipped with a warning.
- Optional: `lualatex` to compile the preview document.

Quick start, from the repository root in MATLAB:

```matlab
cd modified/paper_figures
make_paper_figures                            % Fig. 4, 5(a), 6, 7; 5(b) is skipped unless its data is on disk
make_paper_figures('only', {'fig6','fig7'})   % a subset
```

The first call of Fig. 6 and Fig. 7 runs the activation sweep of the three large
systems and caches it under `modified/paper_figures/_cache/` (about 650 MB, a few
minutes in total); later calls only redraw.

## What run_all does

`run_all` is the top-level driver. From the repository root in MATLAB:

```matlab
addpath modified/runnable
run_all                % default gain K = 20, reuse cached data
run_all(20)            % explicit K
run_all(20, true)      % wipe the cached data first and recompute from scratch
```

It takes two optional arguments:

- `gain` (default 20): the communicated-damping gain K for the small example. It is
  rounded to an integer and used to tag the controller-on nonlinear result file.
- `force_resim` (default false): when false, any result `.mat` already on disk is
  reused and only the figures are re-rendered. When true, the cached files
  (`case1_nonlinear.mat`, `case1_nonlinear_damping_comm_K<K>.mat`, and the sweep
  cache under `modified/paper_figures/_cache/`) are deleted first, so everything is
  recomputed.

`run_all` then calls these in order; each can also be run on its own:

```
1/3   run_smallexample_feng_paper(K)   simulations of the twelve-bus small example
2/3   run_large_systems                the activation sweep + Fig. 6 and Fig. 7
3/3   make_paper_figures               Fig. 4, 5(a) and 5(b)
```

## 1) run_smallexample_feng_paper(K): the twelve-bus small example

This is the paper's small example, the augmented Kundur benchmark of Feng et al.:
three areas, two governed synchronous machines, six grid-forming and three
grid-following converters, so nine inverter buses carry the inertia and damping
allocation. (The upstream model numbers the four converter buses behind their
transformers 13 to 16, which is why some file names say `feng16`.) The driver runs
the two stages below and prints the paper invariants, including the COI nadir and
its time; it draws no figures itself, `modified/paper_figures` does that from the
data it leaves behind.

Linear model (fast, always runs):

- `build_linear_cases(K)` writes two case files to `modified/linear/cases/`:
  `case_nocomm.mat` with communicated damping `D^com = 0`, and `case_comm.mat`
  with `D^com = C K C'` (zero-sum communicated damping). Each holds the reduced
  swing model: inertia `M = diag(m)`, native damping `D = diag(d)`, network
  Laplacian `L`, the nodal governor `(S^g, T^g = diag(tau), R^-1)`, the load step
  `(B^p, pbar)`, and `D^com`. The two files are tracked, so a run rewrites them
  and `git status` shows them as modified.
- `simulate_linear` integrates the closed-loop swing system for each case, and
  `small_signal_der` forms the small-signal state matrix used for the eigenvalue
  plots.

Nonlinear Simulink model (slow, cached):

- `sim_m_case1_long` runs the upstream Scenario 1 verbatim (the upstream
  `simulation_model.slx`: grid-forming switch at 30 s, grid-following at 35 s,
  300 MW breaker at 40 s, simulate to 60 s, accelerator mode) and saves the
  controller-off baseline to `case1_nonlinear.mat`.
- `sim_m_case1_damping_comm(K)` runs the same scenario with inter-DER damping
  communication active (`simulation_model_damping_comm.slx`, whose CommGain block
  reads the workspace matrix `D_comm`) and saves the controller-on result to
  `case1_nonlinear_damping_comm_K<K>.mat`.
- Both are idempotent: a side is skipped if its `.mat` exists, so only the first
  run at a given K pays the multi-hour simulation cost.

These two nonlinear drivers are kept local and are not part of this repository (see
Notes). When they are absent the driver says so and skips the nonlinear stage;
everything else still runs.

The figures drawn from this data are Fig. 4 (`fig4_linear_eig`), Fig. 5(a)
(`fig5a_linear_perdev_off_vs_on`) and Fig. 5(b)
(`fig5b_nonlinear_perdev_off_vs_on`); 4 and 5(a) need only the linear cases, 5(b)
needs both nonlinear `.mat` files and is skipped with a warning without them.

## 2) run_large_systems: activation sweep over three large systems

`run_large_systems` sweeps the linear model over three allocated systems at the
paper-canonical per-case gains:

- WECC, K = 15
- SouthCarolina500, K = 9
- Texas2000, K = 4

For each system it reads the pre-allocated reduced model from
`export/<system>/allocated/matlab/scenario.mat`, then sweeps the activation share
from 0 to 100 percent in steps of 10, where the share is the fraction of DER nodes
that carry the communicated damping. Units are activated in ascending order of their
native damping, and a nonzero share always activates at least two units, since a
single unit has nothing to exchange with. Each share is one `simulate_linear` run,
cached under `modified/paper_figures/_cache/<system>/`.

The three `scenario.mat` files are shipped as data. They hold the Kron-reduced
network matrix of each MATPOWER case with every synchronous generator replaced by an
inverter-based DER, together with the inertia and damping allocation obtained with
the method of Feng et al.; the allocation step itself is not part of this
repository.

Two figures come out of it:

- Fig. 6, `fig6_eig_zoom_3cases`: the small-signal eigenvalues per system, with the
  nominal K = 0 case as crosses and the damped shares as dots.
- Fig. 7, `fig7_coi_envelope_3cases`: one column per system, three rows: COI
  frequency deviation, the peak per-node swing `max_i |f_i - f_COI|` in Hz, and
  that peak swing minus its 0 percent (no-damping) baseline (lower means a larger
  reduction).

## 3) make_paper_figures: the figures

`modified/paper_figures/` is the single place the paper's five MATLAB figures are
drawn, and nothing else is exported. It has its own README; the short version is

```matlab
cd modified/paper_figures
make_paper_figures                            % all five
make_paper_figures('only', {'fig6','fig7'})   % a subset
```

`paper_export` writes every figure three ways into `paper_figures/figures/`: a vector
PDF, a 600 dpi PNG, and a PGF/TikZ `.tikz` for direct LaTeX inclusion; Fig. 6 and 7
also write a small `<stem>-1.png` colour-bar raster that their `.tikz` includes. The
`.tikz` is what the paper `\input`s. That step uses matlab2tikz, expected under
`modified/external/`; if it is not present the step is skipped with a warning and only
the PDF and PNG are produced. `paper_figures/preview/` holds a short IEEEtran document
that inputs all five and compiles them to one PDF for checking.

## Layout

```
upstream/    Feng et al. original repository (git submodule, read-only)
modified/    the MATLAB pipeline of this work
  linear/               build_linear_cases, simulate_linear, small_signal_der
  build_slx/            build_feng9_nonlinear_comm (builds the communicated-damping model)
  models/               simulation_model_damping_comm.slx
  functions/            setup and diagnostics for the nonlinear model
  runnable/             run_all, run_smallexample_feng_paper, run_large_systems
  paper_figures/        the five paper figures: builders, styling, outputs, preview
  papers/               the paper and the Feng et al. preprint
export/<system>/allocated/matlab/scenario.mat   pre-allocated reduced models
```

## Notes

- The two large nonlinear result `.mat` files and the sweep `_cache/` data are not
  tracked; they are regenerated on demand. The committed figures under
  `modified/paper_figures/figures/` are the rendered outputs.
- The nonlinear sim drivers (the controller-off and controller-on wrappers around
  the upstream Simulink model) are kept local and are not part of this repository.
  Fig. 5(b) is their rendered output.

## About the code

Claude Code was used to clean up and refactor this code for readability. The models,
methods and results are the authors' own.
