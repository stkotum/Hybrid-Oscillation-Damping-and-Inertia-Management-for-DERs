# paper_figures

The five MATLAB figures of the paper, and everything that draws them. One entry point,
one output folder, no other plots.

Paper: *Structured Modal-Energy Dissipation for Inter-Area Oscillations in Reduced
Low-Inertia Power Systems*, 25th Wind & Solar Integration Workshop.

| Paper | Output stem (in `figures/`) | What it shows |
|---|---|---|
| Fig. 4 | `fig4_linear_eig` | Twelve-bus small-signal spectrum, `K=0` against `K=20 I` |
| Fig. 5(a) | `fig5a_linear_perdev_off_vs_on` | Per-node deviation, linearised model, OFF \| ON |
| Fig. 5(b) | `fig5b_nonlinear_perdev_off_vs_on` | Per-node deviation, nonlinear simulation, OFF \| ON |
| Fig. 6 | `fig6_eig_zoom_3cases` | Small-signal spectrum over the activation sweep, three systems |
| Fig. 7 | `fig7_coi_envelope_3cases` | COI envelope over the activation sweep, three systems |

Figures 1, 2 and 3 of the paper are not made here: 1 and 2 are hand-drawn TikZ in the
paper repo, 3 is a vector crop from the reference paper.

## Run it

```matlab
cd modified/paper_figures
make_paper_figures                            % all five
make_paper_figures('only', {'fig6','fig7'})   % just the large-system sweep
make_paper_figures('gain', 20)                % explicit K for the twelve-bus example
fig7_coi_envelope_3cases                      % each builder also stands alone
```

Each figure is written three ways: `.tikz` (what the paper `\input`s), `.pdf` (vector
standalone) and `.png` (600 dpi). Fig. 6 and 7 also write a `<stem>-1.png`, the
colour-bar raster their `.tikz` includes by bare filename. `paper_config` puts
`modified/linear/` and `upstream/` on the path itself, so no setup is needed beyond
`cd` (the `upstream/` submodule has to be checked out, see the top-level README).

The MATLAB-side `.pdf` and `.png` of Fig. 7 show its three row labels as raw macro
text: they are written in the paper's `\fcoi` notation, which `paperfig_preamble.tex`
defines for the `.tikz` and MATLAB's interpreter does not know. The `.tikz` is right.

## What has to be on disk

| Figure | Needs | If missing |
|---|---|---|
| 4, 5(a) | nothing | `build_linear_cases` + `simulate_linear` run in seconds |
| 5(b) | `modified/case1_nonlinear.mat` and `case1_nonlinear_damping_comm_K20.mat` | skipped with a warning; the two files are written by the nonlinear drivers, which are not part of the repository, so the committed `fig5b_*` outputs are the reference |
| 6, 7 | `_cache/<case>/result_share_*.mat` | recomputed from `export/*/allocated/matlab/scenario.mat`, minutes per share |

`_cache/` is gitignored and about 650 MB. It is keyed by case and by `K`, so changing a
gain misses the cache rather than silently reusing the wrong run. Nothing else
invalidates it: after changing a scenario `.mat`, delete that case's directory.

[matlab2tikz](https://github.com/matlab2tikz/matlab2tikz) is expected at
`modified/external/matlab2tikz/`, so that `modified/external/matlab2tikz/src/matlab2tikz.m`
exists (gitignored, not part of the repo). Without it the `.pdf` and `.png` are still
written and the `.tikz` is skipped with a warning, which means the paper keeps
whatever `.tikz` was there before, so check for that warning before trusting a
re-export.

## Layout

```
make_paper_figures.m          entry point: the loop over the five builders
fig4_linear_eig.m             one file per figure. Each is self-contained: it asks the
fig5a_linear_perdev.m           data layer for what it needs, lays out its panels and
fig5b_nonlinear_perdev.m        exports. The paper geometry lives at the top of each
fig6_eig_zoom_3cases.m          one as named constants in inches.
fig7_coi_envelope_3cases.m
private/                      everything shared, invisible from outside the folder
  paper_config.m                paths, gains, the sweep cases - written down once
  linear_data.m                 the K=0 / K=N*I linear pair (memoized)
  nonlinear_data.m              the two Simscape runs, reduced to deviations + COI
  sweep_data.m                  the per-share sweep of the three large systems (cached)
  paper_style/figure/axes.m     IEEE sizes, fonts, line widths, the two accent colours
  paper_export.m                pdf + png + tikz, and the decimation the tikz needs
  tikz_make_adjustable.m        hoists fonts/sizes into the LaTeX knobs
  place_axes_in.m               puts a plot box at an exact rectangle in inches
  perdev_figure.m               the shared body of Fig. 5(a) and 5(b)
  vik_wing/line_ramp/ranked_line_ramp, sweep_colormap, share_style, band_col   the colour system
  coi_envelope, draw_band, draw_ring, add_perdev_legend    the Fig. 5 envelopes
  draw_eig_sector, draw_eig_grid, sector_spec              the eigenvalue guides
  draw_share_colorbar, draw_kbox, panel_title              the sweep furniture
  colormaps/                    Crameri's vik and imola, with the citation
figures/                      the five exported figure sets + paperfig_preamble.tex
preview/                      tikz_preview.tex (+ its compiled pdf): all five in an IEEE two-column page
_cache/                       per-share sweep results (gitignored)
```

## Colour convention: red is the uncontrolled case

Red means `K = 0` in every figure, so the baseline is identifiable without reading a
legend.

| Role | Colour | Where it comes from |
|---|---|---|
| Uncontrolled accent (`K=0` crosses, 0 % sweep baseline, colour-bar block) | `#930000` | `paper_style.red`, the p301 blue hue-rotated to 0 |
| Controlled accent (`K!=0` dots) | `#005293` | `paper_style.p301`, Pantone 301 |
| Sweep ramp, 0 % light to 100 % dark | vik blue wing | `sweep_colormap` |
| Per-node `f_i`, controlled / uncontrolled | green / red | `line_ramp`, the same wing hue-rotated to 0.30 / 0.00 |
| Uncontrolled envelope band (outer) | `#E0ABAB` | `band_col('off')` |
| Controlled envelope band (inner) | `#EEFCEB` | `band_col('on')` |
| COI trace | black, `lw_dataemph` | drawn on top of the ramp |
| COI nadir marker | black dotted, `lw_axis` | `yline` |

Two properties of that table are deliberate:

- The green and red ramps are the **same** ramp under two hue rotations, and both are
  cut from the wing the sweep colormap uses, so a node keeps its position in the
  light-to-dark ordering across the two panels of Fig. 5. The ordering is by inertia:
  `ranked_line_ramp` gives the largest virtual inertia the darkest entry.
- The two envelope bands separate by **brightness, not hue** (relative luminance 0.48
  against 0.93), and the outer one is deliberately the darker. That survives red-green
  colour blindness and greyscale printing, which a red-green pair at equal lightness
  would not. Pushing the red ramp brighter or more saturated to clear its band was
  tried twice and rejected: the separation is made at the band instead.

## Geometry is code, and the page budget depends on it

Every panel rectangle is set explicitly, in inches, by `place_axes_in`. This is not
decoration. MATLAB's automatic subplot layout pads the panels by whatever the current
release's font metrics ask for: for Fig. 5 that is 1.2 in tall rows where the paper
budgets 0.95 in, and for Fig. 7 it is 0.4 in of extra whitespace on a figure that had
to be cut from 3.14 in to 2.2 in to keep the paper inside its page limit. Those numbers
used to be patched into the `.tikz` by hand after every export; they are constants at
the top of each builder now, so a re-export reproduces the paper instead of quietly
inflating it.

Things that are load-bearing and easy to break:

- **Fig. 7 is the fragile one.** Rows 0.460 in on a 0.565 in pitch, columns on a
  1.910 in pitch, top row ending at 2.150 in. Its zoom insets sit 0.085 in below the
  panel's top edge and **not less**: their upper y tick label is centred on that edge
  and at 0.045 in it crossed the border. Their x tick numbers are lifted
  `\figinsettickshift` (1.5 pt), applied by `tikz_make_adjustable`, because unshifted
  they sat on the COI trace behind them; 1.5 pt is near the ceiling, about 3.1 pt
  separate the digit tops from the inset's bottom border.
- **The Fig. 5 legend is sized in inches**, not as a fraction of the data range,
  because its label font is fixed in points. Sized the old way, shortening the panel
  collapsed the three rows into each other.
- **The `K = 0` / `K = 20 I` labels are not drawn inside the Fig. 5 panels.** The paper
  sets them once as column headers above the two-row composite of 5(a) and 5(b). The
  header offsets are the panel centres, `0.455 + 1.32/2` and the same plus the 1.53 in
  axis pitch, so they move if the geometry above does.
- **Fig. 4's split at `Re = -6`** sits in the spectral gap (-6.155 .. -5.093), so the
  two panels tile the spectrum with no mode drawn twice.

## LaTeX side

`figures/paperfig_preamble.tex` carries the knobs the exported `.tikz` read: `\figscale`
(1, since the figures are exported at their final paper size), the six `\fig*font` knobs,
`\figtitleshift`, `\figinsettickshift`, the legend-box knobs, and the `\fcoi` notation
the axis labels use. `\input` it after `\usepackage{pgfplots}`.

To check a re-export before it reaches the paper:

```
cd preview
lualatex --interaction=nonstopmode tikz_preview.tex
```

**lualatex, not pdflatex**: the sweep figures run to ~100k lines with 9 to 12 axes and
exceed pdflatex's `main_memory`.

The paper `\input`s these files through its own `\figdir`. Fig. 7 is the one figure
that must go in a `figure*` (full text width); the other four are single-column.
